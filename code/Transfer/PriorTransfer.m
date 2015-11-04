classdef PriorTransfer < Transfer
    %PRIORTRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = PriorTransfer(configs)
            if nargin < 1
                configs = [];
            end
            obj = obj@Transfer(configs);            
        end
        
        function [transformedTargetTrain,transformedTargetTest,...
                tSource,tTarget] = ...
                performTransfer(obj,targetTrainData, targetTestData,...
                sourceDataSets)             
            transformedTargetTrain = targetTrainData.copy();
            transformedTargetTest = targetTestData;
            if isfield(sourceDataSets{1}.savedFields,'beta')
                transformedTargetTrain.savedFields.betaSource=...
                    sourceDataSets{1}.savedFields.beta;
            end

            tSource = sourceDataSets;  
            
            numTrain = targetTrainData.size();
            numTest = targetTestData.size();
            tTarget = DataSet.Combine(targetTrainData,targetTestData);
            tTarget.Y(numTrain+1:end) = -1;
        end  
        function [prefix] = getPrefix(obj)
            prefix = 'Prior';
        end
    end
    
end

