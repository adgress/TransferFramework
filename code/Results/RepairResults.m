classdef RepairResults < FoldResults
    %REPAIRRESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        repairResults
        repairMetadata
        labeledTargetScores
        postTransferMeasureResults
        transferMeasureMetadata
        trainTestMetadata
    end
    
    methods
        function obj = RepairResults()
            obj = obj@FoldResults();
            obj.repairResults = {};
            obj.repairMetadata = {};
            obj.labeledTargetScores = {};
            obj.postTransferMeasureResults = {};
            obj.transferMeasureMetadata = {};
            obj.trainTestMetadata = {};
        end
    end
    
end

