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
            [sampledTrain] = train.stratifiedSampleByLabels(numTrain,obj.get('classesToKeep'));
            
            splitStruct = obj.dataAndSplits.allSplits{splitIndex};
            sourceDataSets = {splitStruct.sourceData};
            sources = {};            
            for i=1:length(sourceDataSets)
                sources{i} = sourceDataSets{i}.copy();                
                sources{i}.setSource();
                if isfield(experiment,'numSourcePerClass') && ~isinf(experiment.numSourcePerClass)
                    numSource = sources{i}.numClasses*experiment.numSourcePerClass;
                    sources{i} = sources{i}.stratifiedSample(numSource);
                end
            end
            sampledTrain.setTargetTrain();
            train.setTargetTrain();
            test.setTargetTest();
            validate.setTargetTrain();
            assert(numel(sources) == 1);
        end
        
        function [results] = ...
                runExperiment(obj,experimentIndex,splitIndex)                                  
            
            [sampledTrain,test,sources,validate,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex);
            [~,trainTestInput] = ...
                obj.performTransfer(sampledTrain,test,sources,validate,...
                experiment);                        
            [results] = obj.trainAndTest(trainTestInput,experiment);            
            results.trainingDataMetadata = obj.constructTrainingDataMetadata(sources,...
                sampledTrain,test,numPerClass);
        end
        function [transferOutput,trainTestInput] = ...
                performTransfer(obj,train,test,sources,validate,experiment)
            assert(length(sources) == 1);
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
            assert(numel(sources) == 1);
            transferOutput.originalSourceData = sources{1};
            trainTestInput = ExperimentConfigLoader.CreateRunExperimentInput(...
                tTrain,tTest,validate,experiment);
            trainTestInput.originalSourceData = sources{1};
            assert(trainTestInput.train.hasTypes());
            assert(trainTestInput.test.isTargetDataSet());
            assert(trainTestInput.originalSourceData.isSourceDataSet());
        end                      
        
        function [trainingDataMetadata] = constructTrainingDataMetadata(obj,sources,...
                sampledTrain,test,numPerClass)
            trainingDataMetadata = struct();
            trainingDataMetadata.numSourceLabels = ...
                size(find(sources{1}.Y > 0),1);
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

