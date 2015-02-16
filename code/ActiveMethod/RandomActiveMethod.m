classdef RandomActiveMethod < ActiveMethod
    %RANDOMACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = RandomActiveMethod(configs)            
            obj = obj@ActiveMethod(configs);
        end
        function [queriedIdx] = queryLabel(obj,input,results,s)               
            unlabeledInds = find(input.train.Y < 0);            
            numUnlabeled = length(unlabeledInds);
            queriedIdx = unlabeledInds(randsample(numUnlabeled,1));
        end   
        function [prefix] = getPrefix(obj)
            prefix = 'Random';
        end
    end
    
end

