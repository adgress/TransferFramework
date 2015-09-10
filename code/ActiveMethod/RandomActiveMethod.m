classdef RandomActiveMethod < ActiveMethod
    %RANDOMACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = RandomActiveMethod(configs)            
            obj = obj@ActiveMethod(configs);
        end        
        
        function [scores] = getScores(obj,input,results,s)
            numUnlabeled = sum(~input.train.isLabeled());
            scores = rand(numUnlabeled,1);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'Random';
        end
    end
    
end

