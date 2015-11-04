function [nll,g,H] = L2Loss(w,X,y)
% w(feature,1)
% X(instance,feature)
% y(instance,1)

[n,p] = size(X);

Xw = X*w;
XX = X'*X;

nll = norm(Xw-y)^2;

if nargout > 1
    g = 2*(XX*w - X'*y);
    if nargout > 2
        %sig = 1./(1+exp(-yXw));
        %g = -X.'*(y.*(1-sig));
    else
        %g = -X.'*(y.*(1-(1./(1+exp(-yXw)))));
    end
end

if nargout > 2
    %H = X.'*diag(sparse(y.*sig.*(1-sig).*y))*X;
    H = 2*XX;
end