function [func] = makeOptimHandle(obj,X,V0,y,alpha,reg,S,yTest,sigma)
    func = @f;
    function [val,grad] = f(V)
        %V = diag(V);
        val = obj.evaluate(X,V,V0,y,alpha,reg,S,yTest,sigma);
        grad = obj.gradient(X,V,V0,y,alpha,reg,S,yTest,sigma);
        %grad = diag(grad);
    end
end