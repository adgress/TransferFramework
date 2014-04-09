classdef FuseTransfer < Transfer
    %TRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = FuseTransfer()            
        end
        
        function [transformedTargetTrain,transformedTargetTest,metadata,...
                tSource,tTarget] = ...
                performTransfer(obj,targetTrainData, targetTestData,...
                sourceDataSets,validateData,configs,savedData)            
            xTrain = [sourceDataSets{1}.X ; targetTrainData.X];
            yTrain = [sourceDataSets{1}.Y ; targetTrainData.Y];
            transformedTargetTrain = DataSet('','','',xTrain,yTrain);
            transformedTargetTest = targetTestData;
            tSource = sourceDataSets{1};
            tTarget = DataSet('','','',[targetTrainData.X;targetTestData.X],...
                [targetTrainData.Y;-1*ones(numel(targetTestData.Y),1)]);
            
            metadata = struct();
        end       
    end
    methods(Static)
        function [prefix] = getPrefix()
            prefix = 'S+T';
        end
    end
    
end

