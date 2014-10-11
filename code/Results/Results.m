classdef Results < handle
    %RESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        splitResults = {};
        splitMeasures = {};
        numSplits
        aggregatedResults
        experiment
    end
    
    methods
        function obj = Results(numSplits)
            obj.numSplits = numSplits;
            obj.splitResults = cell(numSplits,1);
            obj.aggregatedResults = struct();
        end
        
        function [] = setSplitResults(obj,results,index)            
            obj.splitResults{index} = results;
        end
        
        function [] = computeLossFunction(obj,measure)            
            obj.splitMeasures = cell(numel(obj.splitResults),1);
            for i=1:numel(obj.splitResults)
                split = obj.splitResults{i};
                obj.splitMeasures{i} = measure.evaluate(split);
            end            
        end
        function [] = aggregateResults(obj,measure)
            obj.aggregatedResults = struct();
            obj.aggregatedResults = measure.aggregateResults(obj.splitMeasures);
            obj.aggregatedResults.trainingDataMetadata = ...
                obj.splitResults{1}.trainingDataMetadata;
        end        
        function [] = aggregateMeasureResults(obj)
            if isfield(obj.splitResults{1},'preTransferResults')
                obj.aggregatedResults.PostTMResults = ...
                    aggregateMeasureResultsForField(obj,'preTransferResults');
            end
            if isfield(obj.splitResults{1},'postTransferResults')
                obj.aggregatedResults.PreTMResults = ...
                    aggregateMeasureResultsForField(obj,'postTransferResults');
            end
        end
        
        function [measureResults] = aggregateMeasureResultsForField(obj,field)
            if ~isfield(obj.splitResults{1},field)
                error('Missing field');
            end
            measures = Helpers.getValuesOfField(obj.splitResults, ...
                field);
            obj.aggregatedResults.trainingDataMetadata = ...
                obj.splitResults{1}.trainingDataMetadata;
            values = Helpers.getValuesOfField(measures,'transferMeasureVal');
            measureResults = ResultsVector(values);
        end
    end    
    methods(Static)        
    end
    
end

