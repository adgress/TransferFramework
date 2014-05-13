classdef Measure < Saveable
    %MEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configs
    end
    
    methods
        function obj = Measure(configs)
            obj.configs = configs;
        end
        function [measureResults] = evaluate(obj,split)
            valTrain = sum(split.trainPredicted==split.trainActual)/...
                numel(split.trainPredicted); 
            valTest = sum(split.testPredicted==split.testActual)/...
                numel(split.testPredicted);
            measureResults = struct();
            measureResults.testPerformance = valTest;
            measureResults.trainPerformance = valTrain;
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

