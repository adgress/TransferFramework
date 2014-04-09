classdef Measure < handle
    %MEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [measureResults] = evaluate(obj,split)
            valTrain = sum(split.trainPredicted==split.trainActual)/...
                numel(split.trainPredicted); 
            valTest = sum(split.testPredicted==split.testActual)/...
                numel(split.testPredicted);
            measureResults = struct();
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
        end
    end
    
end

