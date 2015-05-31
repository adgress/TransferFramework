classdef QBCActiveMethod < ActiveMethod
    %QBCACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = QBCActiveMethod(configs)            
            obj = obj@ActiveMethod(configs);
        end
        
        function [scores] = getScores(obj,input,results,s)
            scores = [];
            unlabeledInds = input.train.Y < 0;
            assert(length(unique(results.yPred)) <= 2);
            predicted = [results.modelResults.yPred];
            predicted = predicted(unlabeledInds,:);
            assert(size(predicted,2) > 1);
            [modes,freq] = mode(predicted,2);            
            scores = freq / size(predicted,2);
            scores = 1 - scores;
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'QBC';
        end 
    end
    
end

