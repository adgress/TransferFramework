classdef ITSMeasure < Measure
    %ITSMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [measureResults] = evaluate(obj,split)
            measureResults = struct();
            measureResults.learnerStats = split.learnerStats;
            %measureResults.valTrain = -1;
            error = abs(split.yPred - double(split.yActual));
            normalizedError = mean(error(:));
            measureResults.learnerStats.valTest = 1 - normalizedError;
        end
    end
    
end

