classdef DistanceActiveMethod < ActiveMethod
    %DISTANCEACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = DistanceActiveMethod(configs)            
            obj = obj@ActiveMethod(configs);
        end
        function [scores] = getScores(obj,input,results,s)
            scores = [];
            I = ~input.train.isLabeled();
            W = Helpers.CreateDistanceMatrix(input.train.X);
            Wu2L = W(I,~I);
            minDists = min(Wu2L,[],2);
            scores = minDists;
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'MinDistance';
        end    
    end
    
end

