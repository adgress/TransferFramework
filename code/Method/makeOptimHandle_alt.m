function [func] = makeOptimHandle_alt(obj,X,V0,y,F,reg,sigma,alpha)
    func = @f;
    function [val,grad] = f(V)
        %V = diag(V);
        val = obj.evaluate_alt(X,V,V0,y,F,reg,sigma,alpha);
        grad = obj.gradient_alt(X,V,V0,y,F,reg,sigma,alpha);
        %H = obj.hessian_alt(X,V,V0,y,F,reg,sigma,alpha);
        %grad = diag(grad);
    end
end