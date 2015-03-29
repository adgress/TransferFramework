function [func] = makeOptimHandle_alt(obj,X,V0,y,F,reg,sigma,alpha,distMats)
    func = @f;
    if ~exist('distMats','var')
        distMats = [];
    end
    function [val,grad] = f(V)
        %V = diag(V);
        [val,W] = obj.evaluate_alt(X,V,V0,y,F,reg,sigma,alpha);
        grad = obj.gradient_alt(X,V,V0,y,F,reg,sigma,alpha,distMats,W);
        %grad = 0;
        %H = obj.hessian_alt(X,V,V0,y,F,reg,sigma,alpha);
        %grad = diag(grad);
    end
end