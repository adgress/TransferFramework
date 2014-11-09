classdef MultiMeasureAverage < MultiMeasure
    %MULTIMEASUREAVERAGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [ind,measureVal,score] = pickDataset(obj, measureVals, changesInPerf)
            %[measureVal, ind] = max(measureVals);
            %score = changesInPerf(ind) - min(changesInPerf);
            ind = -1;
            measureVal = mean(measureVals);
            score = mean(changesInPerf - min(changesInPerf));
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'MMAverage';
        end
    end
    
end

