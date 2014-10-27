classdef ExperimentConfigLoader < ConfigLoader
    %CONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        names
        dataAndSplits   
        allExperiments
        learners
    end
    
    properties(Dependent)
        numSplits
    end
    
    methods
        function obj = ExperimentConfigLoader(configs)
            obj = obj@ConfigLoader(configs);            
            dataSet = obj.configs.get('dataSet');            
            if obj.has('dataAndSplits')
                obj.configs.set('dataSet',dataSet);
                dataSet = obj.get('dataAndSplits');
            end
            obj.setDataSet(dataSet);            
        end        
        
        function [results,savedData] = trainAndTest(obj,input,experiment)
            learner = experiment.learner;            
            input.sharedConfigs = obj.configs;
            [results] = learner.trainAndTest(input);
        end
        function [numTrain,numPerClass] = calculateSampling(obj,experiment,test)
            numClasses = test.numClasses;
            if isfield(experiment,'numLabeledPerClass')           
                numPerClass = experiment.numLabeledPerClass;
                numTrain = numClasses*numPerClass;
            else
                error('What if there is class imalance?');
                percTrain = experiment.trainSize;
                numTrain = ceil(percTrain*size(train.X,1));
                numPerClass = ceil(numTrain/numClasses);
                numTrain = numPerClass*numClasses;
            end 
        end  
        
        function [] = setDataSet(obj,dataSet)
            if ~isa(dataSet,'char')
                obj.dataAndSplits = dataSet;
            else
                obj.configs.set('dataSet',dataSet);
                inputDir = obj.configs.dataDirectory;
                inputFile = [inputDir '/' dataSet '.mat'];           
                obj.dataAndSplits = load(Helpers.MakeProjectURL(inputFile));
                obj.dataAndSplits = obj.dataAndSplits.dataAndSplits;
            end
            if isfield(obj.dataAndSplits,'allData') && isa(obj.dataAndSplits.allData,'SimilarityDataSet')
                X = obj.dataAndSplits.allData.X{1};
                X2 = X(:,obj.dataAndSplits.metadata.imagesKept);
                obj.dataAndSplits.allData.X{1} = X2;            
                display('HACK for PIM');
            end            
            obj.createAllExperiments();
        end   
        
        function [results] = ...
                runExperiment(obj,experimentIndex,splitIndex)            
            experimentConfigs = obj.allExperiments{experimentIndex};
            f = fields(experimentConfigs);
            for i=1:length(f)
                obj.configs.set(f{i}, experimentConfigs.(f{i}));
            end
            learner = experimentConfigs.learner;            
            [train,test,validate,featType] = obj.getSplit(splitIndex);
            if isfield(experimentConfigs,'trainSize')
                percTrain = experimentConfigs.trainSize;
                numTrain = ceil(percTrain*size(train.X,1)); 
            end
            if isa(train,'DataSet')
                error('TODO: Update!');
                [sampledTrain] = train.stratifiedSample(numTrain);
                input = ExperimentConfigLoader.CreateRunExperimentInput(...
                    sampledTrain,test,validate,experimentConfigs);
            elseif isa(train,'SimilarityDataSet')
                trainIndex = obj.configs('trainSetIndex');
                testIndex = obj.configs('testSetIndex');
                data = struct();
                
                if obj.configs('useStandardSampling')
                    [sampledTrain,keptTrain] = train.randomSampleInstances(percTrain,trainIndex,splitIndex);
                    [sampledTrainCV,~] = train.randomSampleInstances(percTrain,trainIndex,splitIndex);
                    [sampledValidate,keptValidate] = validate.randomSampleInstances(percTrain,trainIndex,splitIndex*10);
                    [sampledValidateCV,~] = validate.randomSampleInstances(percTrain,trainIndex,splitIndex*10);
                                        
                    if obj.configs('justKeptFeatures')
                        isTrainFeat = featType == Constants.TRAIN;
                        isValidateFeat = featType == Constants.VALIDATE;
                        trainFeatInds = find(isTrainFeat);
                        validateFeatInds = find(isValidateFeat);                        
                        trainFeatKept = trainFeatInds(keptTrain);
                        validateFeatKept = validateFeatInds(keptValidate);
                        cvFeats = trainFeatKept;

                        sampledTrainCV.X{1} = sampledTrainCV.X{1}(:,cvFeats);
                        sampledValidateCV.X{1} = sampledValidateCV.X{1}(:,cvFeats);

                        trainFeats = [trainFeatKept ; validateFeatKept];
                        trainFeats = [trainFeatKept];

                        sampledTrain.X{1} = sampledTrain.X{1}(:,trainFeats);
                        sampledValidate.X{1} = sampledValidate.X{1}(:,trainFeats);
                        test.X{1} = test.X{1}(:,trainFeats);
                    end
                else
                    error('Update!');
                    sampledTrain = train.randomSampleInstances(percTrain,trainIndex,testIndex);
                    sampledValidate = validate.randomSampleInstances(percTrain,trainIndex);
                end
                if obj.configs('justKeptFeatures')
                    
                end             
                data.train = sampledTrain; data.test = test; data.validate = sampledValidate;                
                drMethodName = obj.configs('drMethod');
                drMethodObj = DRMethod.ConstructObject(drMethodName,obj.configs);
                cvParams = obj.configs('cvParams');
                
                measureObj = Measure.ConstructObject(...
                    obj.configs('measureClass'),obj.configs);
                
                cvData = struct();
                cvData.train = sampledTrainCV;
                cvData.test = sampledValidateCV;
                cvData.validate = [];
                assert(length(cvParams) <= 1);
                for i=1:length(cvParams)
                    param = cvParams{i};
                    paramVals_orig = obj.configs(param);
                    paramVals = {};
                    for k=1:length(paramVals_orig)
                        v = paramVals_orig{k};
                        paramVals{end+1} = v;
                        paramVals{end+1} = 5*v;
                    end
                    paramAcc = zeros(size(paramVals));  
                    cvResults = cell(size(paramVals));
                    bestNumVecs = zeros(size(paramVals));
                    for j=1:length(paramVals)
                        drMethodObj.configs(param) = paramVals{j};
                        [modData,drMetadata] = drMethodObj.performDR(cvData);
                        projTrain = modData.train; projTest = modData.test;
                        cvInput = ExperimentConfigLoader.CreateRunExperimentInput(...
                            projTrain,projTest,[],experimentConfigs);                        
                        if obj.configs('tuneNumVecs')
                            maxVecs = min(obj.configs('numVecs'),size(projTrain.X{trainIndex},2));
                            numVecsResults = cell(maxVecs,1);
                            numVecsAcc = zeros(maxVecs,1);
                            origTrainX = cvInput.train.X;
                            origTestX = cvInput.test.X;
                            for numVecs=1:maxVecs
                                numFeats = maxVecs-numVecs;
                                projTrain.X = origTrainX;
                                projTest.X = origTestX;
                                projTrain.removeLastKFeatures(numFeats);
                                projTest.removeLastKFeatures(numFeats);
                                [numVecsResults{numVecs},~] = ...
                                    learner.trainAndTest(cvInput);
                                measureResults = measureObj.evaluate(numVecsResults{numVecs});
                                numVecsAcc(numVecs) = measureResults.testPerformance;
                            end
                            %numVecsAcc
                            [~,bestInd] = max(numVecsAcc);
                            cvResults{j} = numVecsResults{bestInd};
                            bestNumVecs(j) = bestInd;    
                        else
                            [cvResults{j},~] = ...
                                methodObject.trainAndTest(cvInput);                            
                        end
                        measureResults = measureObj.evaluate(cvResults{j});
                        paramAcc(j) = measureResults.testPerformance;
                        display(['CV Acc: ' num2str(paramAcc(j))]);
                        trainInput = ExperimentConfigLoader.CreateRunExperimentInput(...
                            projTrain,projTrain,[],experimentConfigs);
                        trainResults = methodObject.trainAndTest(trainInput);
                        trainMeasureResults = measureObj.evaluate(trainResults);
                        display(['Train Acc: ' num2str(trainMeasureResults.testPerformance)]);
                        if isfield(drMetadata,'keepTuningReg') && ~drMetadata.keepTuningReg && ...
                                isequal(param,'reg')
                            display('Done tuning reg')
                            break;
                        end
                    end
                    paramAcc
                    if obj.configs('tuneNumVecs')
                        %bestNumVecs
                    end
                    [~,bestInd] = max(paramAcc);
                    drMethodObj.configs(param) = paramVals{bestInd};    
                    drMethodObj.configs('numVecs') = bestNumVecs(bestInd);
                    
                end                
                [modData,drMetadata] = drMethodObj.performDR(data);
                projTrain = modData.train; projTest = modData.test; projValidate = modData.validate;
                input = ExperimentConfigLoader.CreateRunExperimentInput(...
                            projTrain,projTest,projValidate,experimentConfigs);
            else
                error('Unknown Data type');
            end
            [results] = ...
                methodObject.trainAndTest(input);
            if exist('drMetadata','var')
                error('What should we do with drMetadata?');
                metadata.drMetadata = drMetadata;
            end
            results.trainingDataMetadata.percTrain = percTrain;
            if isa(train,'DataSet')            
                results.trainingDataMetadata.numTrain = numel(sampledTrain.Y);
                results.trainingDataMetadata.numTest = numel(test.Y);
                results.trainingDataMetadata.numClasses = max(test.Y);
            else
                trainIndex = obj.configs('trainSetIndex');
                testIndex = obj.configs('testSetIndex');
                Wij = train.getSubW(trainIndex,testIndex);
                %results.trainActual = Wij;
                results.trainingDataMetadata.numClasses = size(Wij,2);
                results.trainingDataMetadata.numTrain = size(train.X{trainIndex},1) + ...
                    size(validate.X{trainIndex},1);
                results.trainingDataMetadata.numTest = size(test.X{trainIndex,1},1);                                
            end
        end
        
        function [train,test,validate,featType] = getSplit(obj,index)
            splitStruct = obj.dataAndSplits.allSplits{index};
            %{
            dataSet = obj.dataAndSplits.allData;
            dataSet = obj.dataAndSplits.allSplits{index};
            %}
            dataSet = splitStruct.targetData;
            split = splitStruct.targetType;
            if isa(dataSet,'DataSet')
                [train,test,validate] = dataSet.splitDataSet(split);
                featType = [];
            elseif isa(dataSet,'SimilarityDataSet')
                error('TODO!!!');
                ind = obj.dataAndSplits.metadata.splitIndex;
                
                [dataSets] = dataSet.createDataSetsWithSplit(split,ind);
                if obj.configs('justKeptFeatures')
                    trainInds = find(split == Constants.TRAIN);
                    validateInds = find(split == Constants.VALIDATE);
                    inds = [ trainInds; validateInds];
                    featType = [Constants.TRAIN*ones(length(trainInds),1) ; ...
                        Constants.VALIDATE*ones(length(validateInds),1)];
                    display('Hack for PIM!');
                    for i=1:length(dataSets)
                        Xi = dataSets{i}.X{1};
                        Xi = Xi(:,inds);
                        dataSets{i}.X{1} = Xi;
                    end
                end
                train = dataSets{Constants.TRAIN};
                test = dataSets{Constants.TEST};
                validate = dataSets{Constants.VALIDATE};
            else
                error('Unknown DataSet')
            end
        end
        
        function [nExperiments] = numExperiments(obj)
            nExperiments = numel(obj.allExperiments);
        end
        function [expManager] = getExperimentManager(obj)
            expManagerName = obj.configs('ExperimentManagerName');
            expManagerCtr = str2func(expManagerName);
            expManager = expManagerCtr();
        end
        function [] = createAllExperiments(obj)
            paramKeys= {'k'};
            keys = {'trainSize'};
            keys{end+1} = 'numVecs';
            if obj.configs.hasConfig('numLabeledPerClass')
                keys = {'numLabeledPerClass'};
            end
            if obj.configs.has('numSourcePerClass')
                keys{end+1} = 'numSourcePerClass';
            end
            obj.allExperiments = ConfigLoader.StaticCreateAllExperiments(paramKeys,...
                keys,obj.configs);
        end
        function [outputFileName] = getOutputFileName(obj)
            outputDir = obj.configs.resultsDirectory;
            warning off;
            outputDirParams = obj.configs.getOutputDirectoryParams();
            outputDir = [outputDir obj.configs.stringifyFields(outputDirParams, '/') '/'];
            warning on;
            
            outputFileParams = obj.configs.getOutputFileNameParams();            
            outputFile = obj.configs.stringifyFields(outputFileParams, '_');            
            outputFileName = [outputDir outputFile '.mat'];
            Helpers.MakeDirectoryForFile(outputFileName);
        end
        function [outputFileName] = appendToName(obj,fileName,s,prependHyphen)
            if prependHyphen
                outputFileName = [fileName '-' s];
            else
                outputFileName = [fileName s];
            end
        end        
        function [v] = get.numSplits(obj)
            v = obj.dataAndSplits.configs.get('numSplits');
        end
    end 
    methods(Static)
        function [s] = CreateRunExperimentInput(train,test,validate,...
                configs)
            s = struct();
            s.train = train;
            s.test = test;
            s.validate = validate;
            s.configs = configs;
        end
        function [e] = CreateConfigLoader(configLoaderName, configs)
            configLoaderClass = str2func(configLoaderName);
            e = configLoaderClass(configs); 
        end
    end
end

