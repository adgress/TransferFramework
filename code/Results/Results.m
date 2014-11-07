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
        function [] = aggregateMeasureResults(obj,measureLoss)
            if isfield(obj.splitResults{1},'preTransferResults')
                obj.aggregatedResults.PreTMResults = ...
                    aggregateMeasureResultsForField(obj,'preTransferResults',measureLoss);
            end
            if isfield(obj.splitResults{1},'postTransferResults')
                obj.aggregatedResults.PostTMResults = ...
                    aggregateMeasureResultsForField(obj,'postTransferResults',measureLoss);
            end
        end
        
        function [measureResults] = aggregateMeasureResultsForField(obj,field,...
                measureLoss)
            if ~isfield(obj.splitResults{1},field)
                error('Missing field');
            end
            measureStructs = Helpers.getValuesOfField(obj.splitResults, ...
                field);
            obj.aggregatedResults.trainingDataMetadata = ...
                obj.splitResults{1}.trainingDataMetadata;
            scores = [];
            for idx=1:numel(measureStructs)
                scores(idx) = measureLoss.computeLoss(measureStructs{idx});                
                obj.splitResults{idx}.(field).measureVal = scores(idx);
            end
            measureResults = ResultsVector(scores');
        end
    end    
    methods(Static)        
    end
    
end

