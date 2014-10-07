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
            error('Update this!');
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
end




