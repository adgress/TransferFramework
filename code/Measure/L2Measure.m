classdef L2Measure < Measure
    %L2MEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = L2Measure(configs)
            if ~exist('configs','var')
                configs = [];
            end
            obj = obj@Measure(configs);
        end
        function [valTrain,valTest] = computeTrainTestResults(obj,r)
            %trainLabeled = ~isnan(r.yTrain) & ~r.isValidation;
            trainLabeled = ~isnan(r.yTrain);
            trainAccVec = abs(r.trainPredicted - r.trainActual);
            trainAccVec = trainAccVec(trainLabeled);
            valTrain = 1 - mean(trainAccVec);
            valTest = 1 - mean(abs(r.testPredicted-r.testActual));
        end
        function [measureResults] = evaluate(obj,split)        
            isLabeled = ~isnan(split.yActual);
            isTest = split.dataType == Constants.TARGET_TEST;
            isTrain = split.dataType == Constants.TARGET_TRAIN;
            measureResults = struct();
            if ~isfield(split,'learnerStats')
                split.learnerStats = struct();
            end
            measureResults.learnerStats = split.learnerStats;
            %measureResults.valTrain = -1;
            ITest = isTest & isLabeled;
            ITrain = isTrain & isLabeled;
            err = abs(double(split.yPred) - double(split.yActual));
            %err = err ./ abs(split.yActual);
            errTrain = abs(err(ITrain));
            errTest = abs(err(ITest));
            
            neTr = mean(errTrain(:));
            neTe = mean(errTest(:));
            %{
            measureResults.learnerStats.valTest = 1 - neTe;
            measureResults.learnerStats.testResults = 1 - neTe;
            measureResults.learnerStats.trainResults = 1 - neTr;
            %}
            measureResults.learnerStats.valTest = neTe;
            measureResults.learnerStats.testResults = neTe;
            measureResults.learnerStats.trainResults = neTr;
            if measureResults.learnerStats.valTest > .7
                %display('');
            end
        end
    end
    
end

