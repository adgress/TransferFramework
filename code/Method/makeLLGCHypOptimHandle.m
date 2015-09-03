function [ func ] = makeLLGCHypOptimHandle( obj,L,y,sourceY,alpha,reg)
    func = @f;
    function [val,grad] = f(beta)
        [val] = obj.evaluate(L,y,sourceY,alpha,reg,beta);
        grad = 0;
    end
end

