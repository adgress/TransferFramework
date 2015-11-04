classdef SyntheticDataGenerator
    %SYNTHETICDATAGENERATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function [X,Y,Ytrue] = createPolynomialData(n,degree,range,sigma)
            X = rand(n,1)*(range(2)-range(1)) + range(1);
            Ytrue = X.^degree;
            Y = Ytrue + normrnd(0,sigma,n,1);
        end
        function [X,Y,beta,beta0] = createLinearData(n,p,numNonZero,...
                isZero,sigma,options)
            if ~exist('sigma','var')
                sigma = 1;
            end
            if ~exist('options','var')
                options = [];
            end
            beta = rand(p,1) - .5;
            left = numNonZero;
            if ~isempty(isZero)
                left = numNonZero - sum(~isZero);
            end
            if isempty(isZero)
                isZero = true(p,1);
            end           
            if ~isempty(numNonZero)
                
                nonSparse = find(isZero);
                I = randperm(length(nonSparse));
                %beta(I(left+1:end)) = 0;
                isZero(nonSparse(I(1:left))) = false;
            end
            beta(isZero) = 0;
            beta0 = -.5 + rand();
            X = rand(n,p) - .5;           
            Y = X*beta + beta0 + normrnd(0,sigma,n,1);
            %[a,b] = lasso(X,Y,'DFmax',2,'CV',10,'Standardize',false);
        end
    end
    
end

