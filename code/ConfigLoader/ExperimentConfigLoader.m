classdef ExperimentConfigLoader < ConfigLoader
    %CONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        names
        dataAndSplits   
        allExperiments
        numSplits
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
            methodClass = str2func(experimentConfigs.methodClass);
            methodObject = methodClass(obj.configs);
            percTrain = experimentConfigs.trainSize;
            [train,test,validate] = obj.getSplit(splitIndex);
            numTrain = ceil(percTrain*size(train.X,1));
            if isa(train,'DataSet')
                [sampledTrain] = train.stratifiedSample(numTrain);
                input = ExperimentConfigLoader.CreateRunExperimentInput(...
                    sampledTrain,test,validate,experimentConfigs);
            elseif isa(train,'SimilarityDataSet')
                data = struct();
                data.train = train; data.test = test; data.validate = validate;
                drMethodName = obj.configs('drMethod');
                drMethodObj = DRMethod.ConstructObject(drMethodName,obj.configs);
                [modData,metadata] = performDR(data,configs);
                train = modData.train; test = modData.test; validate = modData.validate;
            else
                error('Unknown Data type');
            end
            
            
            
            
            [results,metadata] = ...
                methodObject.trainAndTest(input);
        end
        
        function [train,test,validate] = getSplit(obj,index)
            split = obj.dataAndSplits.allSplits{index};
            dataSet = obj.dataAndSplits.allData;
            if isa(dataSet,'DataSet')
                [train,test,validate] = dataSet.splitDataSet(split);
            elseif isa(dataSet,'SimilarityDataSet')
                ind = obj.dataAndSplits.metadata.splitIndex;
                [dataSets] = dataSet.createDataSetsWithSplit(split,ind);
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
            if isKey(obj.configs,'numPerClass')
                keys = {'numPerClass'};
            end
            obj.allExperiments = ConfigLoader.StaticCreateAllExperiments(paramKeys,...
                keys,obj.configs);
        end
        function [outputFileName] = getOutputFileName(obj)
            outputDir = [obj.configs('outputDir') '/' obj.configs('dataSet') '/'];
            if ~exist(outputDir,'dir')
                mkdir(outputDir);
            end
            drMethodName = obj.configs('drMethod');
                        
            drMethodPrevix = DRMethod.GetPrefix(drMethodName,obj.configs);            
            outputFileName = [outputDir drMethodPrevix '.mat'];
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

