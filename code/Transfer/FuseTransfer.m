classdef FuseTransfer < Transfer
    %TRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = FuseTransfer(configs)
            if nargin < 1
                configs = [];
            end
            obj = obj@Transfer(configs);            
        end
        
        function [transformedTargetTrain,transformedTargetTest,...
                tSource,tTarget] = ...
                performTransfer(obj,targetTrainData, targetTestData,...
                sourceDataSets)             
            transformedTargetTrain = targetTrainData;
            for idx=1:length(sourceDataSets)
                transformedTargetTrain = DataSet.Combine(transformedTargetTrain,sourceDataSets{idx});
            end
            transformedTargetTest = targetTestData;
            %assert(numel(sourceDataSets) == 1);
            tSource = sourceDataSets;  
            
            numTrain = targetTrainData.size();
            numTest = targetTestData.size();
            tTarget = DataSet.Combine(targetTrainData,targetTestData);
            tTarget.Y(numTrain+1:end) = -1;
        end  
        function [prefix] = getPrefix(obj)
            prefix = 'S+T';
        end
    end        
end

