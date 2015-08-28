classdef L2Measure < Measure
    %L2MEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [measureResults] = evaluate(obj,split)        
            isLabeled = ~isnan(split.yActual);
            isTest = split.dataType == Constants.TARGET_TEST;
            isTrain = split.dataType == Constants.TARGET_TRAIN;
            measureResults = struct();
            measureResults.learnerStats = split.learnerStats;
            %measureResults.valTrain = -1;
            ITest = isTest & isLabeled;
            ITrain = isTrain & isLabeled;
            err = double(split.yPred) - double(split.yActual);
            errTrain = abs(err(ITrain));
            errTest = abs(err(ITest));
            
            neTr = mean(errTrain(:));
            neTe = mean(errTest(:));
            measureResults.learnerStats.valTest = 1 - neTe;
            measureResults.learnerStats.testResults = 1 - neTe;
            measureResults.learnerStats.trainResults = 1 - neTr;
            if measureResults.learnerStats.valTest > .7
                %display('');
            end
        end
    end
    
end

