function [func] = makeOptimHandle(obj,X,V0,y,alpha,reg,sigma,distMats,useGradient)
    func = @f;
    if ~exist('distMats','var')
        distMats = [];
    end
    function [val,grad] = f(V)
        [val,W] = obj.evaluate(X,V,V0,y,alpha,reg,sigma,distMats);
        grad = 0;
        if useGradient
            grad = obj.gradient(X,V,V0,y,alpha,reg,sigma,distMats,W);
        end  
    end
end