classdef LLGC < handle    
    properties(Constant)
        normRows = 1
    end
    methods(Static)
        
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
            if ~LLGC.normRows
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
        
        function [p] = getPrediction(fu,classes)
            if ~exist('classes','var')
                classes = 1:size(fu,2);
                if length(classes) == 1 && ~LLGC.normRows
                    classes = 1:2;
                end
            end
            if LLGC.normRows
                [~,p] = max(fu,[],2);
            else
                assert(length(classes) == 2);
                p = zeros(size(fu,1),1);
                p(fu >= 0) = classes(1);
                p(fu < 0) = classes(2);
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
            
            if ~LLGC.normRows
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