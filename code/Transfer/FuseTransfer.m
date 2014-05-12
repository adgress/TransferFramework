classdef FuseTransfer < Transfer
    %TRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = FuseTransfer(configs)            
            obj = obj@Transfer(configs);
        end
        
        function [transformedTargetTrain,transformedTargetTest,metadata,...
                tSource,tTarget] = ...
                performTransfer(obj,targetTrainData, targetTestData,...
                sourceDataSets,validateData,configs,savedData) 
            transformedTargetTrain = DataSet.Combine(sourceDataSets{1},targetTrainData);
            transformedTargetTest = targetTestData;
            tSource = sourceDataSets{1};  
            
            numTrain = targetTrainData.size();
            numTest = targetTestData.size();
            type = [DataSet.TargetTrainType(numTrain); ...
                DataSet.TargetTestType(numTest)];
            tTarget = DataSet('','','',[targetTrainData.X;targetTestData.X],...
                [targetTrainData.Y;-1*ones(numel(targetTestData.Y),1)],type);
            metadata = struct();
        end  
        function [prefix] = getPrefix(obj)
            prefix = 'S+T';
        end
    end        
end

