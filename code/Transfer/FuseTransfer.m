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
                sourceDataSets) 
            transformedTargetTrain = DataSet.Combine(sourceDataSets{1},targetTrainData);
            transformedTargetTest = targetTestData;
            assert(numel(sourceDataSets) == 1);
            tSource = sourceDataSets{1};  
            
            numTrain = targetTrainData.size();
            numTest = targetTestData.size();
            typeVector = [DataSet.TargetTrainType(numTrain); ...
                DataSet.TargetTestType(numTest)];
            tTarget = DataSet('','','',[targetTrainData.X;targetTestData.X],...
                [targetTrainData.Y;-1*ones(numel(targetTestData.Y),1)],typeVector);
            metadata = struct();
        end  
        function [prefix] = getPrefix(obj)
            prefix = 'S+T';
        end
    end        
end

