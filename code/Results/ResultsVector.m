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
        function [v] = getSTD(obj)
            v = std(obj);
        end
        function [v] = getConfidenceInterval(obj,confInterval)
            if confInterval == VisualizationConfigs.CONF_INTERVAL_STD
                v = obj.getSTD();
            elseif confInterval == VisualizationConfigs.CONF_INTERVAL_BINOMIAL
                n = size(obj,1);
                m = obj.getMean();    
                v = 1.96*sqrt(inv(n)*m.*(1-m));
            else
                error('Unknown conf interval type');
            end
            %{
            c = 9/(2*log(2/.05));
            nc = n*c;
            v = (3/(4+nc))*(1 - 2*m + sqrt(1+nc*m.*(1-m)));
            %}
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

