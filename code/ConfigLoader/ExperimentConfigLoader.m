classdef ExperimentConfigLoader < ConfigLoader
    %CONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nameFile
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
            methodObject = methodClass();            
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
                percTrain = experiment.trainSize;
                numTrain = ceil(percTrain*size(train.X,1));
                numPerClass = ceil(numTrain/numClasses);
                numTrain = numPerClass*numClasses
            end 
        end  
        
        function [] = setDataSet(obj,dataSet)
            obj.configs('dataSet') = dataSet;
            inputDir = obj.configs('inputDir');
            inputFile = [inputDir '/transfer' dataSet '.mat'];
            obj.dataAndSplits = load(inputFile);
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
            [train,test,validate] = obj.getSplit(splitIndex);
            expermentConfigs = obj.allExperiments{experimentIndex};
            methodClass = str2func(expermentConfigs.methodClass);
            methodObject = methodClass();
            percTrain = expermentConfigs.trainSize;
            numTrain = ceil(percTrain*size(train.X,1));
            [sampledTrain] = train.stratifiedSample(numTrain);
            input = ExperimentConfigLoader.CreateRunExperimentInput(...
                sampledTrain,test,validate,expermentConfigs);
            [results,~] = ...
                methodObject.trainAndTest(input);
        end
        
        function [train,test,validate] = getSplit(obj,index)
            split = obj.dataAndSplits.allSplits{index};
            dataSet = obj.dataAndSplits.allData;
            [train,test,validate] = dataSet.splitDataSet(split);
        end
        
        function [] = loadNames(obj)            
            obj.names = ConfigLoader.StaticLoadConfigs(obj.nameFile);            
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
            mkdir(outputDir);
            outputFileName = [outputDir ...
               obj.configs('saveFile')];
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

