classdef TransferExperimentConfigLoader < ExperimentConfigLoader
    %TRANSFEREXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TransferExperimentConfigLoader(...
                configs,commonConfigFile)
            obj = obj@ExperimentConfigLoader(configs,commonConfigFile);
            obj.configs('transferFile') = obj.getTransferFileName();
        end
        
        function [] = preprocessData(obj,targetTrainData, ...
                targetTestData, sourceDataSets,validateData,configs,...
                savedData,experimentIndex,splitIndex)  
            
        end
        
        function [results, metadata] = ...
                runExperiment(obj,experimentIndex,splitIndex,savedData)
            metadata = struct();
            [train,test,validate] = obj.getSplit(splitIndex);
            experiment = obj.allExperiments{experimentIndex};            
            methodClass = str2func(experiment.methodClass);
            methodObject = methodClass();
            
            numClasses = max(test.Y);
            if isfield(experiment,'numPerClass')           
                numPerClass = experiment.numPerClass;
                numTrain = numClasses*numPerClass;
            else
                percTrain = experiment.trainSize;
                numTrain = ceil(percTrain*size(train.X,1));
                numPerClass = ceil(numTrain/numClasses);
                numTrain = numPerClass*numClasses
            end
            [sampledTrain] = train.stratifiedSampleByLabels(numTrain);
            
            transferClass = str2func(obj.configs('transferMethodClass'));
            transferObject = transferClass();
            m = struct();
            m.configs = savedData.configs;
            m.metadata = savedData.metadata{experimentIndex,splitIndex};
            
            sources = obj.dataAndSplits.sourceDataSets;
            assert(numel(sources) == 1);
            [tTrain,tTest,metadata,tSource,tTarget] = ...
                transferObject.performTransfer(...
                sampledTrain, test,sources,...
                validate,obj.configs,m);

            %savedData.metadata{experimentIndex,splitIndex} = tMetadata;
            
            input = ExperimentConfigLoader.CreateRunExperimentInput(...
                tTrain,tTest,validate,experiment,metadata);
            input.sharedConfigs = obj.configs;
            [results,~] = ...
                methodObject.trainAndTest(input);
            postTransferMeasures = obj.configs('postTransferMeasures');
            results.postTransferMeasureVal = {};
            options = {};
            if isfield(metadata,'distanceMatrix')
                options.distanceMatrix = metadata.distanceMatrix;
            end
            for i=1:numel(postTransferMeasures)
                measureFunc = str2func(postTransferMeasures{i});
                measureObject = measureFunc(obj.configs);                                
                results.postTransferMeasureVal{i} = ...
                    measureObject.computeMeasure(tSource,tTarget,options);
            end
            results.metadata.numSourceLabels = ...
                size(find(sources{1}.Y > 0),1);
            results.metadata.numTargetLabels = ...
                size(find(sampledTrain.Y > 0),1);
            results.metadata.targetLabelsPerClass = numPerClass;
            results.metadata.numTrain = numel(sampledTrain.Y);
            results.metadata.numTest = numel(test.Y);
            results.metadata.numClasses = numClasses;
            %display(num2str(metadata.preTransferMeasure));
        end
        function [outputFileName] = getOutputFileName(obj)
            outputDir = [obj.configs('outputDir') '/' obj.configs('dataSet') '/'];
            if ~exist(outputDir,'dir')
                mkdir(outputDir);
            end
            transferClass = str2func(obj.configs('transferMethodClass'));
            transferObject = transferClass();
            transferMethodPrefix = transferObject.getResultFileName(obj.configs);
            outputFileName = [outputDir transferMethodPrefix '.mat'];
        end
        function [transferFileName] = getTransferFileName(obj)
            dataSet = obj.configs('dataSet');
            transferDir = obj.configs('transferDir');
            transferClass = str2func(obj.configs('transferMethodClass'));
            transferObject = transferClass();
            transferMethodPrefix = transferObject.getResultFileName(obj.configs);
            transferFileName = [transferDir transferMethodPrefix '_' ...
                dataSet '.mat'];
        end        
        function [savedDataFileName] = getSavedDataFileName(obj)
            savedDataFileName = obj.getTransferFileName();
        end
    end 
end

