function [ entropy ] = TheEntropy( X )
    y=log2(X);
    y=y*diag(X);
    entropy = -1.0*sum(y);
end

