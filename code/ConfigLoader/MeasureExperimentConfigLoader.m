classdef MeasureExperimentConfigLoader < ExperimentConfigLoader
    %MEASUREEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = MeasureExperimentConfigLoader(configs,commonConfigFile)
            obj = obj@ExperimentConfigLoader(configs,commonConfigFile);               
        end 
        
        function [results, metadata] = ...
                runExperiment(obj,experimentIndex,splitIndex,savedData)
            [train,test,~] = obj.getSplit(splitIndex);                        
            experiment = obj.allExperiments{experimentIndex};
            
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

            metadata = struct();
            metadata.configs = savedData.configs;
            metadata.metadata = savedData.metadata{experimentIndex,splitIndex};
            
            sources = obj.dataAndSplits.sourceDataSets;
            preTransferMeasure = str2func(obj.configs('preTransferMeasure'));
            measureObj = preTransferMeasure(obj.configs);
            target = DataSet('','','',[sampledTrain.X ; test.X],...
                [sampledTrain.Y ; zeros(size(test.Y,1),1)]);
            metadata.preTransferMeasure = ...
                measureObj.computeMeasure(sources{1},target,obj.configs);
            results = struct();
            results.trainPerformance = metadata.preTransferMeasure;
            results.testPerformance = metadata.preTransferMeasure;
            results.numSourceLabels = size(find(sources{1}.Y > 0),1);
            results.numTargetLabels = size(find(sampledTrain.Y > 0),1);
            
            results.targetLabelsPerClass = numPerClass;
            results.numTrain = numel(sampledTrain.Y);
            results.numTest = numel(test.Y);
            results.numClasses = numClasses;
        end
        function [outputFileName] = getOutputFileName(obj)
            outputDir = [obj.configs('outputDir') '/' obj.configs('dataSet') '/'];
            if ~exist(outputDir,'dir')
                mkdir(outputDir);
            end
            measureClass = str2func(obj.configs('preTransferMeasure'));
            measureObject = measureClass(obj.configs);
            measurePrefix = measureObject.getResultFileName();
            outputFileName = [outputDir measurePrefix '.mat'];
        end
    end
    
end

