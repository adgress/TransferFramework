classdef ActiveExperimentConfigLoader < ExperimentConfigLoader
    %ACTIVEEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ActiveExperimentConfigLoader(configs)
            if ~exist('configs','var')
                configs = Configs();
            end
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
            for sourceIdx=1:length(sources)
                sources{sourceIdx}.setSource();
            end
            transferMethodObj = obj.get('transferMethodClass');
            transferMeasureObj = obj.get('transferMeasure');
            
            preTransferInput = struct();
            preTransferInput.train = sampledTrain;
            preTransferInput.test = originalTest;
            preTransferInput.learner = learner;
            preTransferInput.sharedConfigs = obj.configs;
            if ~isempty(transferMethodObj)                
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
            
            measureSavedData = struct();
            learnerSavedData = struct();
            
            [activeResults.iterationResults{end+1}, ...
                activeResults.preTransferResults{end+1},learnerSavedData] = ...
                obj.runLearners(input,preTransferInput,transferMethodObj,...
                learnerSavedData);
            if ~isempty(transferMeasureObj)
                [activeResults.transferMeasureResults{end+1},...
                    activeResults.preTransferMeasureResults{end+1},...
                    measureSavedData] = obj.runTransferMeasures(sources,...
                    preTransferInput.train,transferMeasureObj,measureSavedData);
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
                queriedIdx = activeMethodObj.queryLabel(input,resultsForAL,s);
                activeResults.queriedLabelIdx(end+1) = queriedIdx;
                input.train.labelData(queriedIdx);
                preTransferInput.train.labelData(queriedIdx);
                [activeResults.iterationResults{end+1}, ...
                    activeResults.preTransferResults{end+1},learnerSavedData] = ...
                    obj.runLearners(input,preTransferInput,transferMethodObj,learnerSavedData);
                if ~isempty(transferMeasureObj)
                    [activeResults.transferMeasureResults{end+1},...
                        activeResults.preTransferMeasureResults{end+1},measureSavedData]...
                        = obj.runTransferMeasures(sources,...
                        preTransferInput.train,transferMeasureObj,measureSavedData);
                end
            end                                                                        
            activeResults.trainingDataMetadata = obj.constructTrainingDataMetadata(...
                sampledTrain,test,numPerClass);   
        end
        function [results,preTransferResults,savedData] = ...
                runLearners(obj,input,preTransferInput,transferMethodObj,...
                savedData)
            if ~isfield(savedData,'postTransfer')
                savedData.postTransfer = struct();
            end
            if ~isfield(savedData,'preTransfer')
                savedData.preTransfer = struct();
            end
            [results,savedData.postTransfer] = input.learner.trainAndTest(input,...
                savedData.postTransfer);
            if ~isempty(transferMethodObj)
                [preTransferResults,savedData.preTransfer] = ...
                    input.learner.trainAndTest(preTransferInput,...
                    savedData.preTransfer);
            end
        end
        %TODO: This only works for FuseTransfer
        function [postTransferResults,preTransferResults,savedData] = ...
                runTransferMeasures(obj,sources,train,transferMeasureObj,savedData)
            if ~isfield(savedData,'postTransfer')
                savedData.postTransfer = struct();
            end
            if ~isfield(savedData,'preTransfer')
                savedData.preTransfer = struct();
            end
            transferMeasureObj.set('useSourceForTransfer',true);
            [postTransferResults,savedData.postTransfer] = ...
                transferMeasureObj.computeMeasure(sources,...
                train,transferMeasureObj.configs,savedData.postTransfer);
            transferMeasureObj.set('useSourceForTransfer',false);
            [preTransferResults,savedData.preTransfer] = ...
                transferMeasureObj.computeMeasure(sources,...
                train,transferMeasureObj.configs,savedData.preTransfer);
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

