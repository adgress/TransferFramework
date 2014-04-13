function [fu,fu_CMN] = llgc(W,fl)
    a = .5;
    Disq = diag(sum(W).^-.5);
    WN = Disq*W*Disq;
    I = eye(size(WN,1));
    fu = (1-a)*inv(I-a*WN)*fl;
    fu_CMN = fu;
end

