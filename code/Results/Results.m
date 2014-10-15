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
                obj.aggregatedResults.PreTMResults = ...
                    aggregateMeasureResultsForField(obj,'preTransferResults');
            end
            if isfield(obj.splitResults{1},'postTransferResults')
                obj.aggregatedResults.PostTMResults = ...
                    aggregateMeasureResultsForField(obj,'postTransferResults');
            end
        end
        
        function [measureResults] = aggregateMeasureResultsForField(obj,field)
            if ~isfield(obj.splitResults{1},field)
                error('Missing field');
            end
            measureStructs = Helpers.getValuesOfField(obj.splitResults, ...
                field);
            obj.aggregatedResults.trainingDataMetadata = ...
                obj.splitResults{1}.trainingDataMetadata;
            transferMeasureValueName = 'transferMeasureVal';
            if Helpers.isFieldNonemptyForArray(measureStructs,transferMeasureValueName)
                values = Helpers.getValuesOfField(measureStructs,transferMeasureValueName);
                measureResults = ResultsVector(values);
            end
            metadataStructs = Helpers.getValuesOfField(measureStructs,'measureMetadata');            
            if Helpers.hasFieldForArray(metadataStructs,'fuSourceProp') && ...
                Helpers.isFieldNonemptyForArray(metadataStructs,'fuSourceProp')                                
                fuSourcePropArray = Helpers.getValuesOfField(metadataStructs,...
                    'fuSourceProp');
                fuTargetPropArray = Helpers.getValuesOfField(metadataStructs,...
                    'fuTargetProp');
                scores = [];
                for propArrayIdx=1:numel(fuSourcePropArray)
                    sourceProp = fuSourcePropArray{propArrayIdx};
                    targetProp = fuTargetPropArray{propArrayIdx};
                    
                    [~,sourcePropPred] = max(sourceProp,[],2);
                    [~,targetPropPred] = max(targetProp,[],2);
                    scores(propArrayIdx) = sum(sourcePropPred==targetPropPred)/length(sourcePropPred);
                end
                measureResults = ResultsVector(scores');
            end            
        end
    end    
    methods(Static)        
    end
    
end

