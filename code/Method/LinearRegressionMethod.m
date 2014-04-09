classdef LinearRegressionMethod < Method
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LinearRegressionMethod
            %obj = obj@Method();
        end
        function [testResults,metadata] = ...
            trainAndTest(obj,train,test,validate,experiment)
            trainX = train.X;
            trainY = train.Y;
            testX = test.X;
            testY = test.Y;
            %B = mnrfit(sparse(trainX),trainY);
            [B,FitInfo] = lassoglm(trainX,trainY,'poisson'...
                ,'Alpha',1 ...                
            );
        end
    end   
    
    methods(Static)
        function [name] = getMethodName(configs)
            if nargin < 1
            else
            end
            name = 'Logistic Regression';
        end
    end
end




