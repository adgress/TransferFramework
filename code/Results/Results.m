classdef Results < handle
    %RESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        splitResults = {};
        splitMetadata = {};
        splitMeasures = {};
        numSplits
        aggregatedResults
        experiment
    end
    
    methods
        function obj = Results(numSplits)
            obj.numSplits = numSplits;
            obj.splitResults = cell(numSplits,1);
            obj.splitMetadata = cell(numSplits,1);
        end
        
        function [] = setSplitResults(obj,results,index)            
            obj.splitResults{index} = results;
        end
        function [] = setSplitMetadata(obj,metaData,index)
            obj.splitMetadata{index} = metaData;
        end
        
        function [] = processResults(obj,measure)            
            obj.splitMeasures = cell(numel(obj.splitResults),1);
            for i=1:numel(obj.splitResults)
                split = obj.splitResults{i};
                obj.splitMeasures{i} = measure.evaluate(split);
            end            
        end
        function [] = aggregateResults(obj,measure)
            obj.aggregatedResults = struct();
            obj.aggregatedResults = measure.aggregateResults(obj.splitMeasures);
            obj.aggregatedResults.metadata = ...
                obj.splitResults{1}.metadata;            
            if isfield(obj.splitResults{1},'postTransferMeasureVal')
                measures = Helpers.getValuesOfField(obj.splitResults, ...
                    'postTransferMeasureVal');
                obj.aggregatedResults.PTMResults = {};
                for i=1:numel(measures{1})
                    vals = [];
                    for j=1:numel(measures)
                        vals(j) = measures{j}{i};
                    end 
                    obj.aggregatedResults.PTMResults{i} = ...
                        ResultsVector(vals);   
                end                
            end
        end        
    end    
    methods(Static)        
    end
    
end

