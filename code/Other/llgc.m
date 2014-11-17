function [fu,invM] = llgc(W,fl,invM)
    alpha = .5;       
    W(logical(speye(size(W)))) = 0;
    %W = W - diag(diag(W));
    
    if nargin < 3
        Disq = diag(sum(W).^-.5);
        WN = Disq*W*Disq;
        I = eye(size(WN,1));
        %M = I-alpha*WN;
        invM = (1-alpha)*inv(I-alpha*WN);               
    end
    fu = invM*fl;
    fu = Helpers.normRows(fu);
    %display('llgc: Normalizing fu');
end

function [fu,invM] = llgc_chol(W,fl)
tic
    alpha = .5;   
    W(logical(eye(size(W)))) = 0;
    if nargin < 3
        Disq = diag(sum(W).^-.5);
        WN = Disq*W*Disq;
        I = eye(size(WN,1));
        invM = (1-alpha)*inv(I-alpha*WN);        
    end
    fu = invM*fl;
    fu = Helpers.normRows(fu);
toc
    invM = [];
    %display('llgc: Normalizing fu');
end


function [fu,invM] = llgc_LS(W,fl,invM)
tic
    alpha = .5;   
    W(logical(speye(size(W)))) = 0;   
    Disq = spdiags(sum(W).^-.5);
    WN = Disq*W*Disq;
    I = eye(size(WN,1));
    M = (I-alpha*WN);
    fu = M\((1-alpha)*fl);
    fu = Helpers.normRows(fu);
toc
    invM = [];
    %display('llgc: Normalizing fu');
end
