classdef MultiMeasureBest < MultiMeasure
    %MULTIMEASUREBEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [ind,measureVal,score] = pickDataset(obj, measureVals, changesInPerf)
            [~, ind] = max(changesInPerf);
            score = changesInPerf(ind) - min(changesInPerf);
            measureVal = measureVals(ind);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'MMBest';
        end
    end
    
end

