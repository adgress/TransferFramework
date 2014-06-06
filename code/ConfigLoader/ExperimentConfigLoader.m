classdef ExperimentConfigLoader < ConfigLoader
    %CONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        names
        dataAndSplits   
        allExperiments
        numSplits
        methodClasses
    end
    
    methods
        function obj = ExperimentConfigLoader(configs,commonConfigFile)
            obj = obj@ConfigLoader(configs,commonConfigFile);            
            dataSet = obj.configs('dataSet');
            obj.setDataSet(dataSet);            
        end        
        
        function [results,metadata] = trainAndTest(obj,input,experiment)
            methodClass = str2func(experiment.methodClass);
            methodObject = methodClass(obj.configs);            
            input.sharedConfigs = obj.configs;
            [results,metadata] = ...
                methodObject.trainAndTest(input);            
        end
        function [numTrain,numPerClass] = calculateSampling(obj,experiment,test)
            numClasses = max(test.Y);
            if isfield(experiment,'numPerClass')           
                numPerClass = experiment.numPerClass;
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
            obj.configs('dataSet') = dataSet;
            inputDir = obj.configs('inputDir');
            inputFile = [inputDir '/' dataSet '.mat'];           
            obj.dataAndSplits = load(Helpers.MakeProjectURL(inputFile));
            obj.dataAndSplits = obj.dataAndSplits.dataAndSplits;
            
            if isa(obj.dataAndSplits.allData,'SimilarityDataSet')
                X = obj.dataAndSplits.allData.X{1};
                X2 = X(:,obj.dataAndSplits.metadata.imagesKept);
                obj.dataAndSplits.allData.X{1} = X2;            
                display('HACK for PIM');
            end
            obj.numSplits = obj.dataAndSplits.configs('numSplits');
            obj.createAllExperiments();
        end
        
        function [] = preprocessData(obj,targetTrainData, ...
                targetTestData, sourceDataSets,validateData,configs,...
                savedData,experimentIndex,splitIndex)  
            methodClass = str2func(experiment.methodClass);
            methodObject = methodClass();
            methodObject.preprocessData(targetTrainData,targetTestData,...
                sourceDataSets,validateData,configs,savedData,...
                experimentIndex,splitIndex)
        end
        
        function [results, metadata] = ...
                runExperiment(obj,experimentIndex,splitIndex,metadata)            
            experimentConfigs = obj.allExperiments{experimentIndex};
            f = fields(experimentConfigs);
            for i=1:length(f)
                obj.configs(f{i}) = experimentConfigs.(f{i});
            end
            methodClass = str2func(experimentConfigs.methodClass);
            methodObject = methodClass(obj.configs);
            percTrain = experimentConfigs.trainSize;
            [train,test,validate,featType] = obj.getSplit(splitIndex);
            numTrain = ceil(percTrain*size(train.X,1)); 
            emptyMetadata = struct();
            if isa(train,'DataSet')
                error('TODO: Update!');
                [sampledTrain] = train.stratifiedSample(numTrain);
                input = ExperimentConfigLoader.CreateRunExperimentInput(...
                    sampledTrain,test,validate,experimentConfigs,emptyMetadata);
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

                        %trainFeats = [trainFeatKept ; validateFeatKept];
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
                    paramVals = obj.configs(param);
                    paramAcc = zeros(size(paramVals));  
                    cvResults = cell(size(paramVals));
                    bestNumVecs = zeros(size(paramVals));
                    for j=1:length(paramVals)
                        drMethodObj.configs(param) = paramVals{j};
                        [modData,drMetadata] = drMethodObj.performDR(cvData);
                        projTrain = modData.train; projTest = modData.test;
                        cvInput = ExperimentConfigLoader.CreateRunExperimentInput(...
                            projTrain,projTest,[],experimentConfigs,emptyMetadata);                        
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
                                    methodObject.trainAndTest(cvInput);
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
                            projTrain,projTrain,[],experimentConfigs,emptyMetadata);
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
                            projTrain,projTest,projValidate,experimentConfigs,emptyMetadata);
            else
                error('Unknown Data type');
            end
            [results,metadata] = ...
                methodObject.trainAndTest(input);
            if exist('drMetadata','var')
                metadata.drMetadata = drMetadata;
            end
            results.metadata.percTrain = percTrain;
            if isa(train,'DataSet')            
                results.metadata.numTrain = numel(sampledTrain.Y);
                results.metadata.numTest = numel(test.Y);
                results.metadata.numClasses = max(test.Y);
            else
                trainIndex = obj.configs('trainSetIndex');
                testIndex = obj.configs('testSetIndex');
                Wij = train.getSubW(trainIndex,testIndex);
                %results.trainActual = Wij;
                results.metadata.numClasses = size(Wij,2);
                results.metadata.numTrain = size(train.X{trainIndex},1) + ...
                    size(validate.X{trainIndex},1);
                results.metadata.numTest = size(test.X{trainIndex,1},1);                                
            end
        end
        
        function [train,test,validate,featType] = getSplit(obj,index)
            split = obj.dataAndSplits.allSplits{index};
            dataSet = obj.dataAndSplits.allData;
            if isa(dataSet,'DataSet')
                [train,test,validate] = dataSet.splitDataSet(split);
            elseif isa(dataSet,'SimilarityDataSet')
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
            if isKey(obj.configs,'numPerClass')
                keys = {'numPerClass'};
            end
            obj.allExperiments = ConfigLoader.StaticCreateAllExperiments(paramKeys,...
                keys,obj.configs);
            obj.methodClasses = obj.configs('methodClasses');                        
        end
        function [outputFileName] = getOutputFileName(obj)
            warning off;
            s = getProjectConstants();            
            outputDir = [s.projectDir '/' obj.configs('outputDir')];
            
            if isKey(obj.configs,'useMeanSigma') && obj.configs('useMeanSigma')
                outputDir = [outputDir '-useMeanSigma/'];
            else
                outputDir = [outputDir '/'];
            end
            mkdir(outputDir);
            if isKey(obj.configs,'dataSet')
                outputDir = [outputDir '/' obj.configs('dataSet')];                
                mkdir(outputDir);
            end            
            if isKey(obj.configs,'justKeptFeatures') && obj.configs('justKeptFeatures')                
                outputDir = [outputDir '/justKeptFeatures/'];
                mkdir(outputDir);
            end
            if length(obj.configs('numVecs')) > 1
                outputDir = [outputDir '/numVecsExp/'];
                mkdir(outputDir);
            end
            if isKey(obj.configs,'tau') && length(obj.configs('tau')) > 1
                outputDir = [outputDir '/tauExp/'];
                mkdir(outputDir);
            end
            if isKey(obj.configs,'clusterExp') && obj.configs('clusterExp')
                outputDir = [outputDir '/cluster/'];
                mkdir(outputDir);
            end
            outputDir = [outputDir '/'];
            outputFileName = outputDir;
            
            prependHyphen = false;
            if isKey(obj.configs,'postTransferMeasures')
                measures = obj.configs('postTransferMeasures');
                if length(measures) > 0
                    outputDir = [outputDir '/TM/'];
                    mkdir(outputDir);
                    measureClass = str2func(measures{1});
                    measureObject = measureClass(obj.configs);
                    %measureFileName = measureObject.getResultFileName();                
                    measurePrefix = measureObject.getPrefix();                
                    [outputFileName] = obj.appendToName(outputDir,measurePrefix,prependHyphen);
                    prependHyphen = true;
                end
            end            
            warning on;
            if isKey(obj.configs,'drMethod')
                %error('Update!!!');
                drMethodName = obj.configs('drMethod');
                drMethodPrefix = DRMethod.GetResultFileName(drMethodName,obj.configs,false);
                outputFileName = [outputFileName drMethodPrefix];                
                prependHyphen = true;
            end
            if isKey(obj.configs,'transferMethodClass')
                transferClass = str2func(obj.configs('transferMethodClass'));
                transferObject = transferClass(obj.configs);
                %transferMethodPrefix = transferObject.getResultFileName(obj.configs);
                transferMethodPrefix = transferObject.getPrefix();
                [outputFileName] = obj.appendToName(outputFileName,transferMethodPrefix,prependHyphen);
                prependHyphen = true;
            end
            if isKey(obj.configs,'repairMethod')
                repairClassName = obj.configs('repairMethod');
                repairFileName = TransferRepair.GetResultFileName(repairClassName,obj.configs);
                [outputFileName] = obj.appendToName(outputFileName,repairFileName,prependHyphen);
                prependHyphen = true;
            end            
            if ~isa(obj,'MeasureExperimentConfigLoader') && isKey(obj.configs,'methodName')
                methodName = obj.configs('methodName');            
                methodPrefix = Method.GetResultFileName(methodName,obj.configs,false);
                [outputFileName] = obj.appendToName(outputFileName,methodPrefix,prependHyphen);
                prependHyphen = true;
            end            
            outputFileName = [outputFileName '.mat'];
        end
        function [outputFileName] = appendToName(obj,fileName,s,prependHyphen)
            if prependHyphen
                outputFileName = [fileName '-' s];
            else
                outputFileName = [fileName s];
            end
        end
        function [savedDataFileName] = getSavedDataFileName(obj)
            savedDataFileName = '';
        end
        function [savedData] = loadSavedData(obj)
            savedData = struct();
            savedDataFileName = obj.getSavedDataFileName();
            if ~isempty(savedDataFileName) && ...
                    exist(savedDataFileName,'file')
                savedData = load(savedDataFileName);
                savedData = savedData.savedData;
            end
        end
        function [] = saveData(obj,savedData)
            savedDataFileName = obj.getSavedDataFileName();
            if ~isempty(savedDataFileName)               
                save(savedDataFileName,'savedData');
            end
        end
    end 
    methods(Static)
        function [s] = CreateRunExperimentInput(train,test,validate,...
                configs,metadata)
            s = struct();
            s.train = train;
            s.test = test;
            s.validate = validate;
            s.configs = configs;
            s.metadata = metadata;
        end
        function [e] = CreateConfigLoader(configFile,commonConfigFile)
            experimentLoader = ExperimentConfigLoader(configFile,commonConfigFile);    
            experimentConfigClass = str2func(...
                experimentLoader.configs('experimentConfigLoader'));
            e = experimentConfigClass(configFile,commonConfigFile); 
        end
    end
end

