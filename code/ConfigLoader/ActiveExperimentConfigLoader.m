classdef ActiveExperimentConfigLoader < ExperimentConfigLoader
    %ACTIVEEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ActiveExperimentConfigLoader(configs)
            obj = obj@ExperimentConfigLoader(configs);
        end
        
        function [activeResults] = ...
                runExperiment(obj,experimentIndex,splitIndex)            
            [learner,experiment] = obj.setExperimentConfigs(experimentIndex);            
            [originalTrain,originalTest,validate,featType] = obj.getSplit(splitIndex);
            originalTrain.setTargetTrain();
            originalTest.setTargetTest();

            [numTrain,numPerClass] = obj.calculateSampling(experiment,originalTest);
            [sampledTrain] = originalTrain.stratifiedSampleByLabels(numTrain,[]);
            sources = obj.dataAndSplits.allSplits{splitIndex}.sourceData;
            transferMethodObj = obj.get('transferMethodClass');
            transferMeasureObj = obj.get('transferMeasure');
            if ~isempty(transferMethodObj)
                preTransferInput = struct();
                preTransferInput.train = sampledTrain;
                preTransferInput.test = originalTest;
                preTransferInput.learner = learner;
                preTransferInput.sharedConfigs = obj.configs;
                [sampledTrain,test,~,~] = ...
                    transferMethodObj.performTransfer(sampledTrain,originalTest,sources);                
            else
                test = originalTest;
            end
            input = struct();
            input.train = sampledTrain;
            input.test = test;
            input.learner = learner;
            input.sharedConfigs = obj.configs;
            labelBudget = obj.get('labelBudget');

            [activeMethodObj] = obj.get('activeMethodObj');
            activeResults = ActiveLearningResults();                        

            activeResults.iterationResults{1} = ...
                learner.trainAndTest(input);
            if ~isempty(transferMethodObj)
                activeResults.preTransferResults{1} = ...
                    learner.trainAndTest(preTransferInput);
            end
            if ~isempty(transferMeasureObj)
                transferMeasureObj.set('useSourceForTransfer',true);
                %TODO: This only works for FuseTransfer
                activeResults.transferMeasureResults{1} = ...
                    transferMeasureObj.computeMeasure(sources,sampledTrain,...
                    transferMeasureObj.configs);
                transferMeasureObj.set('useSourceForTransfer',false);
                activeResults.preTransferMeasureResults{1} = ...
                    transferMeasureObj.computeMeasure(sources,preTransferInput.train,...
                    transferMeasureObj.configs);
            end
            %Note: This assumes the first N instances in train and
            %originalTrain are target instances
            s = struct();
            for budgetIdx=1:labelBudget
                resultsForAL = activeResults.iterationResults{end}.copy();
                if ~isempty(transferMethodObj)
                    s.preTransferResults = ...
                        activeResults.preTransferResults{end}.copy();
                end
                queriedIdx = ...
                    activeMethodObj.queryLabel(input,resultsForAL,s);
                activeResults.queriedLabelIdx(end+1) = queriedIdx;
                input.train.Y(queriedIdx) = input.train.trueY(queriedIdx);
                activeResults.iterationResults{end+1} = ...
                    learner.trainAndTest(input);
                if ~isempty(transferMethodObj)
                    preTransferInput.train.Y(queriedIdx) = ...
                        preTransferInput.train.trueY(queriedIdx);
                    activeResults.preTransferResults{end+1} = ...
                        learner.trainAndTest(preTransferInput);
                end
                if ~isempty(transferMeasureObj)
                    assert(~isempty(transferMethodObj));
                    transferMeasureObj.set('useSourceForTransfer',true);
                    activeResults.transferMeasureResults{end+1} = ...
                        transferMeasureObj.computeMeasure(sources,...
                        preTransferInput.train,transferMeasureObj.configs);
                    transferMeasureObj.set('useSourceForTransfer',false);
                    activeResults.preTransferMeasureResults{end+1} = ...
                        transferMeasureObj.computeMeasure(sources,...
                        preTransferInput.train,transferMeasureObj.configs);
                end
            end                                                                        
            activeResults.trainingDataMetadata = obj.constructTrainingDataMetadata(...
                sampledTrain,test,numPerClass);   
        end
        
        function [results,savedData] = trainAndTest(obj,input,experiment)
            savedData = [];
            learner = input.learner;          
            %learner.updateConfigs(obj.configs);
            input.sharedConfigs = obj.configs;
            [results] = learner.trainAndTest(input);
        end
        
        function [outputFileName] = getOutputFileName(obj)
            outputDir = obj.configs.resultsDirectory;
            warning off;
            outputDirParams = obj.configs.getOutputDirectoryParams();
            outputDir = [outputDir '/' obj.configs.stringifyFields(outputDirParams, '/') '/'];     
            warning on;
            
            outputFileParams = obj.configs.getOutputFileNameParams();            
            outputFile = obj.configs.stringifyFields(outputFileParams, '_');
            
            activeMethodObj = obj.configs.get('activeMethodObj');
            outputFile = [activeMethodObj.getDisplayName() '_' outputFile];
            outputFileName = [outputDir outputFile '.mat'];
            Helpers.MakeDirectoryForFile(outputFileName);
        end   
    end
    
end

