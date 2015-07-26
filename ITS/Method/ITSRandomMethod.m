classdef ITSRandomMethod < ITSMethod
    %ITSRANDOMMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ITSRandomMethod(configs)            
            obj = obj@ITSMethod(configs);
        end
        
        function [v] = getPrediction(obj,numRows,numCols)
            v = rand(numRows,numCols);
        end
        function [prefix] = getPrefix(obj)
            prefix = 'ITSRandom';
        end
    end
    
end

