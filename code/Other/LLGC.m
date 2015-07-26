classdef LLGC < handle    
    properties(Constant)
        normRows = 1
        useCMN = 1
    end
    methods(Static)
                        
        function [fu,invM] = llgc_inv_alt(W,fl,alpha,invM)
            %W(logical(speye(size(W)))) = 0;
            if ~exist('invM','var')
                D = diag(sum(W,2));
                L = D-W;
                I = eye(size(L));
                %invM = inv(L+D+alpha*I)*(W+I);
                invM = inv(L+D*alpha)*(alpha*W);
            end
            if ~LLGC.normRows && size(fl,2) > 1
                fl = LLGC.labelMatrix2vector(fl);
            end
            fu = invM*fl;
            if LLGC.normRows
                fu = Helpers.normRows(fu);
            end
        end
        
        function [fu,invM] = llgc_LS_alt(W,fl,alpha)
            %W(logical(speye(size(W)))) = 0;
            D = diag(sum(W,2));
            L = D-W;
            I = eye(size(L));
            %Ly = (W+I)*fl;
            %fu = (L+D+alpha*I)\Ly;
            Ly = (W*alpha)*fl;
            fu = (L+D*alpha)\Ly;
        end
        
        function [v] = smoothness(W,f)            
            if size(f,2) == 1
                f = Helpers.createLabelMatrix(f);
            end
            assert(all(sum(f,2) > 0));
            L = LLGC.make_L(W);
            classScores = [];
            for i=1:size(f,2)
                fi = f(:,i);
                if ~any(fi)
                    continue
                end                
                classScores(end+1) = fi' * L * fi;
            end
            v = mean(classScores);
        end
        
        function [fu,invM] = llgc_inv(W,fl,alpha,invM)
            %alpha = .5;       
            W(logical(speye(size(W)))) = 0;

            if ~exist('invM','var')
                %{
                Disq = diag(sum(W).^-.5);
                WN = Disq*W*Disq;
                I = eye(size(WN,1));
                invM = (1-alpha)*inv((1+alpha)*I - WN);               
                %}
                invM = LLGC.makeInvM(W,alpha);
            end
            if ~LLGC.normRows && size(fl,2) > 1
                fl = LLGC.labelMatrix2vector(fl);
            end
            fu = invM*fl;         
            if LLGC.normRows
                fu = Helpers.normRows(fu);
            end
            isInvalid = isnan(fu) | isinf(fu);
            if any(isInvalid(:))
                %display('LLGC:llgc_ls : inf or nan - randing out');
                r = rand(size(fu));
                fu(isInvalid) = r(isInvalid);
            end
            %display('llgc: Normalizing fu');
        end

        function [WN] = make_WN(W)
            Disq = diag(sum(W).^-.5);
            WN = Disq*W*Disq;
        end
        function [L] = make_L_unnormalized(W)
            L = diag(sum(W)) - W;
        end
        
        function [L] = make_L(W)
            W(logical(speye(size(W)))) = 0;

            Disq = diag(sum(W).^-.5);
            WN = Disq*W*Disq;
            I = eye(size(WN,1));
            L = I - WN;
        end
        
        function [fu,invM] = llgc_inv_unbiased(W,fl,alpha,invM)
            %alpha = .5;       
            W(logical(speye(size(W)))) = 0;

            if ~exist('invM','var')
                invM = LLGC.makeInvM_unbiased(W,alpha,fl);              
            end
            if ~LLGC.normRows
                fl = LLGC.labelMatrix2vector(fl);
            end
            fu = invM*fl;
            if LLGC.normRows
                fu = Helpers.normRows(fu);
            end
            %display('llgc: Normalizing fu');
        end
        
        function [fu,invM] = llgc_chol(W,fl)
            error('Need to set alpha');
        tic
            alpha = .5;   
            W(logical(speye(size(W)))) = 0;
            if nargin < 3
                Disq = diag(sum(W).^-.5);
                WN = Disq*W*Disq;
                I = eye(size(WN,1));
                invM = (1-alpha)*inv((1+alpha)*I-WN);        
            end
            fu = invM*fl;
            fu = Helpers.normRows(fu);
        toc
            invM = [];
            %display('llgc: Normalizing fu');
        end
        
        function [invM] = makeInvM(W,alpha)
            W(logical(speye(size(W)))) = 0;
            Disq = diag(sum(W).^-.5);
            I = isinf(Disq);
            if sum(I(:)) > 0
                display('Disconnected nodes - zeroing out infs');
                Disq(I) = 0;
            end
            WN = Disq*W*Disq;
            I = eye(size(WN,1));
            %invM = (1-alpha)*inv((1+alpha)*I-WN);
            invM = alpha*inv((1+alpha)*I-WN);
        end
        
        function [invM] = makeInvM_unbiased(W,alpha,Y)
            W(logical(speye(size(W)))) = 0;
            Disq = diag(sum(W).^-.5);
            WN = Disq*W*Disq;
            Y = Y > 0;
            if size(Y,2) > 1
                Y = sum(Y,2);
            end
            I = eye(size(WN,1));
            A = diag(Y);
            eps = 1e-6;
            %invM = (1-alpha)*inv(I*(1+eps) - WN + alpha*A);
            invM = alpha*inv(I*(1+eps) - WN + alpha*A);
        end
        
        function [f] = labelMatrix2vector(fl)
            fl = Helpers.RemoveNullColumns(fl);
            assert(size(fl,2) == 2);
            f = zeros(size(fl,1),1);
            f(fl(:,1) == 1) = 1;
            f(fl(:,2) == 1) = -1;
        end
        
        function [p] = getPrediction(fu,classes,fl,labelSets)
            if isempty(labelSets)
                labelSets = ones(size(fl,2),1);
            end
            if ~exist('classes','var')
                classes = 1:size(fu,2);
                if length(classes) == 1 && ~LLGC.normRows
                    classes = 1:2;
                end
            end
            numF = size(fu,2);
            p = zeros(size(fl,1),max(labelSets));
            assert(numF == 1 || numF == length(classes));            
            for labelIdx=1:max(labelSets)
                currLabels = find(labelSets == labelIdx);
                fuCurr = fu(:,currLabels);
                if LLGC.normRows
                    if LLGC.useCMN
                        %with laplace smoothing                    
                        q = sum(fuCurr)+1;
                        fuCurr = fuCurr .*repmat(q./sum(fuCurr),size(fuCurr,1),1);
                        %fu = fu ./ repmat(q,size(fu,1),1);
                        fuCurr = Helpers.normRows(fuCurr);
                    end                
                    [~,origPred] = max(fuCurr,[],2);
                    p(:,labelIdx) = origPred;
                    for classIdx=1:length(currLabels)
                        p(origPred == classIdx,labelIdx) = currLabels(classIdx);
                    end
                else
                    error('Fix this?');
                    assert(~LLGC.useCMN);
                    assert(length(classes) == 2);
                    p = zeros(size(fuCurr,1),1);
                    p(fuCurr >= 0) = classes(1);
                    p(fuCurr < 0) = classes(2);
                end
            end
        end
        
        function [fu] = llgc_LS(W,fl,alpha)
        %tic
            %alpha = .5;   
            W(logical(speye(size(W)))) = 0;   
            %Disq = spdiags(sum(W).^-.5);
            n = size(W,1);
            D = spdiags(sum(W,2),0,n,n);
            
            %TODO: Do we want this?
            D = D + 1e-6*sparse(eye(size(D)));
            
            Disq = inv(D).^.5;
            WN = Disq*W*Disq;
            I = speye(size(WN,1));
            M = ((1+alpha)*I-WN);
            %fu = M\((1-alpha)*fl);
            
            if ~LLGC.normRows && size(fl,2) > 1
                fl = LLGC.labelMatrix2vector(fl);
            end
            fu = M\(alpha*fl);
            
            if LLGC.normRows
                fu = Helpers.normRows(fu);
            end
            
            isInvalid = isnan(fu) | isinf(fu);
            if any(isInvalid(:))
                %display('LLGC:llgc_ls : inf or nan - randing out');
                r = rand(size(fu));
                fu(isInvalid) = r(isInvalid);
            end
        %toc
            %display('llgc: Normalizing fu');
        end
    end
end