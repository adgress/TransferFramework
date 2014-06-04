classdef TauMeasure < Measure
    %DISTANCEMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TauMeasure(configs)
            obj = obj@Measure(configs);
        end
        
        function [measureResults] = evaluate(obj,split)
            measureResults = struct();                
            measureResults.testPercLessThanTau = split.testPercLessThanTau;
            measureResults.trainPercLessThanTau = split.trainPercLessThanTau;
            measureResults.testPerformance = split.testPercLessThanTau(end);
            measureResults.trainPerformance = split.trainPercLessThanTau(end);
        end
        
        function [aggregatedResults] = aggregateResults(obj,splitMeasures)
            aggregatedResults = struct();
            testMeasures = ...
                Helpers.getValuesOfField(splitMeasures,'testPercLessThanTau');
            trainMeasures = ...
                Helpers.getValuesOfField(splitMeasures,'trainPercLessThanTau');                        
            aggregatedResults.testResults = ResultsVector(testMeasures);
            aggregatedResults.trainResults = ResultsVector(trainMeasures);
        end                
        function [prefix] = getPrefix(obj)
            prefix = 'Tau';
        end
    end
    
end

