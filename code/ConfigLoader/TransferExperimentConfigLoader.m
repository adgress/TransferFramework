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
        
        function [sampledTrain,test,sources,validate,m,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex)
            experiment = obj.allExperiments{experimentIndex};                                    
                                    
            [train,test,validate] = obj.getSplit(splitIndex);            
            [numTrain,numPerClass] = obj.calculateSampling(experiment,test);
            
            [sampledTrain] = train.stratifiedSampleByLabels(numTrain);
            sources = obj.dataAndSplits.sourceDataSets;
            for i=1:length(sources)
                sources{i}.setSource;
            end
            sampledTrain.setTargetTrain();
            train.setTargetTrain();
            test.setTargetTest();
            validate.setTargetTrain();
            assert(numel(sources) == 1);
            m = struct();
            m.configs = savedData.configs;
            m.metadata = savedData.metadata{experimentIndex,splitIndex};
        end
        
        function [results, metadata] = ...
                runExperiment(obj,experimentIndex,splitIndex,savedData)                                  
            
            [sampledTrain,test,sources,validate,m,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex)                        
            [transferOutput,trainTestInput] = ...
                obj.performTransfer(sampledTrain,test,sources,validate,m,...
                experiment);                        
            [results,~] = obj.trainAndTest(trainTestInput,experiment);            
            results.metadata = obj.constructResultsMetadata(sources,...
                sampledTrain,test,numPerClass);
            metadata = results.metadata;
        end
        function [transferOutput,trainTestInput] = ...
                performTransfer(obj,train,test,sources,validate,m,experiment)
            assert(length(sources) == 1);
            transferClass = str2func(obj.configs('transferMethodClass'));
            transferObject = transferClass();
            [tTrain,tTest,metadata,tSource,tTarget] = ...
                transferObject.performTransfer(...
                train, test,sources,...
                validate,obj.configs,m); 
            transferOutput = struct();
            transferOutput.tTrain = tTrain;
            transferOutput.tTest = tTest;
            transferOutput.metadata = metadata;
            transferOutput.tSource = tSource;
            transferOutput.tTarget = tTarget;
            transferOutput.originalSourceData = sources{1};
            trainTestInput = ExperimentConfigLoader.CreateRunExperimentInput(...
                tTrain,tTest,validate,experiment,metadata);
            trainTestInput.originalSourceData = sources{1};
            assert(trainTestInput.train.hasTypes());
            assert(trainTestInput.test.isTarget());
            assert(trainTestInput.originalSourceData.isSource());
        end                      
        
        function [metadata] = constructResultsMetadata(obj,sources,...
                sampledTrain,test,numPerClass)
            metadata = struct();
            metadata.numSourceLabels = ...
                size(find(sources{1}.Y > 0),1);
            metadata.numTargetLabels = ...
                size(find(sampledTrain.Y > 0),1);
            metadata.targetLabelsPerClass = numPerClass;
            metadata.numTrain = numel(sampledTrain.Y);
            metadata.numTest = numel(test.Y);
            metadata.numClasses = max(test.Y);
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

