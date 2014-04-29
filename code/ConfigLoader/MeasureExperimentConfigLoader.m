classdef MeasureExperimentConfigLoader < TransferExperimentConfigLoader
    %MEASUREEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = MeasureExperimentConfigLoader(configs,commonConfigFile)
            obj = obj@TransferExperimentConfigLoader(configs,commonConfigFile);               
        end 
        
        function [results, metadata] = ...
                runExperiment(obj,experimentIndex,splitIndex,savedData)                                    
            experiment = obj.allExperiments{experimentIndex};
            
            [train,test,validate] = obj.getSplit(splitIndex);            
            [numTrain,numPerClass] = obj.calculateSampling(experiment,test);
            
            [sampledTrain] = train.stratifiedSampleByLabels(numTrain);
            sources = obj.dataAndSplits.sourceDataSets;
            assert(numel(sources) == 1);
            
            metadata = struct();
            metadata.configs = savedData.configs;
            metadata.metadata = savedData.metadata{experimentIndex,splitIndex};
                        
            configsCopy = obj.configs;
            if ~isempty(obj.configs('preTransferMeasures'))
                configsCopy('useSourceForTransfer') = 0;
                preTransferMeasures = obj.configs('preTransferMeasures');
                measureFunc = str2func(preTransferMeasures{1});                
                measureObj = measureFunc(configsCopy);
                target = DataSet('','','',[sampledTrain.X ; test.X],...
                    [sampledTrain.Y ; -1*ones(size(test.Y))]);
                results.preTransferMeasureVal = {};
                results.preTransferPerLabelMeasures = {};
                [results.preTransferMeasureVal{1},...
                    results.preTransferPerLabelMeasures{1}] = ...
                    measureObj.computeMeasure(sources{1},...
                    target,obj.configs);
            end
            
            if ~isempty(obj.configs('postTransferMeasures'))
                configsCopy('useSourceForTransfer') = 1;
                [transferOutput,~] = ...
                    obj.performTransfer(sampledTrain,test,sources,validate,metadata,...
                    experiment);                
                postTransferMeasures = obj.configs('postTransferMeasures');
                measureFunc = str2func(postTransferMeasures{1});
                measureObject = measureFunc(configsCopy);                                
                results.postTransferMeasureVal = {};
                results.postTransferPerLabelMeasures = {};
                [results.postTransferMeasureVal{1},...
                    results.postTransferPerLabelMeasures{1}] = ...
                    measureObject.computeMeasure(transferOutput.tSource,...
                    transferOutput.tTarget,transferOutput.metadata);                                                
            end
            results.metadata = obj.constructResultsMetadata(sources,...
                sampledTrain,test,numPerClass);
        end
        function [outputFileName] = getOutputFileName(obj)
            outputDir = [obj.configs('outputDir') '/' obj.configs('dataSet') '/'];
            if ~exist(outputDir,'dir')
                mkdir(outputDir);
            end
            measures = obj.configs('postTransferMeasures');
            measureClass = str2func(measures{1});
            measureObject = measureClass(obj.configs);
            measurePrefix = measureObject.getResultFileName();
            
            transferMethodClass = obj.configs('transferMethodClass');
            methodPrefix = Transfer.GetPrefixForMethod(...
                transferMethodClass,obj.configs);
            outputFileName = [outputDir measurePrefix ...
                '_' methodPrefix '.mat'];
        end
    end
    
end

