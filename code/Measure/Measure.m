classdef Measure < Saveable
    %MEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = Measure(configs)
            obj = obj@Saveable(configs);
        end
        function [measureResults] = evaluate(obj,split)
            measureResults = struct();
            if size(split.trainActual,2) == 1
                valTrain = sum(split.trainPredicted==split.trainActual)/...
                    numel(split.trainPredicted); 
                valTest = sum(split.testPredicted==split.testActual)/...
                    numel(split.testPredicted);                
                numLabels = max(split.testActual);
                measureResults.trainPerfPerLabel = ResultsVector(zeros(numLabels,1));
                measureResults.testPerfPerLabel = ResultsVector(zeros(numLabels,1));
                for i=1:numLabels
                    measureResults.trainPerfPerLabel(i) = ...
                        Helpers.getLabelAccuracy(split.trainPredicted,...
                        split.trainActual,i);
                    measureResults.testPerfPerLabel(i) = ...
                        Helpers.getLabelAccuracy(split.testPredicted,...
                        split.testActual,i);
                end
            else
                trainPredicted = split.trainPredicted;
                testPredicted = split.testPredicted;
                if isKey(obj.configs,'k')
                    trainPredicted = trainPredicted(:,1:obj.configs('k'));
                    testPredicted = testPredicted(:,1:obj.configs('k'));
                end
                trainPredictedMat = logical(Helpers.createLabelMatrix(trainPredicted));
                t = split.trainActual(:,1:size(trainPredictedMat,2));
                trainIsCorrect = t(trainPredictedMat);
                valTrain = sum(trainIsCorrect(:))/numel(trainPredicted);
                
                testPredictedMat = logical(Helpers.createLabelMatrix(testPredicted));
                t = split.testActual(:,1:size(testPredictedMat,2));
                testIsCorrect = t(testPredictedMat);
                valTest = sum(testIsCorrect(:))/numel(testPredicted);
            end            
            measureResults.testPerformance = valTest;
            measureResults.trainPerformance = valTrain;
        end
        
        function [aggregatedResults] = aggregateResults(obj,splitMeasures)
            aggregatedResults = struct();
            testMeasures = ...
                Helpers.getValuesOfField(splitMeasures,'testPerformance');
            trainMeasures = ...
                Helpers.getValuesOfField(splitMeasures,'trainPerformance');                        
            aggregatedResults.testResults = ResultsVector(testMeasures);
            aggregatedResults.trainResults = ResultsVector(trainMeasures);
            aggregatedResults.trainLabelMeasures = ...
                ResultsVector(Helpers.getValuesOfField(splitMeasures,'trainPerfPerLabel'));
            aggregatedResults.testLabelMeasures  = ...
                ResultsVector(Helpers.getValuesOfField(splitMeasures,'testPerfPerLabel'));
        end                
        function [prefix] = getPrefix(obj)
            prefix = '0-1 loss';
        end
        function  [d] = getDirectory(obj)
            error('Not implemented');
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
    end
end

