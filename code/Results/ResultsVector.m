classdef ResultsVector < double
    %RESULTVECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
    end

    methods
        function obj = ResultsVector(vals)
            obj = obj@double(vals);
        end        
        
        function [m] = getMean(obj)
            m = mean(obj);
        end
        function [v] = getVar(obj)
            v = var(obj);
        end
    end
    
    methods(Static)
        function [vals] = GetRelativePerformance(num,denom)
            vals = ResultsVector(num./denom);
        end
        
        function [c,up,low] = GetCorrelation(x,y)
            assert(numel(x) == numel(y));
            [corrMat,~,low,up] = corrcoef(double(x),double(y));
            up = up(1,2);
            low = low(1,2);
            c = corrMat(1,2);
        end
    end
end

