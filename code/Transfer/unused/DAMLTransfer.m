classdef DAMLTransfer < Transfer
    %DAMLTRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = DAMLTransfer()
        end
        
        function [transformedTargetTrain,transformedTargetTest,metadata,...
                tSource,tTarget] = ...
                performTransfer(obj,targetTrainData, targetTestData,...
                sourceDataSets,validateData,configs,savedData)            
            metadata = struct();
            addpath('libraryCode/DAML');
            addpath('libraryCode/DAML/config_files');
            addpath(genpath('libraryCode/cvx'));
            source = sourceDataSets{1};
            
            [Xt,Yt] = targetTrainData.getLabeledData();
            [Xs,Ys] = source.getLabeledData();
            if numel(Yt) == 0
                transformedTargetTrain = targetTrainData;
                transformedTargetTest = targetTestData;
                tSource = source;
                tTarget = targetTrainData;
                return;
            end
            
            params = struct();
            params.constraint_type = configs('constraintType');
            params.gamma = configs('gamma');
            params.use_Gaussian_kernel = 0;
            params.constraint_num = configs('maxConstraints');
            params = learnSymmTransform(Xt,Yt,Xs,Ys, params);                        
            metadata.distanceMatrix = params.S;
            metadata.sourceIndices = 1:size(Xt,1);
            metadata.targetIndices = ...
                size(Xt,1)+1:size(metadata.distanceMatrix,1);
            metadata.sourceY = Ys;
            metadata.targetY = Yt;
            
        end       
    end
    methods(Static)
        function [prefix] = getPrefix()
            prefix = 'DAML';
        end
    end
    
end

