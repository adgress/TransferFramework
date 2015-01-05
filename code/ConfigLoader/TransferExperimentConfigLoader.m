classdef TransferExperimentConfigLoader < ExperimentConfigLoader
    %TRANSFEREXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TransferExperimentConfigLoader(configs)
            obj = obj@ExperimentConfigLoader(configs);
        end      
        
        function [sampledTrain,test,sources,validate,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex)
            experiment = obj.allExperiments{experimentIndex};                                    
                                    
            [train,test,validate] = obj.getSplit(splitIndex);            
            [numTrain,numPerClass] = obj.calculateSampling(experiment,test);            
            classesToKeep = [];
            if obj.has('classesToKeep')
                classesToKeep = obj.get('classesToKeep');
            end
            [sampledTrain] = train.stratifiedSampleByLabels(numTrain,classesToKeep);
            assert(sampledTrain.numClasses == train.numClasses);
            assert(sum(sampledTrain.Y > 0) == sampledTrain.numClasses*numPerClass);
            assert(numPerClass > 1);
            splitStruct = obj.dataAndSplits.allSplits{splitIndex};
            sourceDataSets = splitStruct.sourceData;
            sources = {};            
            for i=1:length(sourceDataSets)
                sources{i} = sourceDataSets{i}.copy();                
                sources{i}.setSource();
                if isfield(experiment,'numSourcePerClass') && ~isinf(experiment.numSourcePerClass)
                    numSource = sources{i}.numClasses*experiment.numSourcePerClass;
                    sources{i} = sources{i}.stratifiedSample(numSource);
                end
                if obj.has('labelsToUse')
                    labelsToUse = obj.get('labelsToUse');
                    assert(length(labelsToUse) > 1);
                    sources{i}.keep(sources{i}.hasLabel(labelsToUse));                   
                end
            end
            sampledTrain.setTargetTrain();
            train.setTargetTrain();
            test.setTargetTest();
            validate.setTargetTrain();
        end
        
        function [results] = ...
                runExperiment(obj,experimentIndex,splitIndex)                                  
            
            [sampledTrain,test,sources,validate,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex);
            assert(sum(sampledTrain.Y > 0) == numPerClass*sampledTrain.numClasses);
            [~,trainTestInput] = ...
                obj.performTransfer(sampledTrain,test,sources,validate,...
                experiment); 
            trainTestInput.learner = obj.get('learner');
            [results] = obj.trainAndTest(trainTestInput,experiment);            
            results.trainingDataMetadata = obj.constructTrainingDataMetadata(sources,...
                sampledTrain,test,numPerClass);
        end
        function [transferOutput,trainTestInput] = ...
                performTransfer(obj,train,test,sources,validate,experiment)
            transferObject = obj.get('transferMethodClass');
            transferObject.configs = obj.configs.copy();
            [tTrain,tTest,tSource,tTarget] = ...
                transferObject.performTransfer(...
                train, test,sources); 
            transferOutput = struct();
            transferOutput.tTrain = tTrain;
            transferOutput.tTest = tTest;
            transferOutput.tSource = tSource;
            transferOutput.tTarget = tTarget;
            transferOutput.originalSourceData = sources;
            trainTestInput = ExperimentConfigLoader.CreateRunExperimentInput(...
                tTrain,tTest,validate,experiment);
            trainTestInput.originalSourceData = sources;
            assert(trainTestInput.train.hasTypes());
            assert(trainTestInput.test.isTargetDataSet());
            isSource = cellfun(@isSourceDataSet,trainTestInput.originalSourceData);
            assert(all(isSource));
            %assert(trainTestInput.originalSourceData.isSourceDataSet());
        end                      
        
        function [trainingDataMetadata] = constructTrainingDataMetadata(obj,sources,...
                sampledTrain,test,numPerClass)
            trainingDataMetadata = struct();
            if length(sources) == 0
                trainingDataMetadata.numSourceLabels = 0;
            else
                trainingDataMetadata.numSourceLabels = ...
                    size(find(sources{1}.Y > 0),1);
            end
            trainingDataMetadata.numTargetLabels = ...
                size(find(sampledTrain.Y > 0),1);
            trainingDataMetadata.numLabeledPerClass = numPerClass;
            trainingDataMetadata.numTrain = numel(sampledTrain.Y);
            trainingDataMetadata.numTest = numel(test.Y);
            trainingDataMetadata.numClasses = test.numClasses;
            %{
            trainingDataMetadata.sources = sources;
            trainingDataMetadata.sampledTrain = sampledTrain;
            trainingDataMetadata.test = test;
            %}
        end        
        
        function [outputFileName] = getOutputFileName(obj)
            outputDir = obj.configs.resultsDirectory;
            warning off;
            outputDirParams = obj.configs.getOutputDirectoryParams();
            outputDir = [outputDir obj.configs.stringifyFields(outputDirParams, '/')];
            
            trueFunc = MainConfigs.trueFunc;
            t = '';
            if obj.has('addTargetDomain') && obj.get('addTargetDomain')
                v = {...
                    MainConfigs.OutputNameStruct('numOverlap','',trueFunc,true,true),...
                };
                t = ['-' obj.configs.stringifyFields(v,'-')];
            end            
            outputDir = [outputDir t '/'];
            warning on;
            
            outputFileParams = obj.configs.getOutputFileNameParams();            
            outputFile = obj.configs.stringifyFields(outputFileParams, '_');            
            outputFileName = [outputDir outputFile '.mat'];
            Helpers.MakeDirectoryForFile(outputFileName);
        end            
            
        function [transferFileName] = getTransferFileName(obj)
            dataSet = obj.configs.get('dataSet');
            transferDir = obj.configs.transferDirectory;
            transferClassName = class(obj.configs.get('transferMethodClass'));
            transferSaveFileName = Transfer.GetResultFileName(...
                transferClassName,obj.configs,false);
            transferFileName = [transferDir transferSaveFileName '_' ...
                dataSet '.mat'];
        end        
    end 
end

