classdef ActiveLearningResults < matlab.mixin.Copyable
    %ACTIVERESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        queriedLabelIdx = []
        iterationResults = {}
        preTransferResults = {}
        transferMeasureResults = {}
        preTransferMeasureResults = {}
        trainingDataMetadata
    end
    
    methods
        
        function [] = shrink(obj)
            cellfun(@FoldResults.shrink_static,obj.iterationResults);
            cellfun(@FoldResults.shrink_static,obj.preTransferResults);
        end
    end        
end

