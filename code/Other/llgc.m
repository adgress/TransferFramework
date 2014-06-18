function [fu,invM] = llgc(W,fl,invM)
    alpha = .5;   
    W(logical(eye(size(W)))) = 0;
    if nargin < 3
        Disq = diag(sum(W).^-.5);
        WN = Disq*W*Disq;
        I = eye(size(WN,1));
        invM = (1-alpha)*inv(I-alpha*WN);        
    end
    fu = invM*fl;
    %fu = Helpers.normRows(fu);
    %display('llgc: Normalizing fu');
end

