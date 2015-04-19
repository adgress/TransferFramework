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
                        
            transferMethodObj = obj.get('transferMethodClass');
            transferMeasureObj = obj.get('transferMeasure');
            
            useTransfer = ~isempty(transferMethodObj);
            
            preTransferInput = struct();
            %preTransferInput.train = sampledTrain;
            %preTransferInput.test = originalTest;
            preTransferInput.learner = learner;
            preTransferInput.sharedConfigs = obj.configs;
            if useTransfer              
                sources = obj.dataAndSplits.allSplits{splitIndex}.sourceData;
                for sourceIdx=1:length(sources)
                    sources{sourceIdx}.setSource();
                end
                [sampledTrain,test,~,~] = ...
                    transferMethodObj.performTransfer(sampledTrain,originalTest,sources);                
            else
                test = originalTest;
            end
            preTransferInput.train = sampledTrain.copy();
            preTransferInput.train.Y(preTransferInput.train.isSource()) = -1;
            preTransferInput.test = originalTest;
            preTransferInput.validationWeights = ones(size(sampledTrain.Y));
            input = struct();
            input.train = sampledTrain;
            input.test = test;
            input.learner = learner;
            input.sharedConfigs = obj.configs;
            input.validationWeights = ones(size(sampledTrain.Y));
            activeIterations = obj.get('activeIterations');
            labelsPerIteration = obj.get('labelsPerIteration');
            activeMethodObj = obj.get('activeMethodObj');
            activeMethodObj.set('labelsPerIteration',labelsPerIteration);
            activeResults = ActiveLearningResults();                        
            
            measureSavedData = struct();
            learnerSavedData = struct();
            
            [activeResults.iterationResults{end+1}, ...
                activeResults.preTransferResults{end+1},learnerSavedData] = ...
                obj.runLearners(input,preTransferInput,transferMethodObj,...
                learnerSavedData);
            if useTransfer
                [activeResults.transferMeasureResults{end+1},...
                    activeResults.preTransferMeasureResults{end+1},...
                    measureSavedData] = obj.runTransferMeasures(sources,...
                    preTransferInput.train,transferMeasureObj,measureSavedData);
            end
            %Note: This assumes the first N instances in train and
            %originalTrain are target instances
            s = struct();
            for budgetIdx=1:activeIterations                
                s.preTransferResults = ...
                    activeResults.preTransferResults{end}.copy();                
                resultsForAL = s.preTransferResults;
                if useTransfer
                    resultsForAL = activeResults.iterationResults{end}.copy();
                end
                s.preTransferInput = preTransferInput;
                [queriedIdx,scores] = activeMethodObj.queryLabel(input,resultsForAL,s);
                activeResults.queriedLabelIdx(end+1,:) = queriedIdx;
                
                queriedYVals = s.preTransferInput.train.Y(queriedIdx);
                
                assert(all(queriedYVals == -1));
                preTransferInput.train.isValidation(queriedIdx) = true;
                input.train.isValidation(queriedIdx) = true;
                    
                preTransferInput.validationWeights(queriedIdx) = scores(queriedIdx);
                input.validationWeights(queriedIdx) = scores(queriedIdx);
                
                input.train.labelData(queriedIdx);                
                preTransferInput.train.labelData(queriedIdx);
                [activeResults.iterationResults{end+1}, ...
                        activeResults.preTransferResults{end+1},learnerSavedData] = ...
                        obj.runLearners(input,preTransferInput,transferMethodObj,learnerSavedData);
                if useTransfer                                        
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
            results = [];
            if ~isfield(savedData,'postTransfer')
                savedData.postTransfer = struct();
            end
            if ~isfield(savedData,'preTransfer')
                savedData.preTransfer = struct();
            end 
            [preTransferResults,savedData.preTransfer] = ...
                input.learner.trainAndTest(preTransferInput,...
                savedData.preTransfer);
            if ~isempty(transferMethodObj)
                [results,savedData.postTransfer] = input.learner.trainAndTest(input,...
                    savedData.postTransfer);                
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
            pc = ProjectConfigs.Create();
            outputDir = obj.configs.resultsDirectory;
            if pc.labelNoise > 0
                outputDir = [outputDir '/labelNoise=' num2str(pc.labelNoise) '/'];
            end
            warning off;
            outputDirParams = obj.configs.getOutputDirectoryParams();
            outputDir = [outputDir '/' obj.configs.stringifyFields(outputDirParams, '/') '/'];     
            warning on;
            
            outputFileParams = obj.configs.getOutputFileNameParams();            
            outputFile = obj.configs.stringifyFields(outputFileParams, '_');
            
            activeMethodObj = obj.configs.get('activeMethodObj');
            s = activeMethodObj.getResultFileName('_',false);

            outputFile = [s '_' outputFile];
            activeIterations = obj.get('activeIterations');
            labelsPerIteration = obj.get('labelsPerIteration');
            outputFile = [outputFile '_' num2str(activeIterations) '_' num2str(labelsPerIteration)];

            outputFileName = [outputDir outputFile '.mat'];
            Helpers.MakeDirectoryForFile(outputFileName);
        end   
    end
    
end

