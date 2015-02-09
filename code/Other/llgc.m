classdef LLGC < handle    
    methods(Static)
        function [fu,invM] = llgc_inv(W,fl,alpha,invM)
            %alpha = .5;       
            W(logical(speye(size(W)))) = 0;

            if ~exist('invM','var')
                Disq = diag(sum(W).^-.5);
                WN = Disq*W*Disq;
                I = eye(size(WN,1));
                invM = (1-alpha)*inv((1+alpha)*I - WN);               
            end
            fu = invM*fl;
            fu = Helpers.normRows(fu);
            %display('llgc: Normalizing fu');
        end

        function [fu,invM] = llgc_inv_unbiased(W,fl,alpha,invM)
            %alpha = .5;       
            W(logical(speye(size(W)))) = 0;

            if ~exist('invM','var')
                invM = LLGC.makeInvM_unbiased(W,alpha,fl);              
            end
            fu = invM*fl;
            fu = Helpers.normRows(fu);
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
            invM = (1-alpha)*inv((1+alpha)*I-WN);
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
            invM = (1-alpha)*inv(I*(1+eps) - WN + alpha*A);
        end
        
        function [fu] = llgc_LS(W,fl,alpha)
        %tic
            %alpha = .5;   
            W(logical(speye(size(W)))) = 0;   
            %Disq = spdiags(sum(W).^-.5);
            n = size(W,1);
            Disq = spdiags(sum(W,2).^-.5,0,n,n);
            WN = Disq*W*Disq;
            I = speye(size(WN,1));
            M = ((1+alpha)*I-WN);
            fu = M\((1-alpha)*fl);
            fu = Helpers.normRows(fu);
        %toc
            %display('llgc: Normalizing fu');
        end
    end
end