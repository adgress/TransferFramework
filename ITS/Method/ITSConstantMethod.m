classdef ITSConstantMethod < ITSRandomMethod
    %ITSCONSTANTMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ITSConstantMethod(configs)            
            obj = obj@ITSRandomMethod(configs);
        end
        function [v] = getPrediction(obj,numRows,numCols)
            s = 1;
            %s = .5;
            v = s*ones(numRows,numCols);
        end
        function [prefix] = getPrefix(obj)
            prefix = 'ITSConstant';
        end
    end
    
end

