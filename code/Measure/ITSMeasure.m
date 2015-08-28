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
            err = abs(split.yPred - double(split.yActual));
            normalizedError = mean(err(:));
            measureResults.learnerStats.valTest = 1 - normalizedError;
            measureResults.learnerStats.testResults = 1 - normalizedError;
            measureResults.learnerStats.trainResults = nan;
            if measureResults.learnerStats.valTest > .7
                %display('');
            end
        end
    end
    
end

