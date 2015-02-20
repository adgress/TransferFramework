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
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@ConfigLoader(configs);            
            obj.updateDataSetFromConfigs();            
        end        
        
        function [] = setNewConfigs(obj,newConfigs)
            obj.configs = newConfigs;
            obj.updateDataSetFromConfigs();
        end
        
        function [results,savedData] = trainAndTest(obj,input,experiment)
            savedData = [];
            learner = input.learner;          
            %learner.updateConfigs(obj.configs);
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
            assert(numTrain == numPerClass*test.numClasses);
            assert(test.numClasses > 1);
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
        end   
        
        function [learner,experiment] = setExperimentConfigs(obj,experimentIndex)
            experiment = obj.allExperiments{experimentIndex};
            f = fields(experiment);
            learner = experiment.learner;
            for i=1:length(f)
                obj.configs.set(f{i}, experiment.(f{i}));
                learner.configs.set(f{i}, experiment.(f{i}));
            end        
        end
        
        function [results] = ...
                runExperiment(obj,experimentIndex,splitIndex)            
            [learner] = obj.setExperimentConfigs(experimentIndex);
            [train,test,validate,featType] = obj.getSplit(splitIndex);
            train.setTargetTrain();
            test.setTargetTest();
            if isfield(experiment,'trainSize')
                percTrain = experiment.trainSize;
                numTrain = ceil(percTrain*size(train.X,1)); 
            end
            if isa(train,'DataSet')
                %error('TODO: Update!');
                [numTrain,numPerClass] = obj.calculateSampling(experiment,test);
                [sampledTrain] = train.stratifiedSampleByLabels(numTrain,[]);
                input = ExperimentConfigLoader.CreateRunExperimentInput(...
                    sampledTrain,test,validate,experiment);
            elseif isa(train,'SimilarityDataSet')
                error('TODO: Update!');
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
                
                measureObj = obj.configs.get('measure');
                measureObj.configs = obj.configs;

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
                            projTrain,projTest,[],experiment);                        
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
                            projTrain,projTrain,[],experiment);
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
                            projTrain,projTest,projValidate,experiment);
            else
                error('Unknown Data type');
            end
            input = struct();
            input.train = sampledTrain;
            input.test = test;
            input.learner = learner;
            [results] = obj.trainAndTest(input,experiment);            
            results.trainingDataMetadata = obj.constructTrainingDataMetadata(...
                sampledTrain,test,numPerClass);
        end
        
        function [trainingDataMetadata] = constructTrainingDataMetadata(obj,...
                sampledTrain,test,numPerClass)
            trainingDataMetadata = struct();            
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
            if obj.has('targetLabels') && ~isempty(obj.get('targetLabels'))
                labelsToUse = obj.get('targetLabels');                
                train.keep(train.hasLabel(labelsToUse));
                test.keep(test.hasLabel(labelsToUse));
                validate.keep(validate.hasLabel(labelsToUse));
            end
            pc = ProjectConfigs.Create();            
            if pc.labelNoise > 0
                assert(all(train.Y > 0));
                train.addRandomClassNoise(pc.labelNoise);
                if pc.replaceTrueY
                    train.trueY = train.Y;
                end
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
            paramKeys= {};
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
            if obj.has('targetLabels')
                outputDir = [outputDir num2str(obj.get('targetLabels')) '/'];
            end
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
    
    methods(Access=private)
        function [] = updateDataSetFromConfigs(obj)
            if obj.has('dataSet')
                dataSet = obj.configs.get('dataSet');    
                if obj.has('dataAndSplits')
                    obj.configs.set('dataSet',dataSet);
                    dataSet = obj.get('dataAndSplits');
                end
                obj.setDataSet(dataSet);
                obj.createAllExperiments();
            end           
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

