function [fu] = llgc(W,fl,alpha)
    if nargin < 3
        alpha = .5;
    end
    Disq = diag(sum(W).^-.5);
    WN = Disq*W*Disq;
    I = eye(size(WN,1));
    fu = (1-alpha)*inv(I-alpha*WN)*fl;
    fu = Helpers.normRows(fu);
end

