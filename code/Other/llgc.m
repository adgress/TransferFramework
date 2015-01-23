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


        function [fu] = llgc_LS(W,fl,alpha)
        %tic
            %alpha = .5;   
            W(logical(speye(size(W)))) = 0;   
            %Disq = spdiags(sum(W).^-.5);
            Disq = diag(sum(W).^-.5);
            WN = Disq*W*Disq;
            I = eye(size(WN,1));
            M = ((1+alpha)*I-WN);
            fu = M\((1-alpha)*fl);
            fu = Helpers.normRows(fu);
        %toc
            %display('llgc: Normalizing fu');
        end
    end
end