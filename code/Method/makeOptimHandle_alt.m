function [func] = makeOptimHandle_alt(obj,X,V0,y,F,reg,sigma,alpha,distMats,useGradient)
    func = @f;
    if ~exist('distMats','var')
        distMats = [];
    end
    function [val,grad] = f(V)
        %V = diag(V);
        [val,W] = obj.evaluate_alt2(X,V,V0,y,F,reg,sigma,alpha);
        grad = 0;
        if useGradient
            grad = obj.gradient_alt2(X,V,V0,y,F,reg,sigma,alpha,distMats,W);
        end
        %H = obj.hessian_alt(X,V,V0,y,F,reg,sigma,alpha);
        %grad = diag(grad);
    end
end