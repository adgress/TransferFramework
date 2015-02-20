classdef DataSplitterConfigLoader < ConfigLoader
    %DATASPLITTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dataAndSplits
        numSplits
    end
    
    methods
        function obj = DataSplitterConfigLoader(configs)
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@ConfigLoader(configs);            
        end
        function [] = splitData(obj)            
            obj.dataAndSplits = struct();
            obj.numSplits = obj.get('numSplits');
            allSplits = cell(obj.numSplits,1);            
            percentTrain = obj.get('percentTrain');
            percentTest = obj.get('percentTest');
            dataSetType = obj.get('dataSetType','DataSet');
            if obj.has('data')
                dataStruct = obj.get('data');
                allData = DataSet.MakeDataFromStruct(dataStruct);
                normalizeRows = obj.get('normalizeRows');
                if normalizeRows
                    allData.X = Helpers.NormalizeRows(allData.X);
                end  
            else
                inputFile = obj.get('inputFile');
                if isequal(dataSetType,'SimilarityDataSet')
                    inputPrefix = obj.get('inputFilePrefix'); 
                    error('Do we want to use MakeProjectURL?');
                    f = Helpers.MakeProjectURL([inputPrefix '/' inputFile]);
                    data = load(f);
                    allData = data.data;                
                    metadata = allData.metadata;
                    allData = allData.data;
                else
                    XName = obj.get('XName');
                    YName = obj.get('YName');
                    dataSetTypeConstructer = str2func(dataSetType);
                    %error('Do we want to use MakeProjectURL?');
                    f = Helpers.MakeProjectURL(inputFile);
                    allData = dataSetTypeConstructer(f,XName,YName);
                    metadata = struct();
                    normalizeRows = obj.get('normalizeRows');  
                    allData.setTargetTrain();
                    if normalizeRows
                        allData.X = Helpers.NormalizeRows(allData.X);
                    end                                
                end                  
            end            
            allData.name = obj.get('targetName','');
            if obj.has('numToUsePerLabel')
                n = obj.get('numToUsePerLabel');
                allData = allData.stratifiedSample(n*allData.numClasses);
            end
            %TODO: Why did we need this?
            %assert(isempty(allData.trueY));
            allData.trueY = allData.Y;
            if isempty(allData.instanceIDs)
                allData.instanceIDs = 1:length(allData.Y);
                allData.instanceIDs = allData.instanceIDs';
            end
            if obj.has('classNoise')
                classNoise = obj.get('classNoise');        
                allData.addRandomClassNoise(classNoise);                
            end
            if obj.has('maxTrainNumPerLabel')
                numClasses = max(allData.Y);
                [allData] = allData.stratifiedSampleNumPerClass(obj.get('maxTrainNumPerLabel'));
                for i=1:numClasses
                    if length(find(allData.Y == i)) == obj.get('maxTrainNumPerLabel')
                        warning('Imbalanced number of instances');
                        break;
                    end
                end                
            end
            for i=1:obj.numSplits
                if isa(allData,'SimilarityDataSet')
                    error('TODO: Update');
                    splitIndex = obj.get('splitIndex');
                    metadata.splitIndex = splitIndex;
                    [allSplits{i}] = ...
                        allData.splitDataAtInd(percentTrain,percentTest,splitIndex);
                elseif isa(allData,'DataSet')
                    allSplits{i} = struct();
                    allSplits{i}.permutation = randperm(length(allData.Y))';
                    
                    allDataCopy = allData.copy();                    
                    allDataCopy.applyPermutation(allSplits{i}.permutation);
                    [split] = ...
                        allDataCopy.generateSplitArray(percentTrain,percentTest,obj.configs);                    
                    allSplits{i}.split = split;                    
                    [train,test,~] = allDataCopy.splitDataSet(split);
                    assert(train.numClasses == allDataCopy.numClasses);
                    assert(test.numClasses == allDataCopy.numClasses);
                else
                    error('Unknown DataSet type');
                end
            end
            if obj.has('sourceFiles')
                display('TODO: permute source data?');
                sourceFiles = obj.get('sourceFiles');
                obj.dataAndSplits.sourceDataSets = {};
                obj.dataAndSplits.sourceNames = obj.get('sourceNames');
                for i=1:numel(sourceFiles)
                    %sourceFileName = [d '/' sourceFiles{i}];
                    sourceFileName = sourceFiles{i};
                    sourceDataSet = DataSet(sourceFileName,XName,YName);                    
                    if normalizeRows
                        sourceDataSet.X = Helpers.NormalizeRows(sourceDataSet.X);
                    end
                    sourceDataSet.setSource();
                    %assert(isempty(sourceDataSet.trueY));
                    sourceDataSet.trueY = sourceDataSet.Y;
                    if isempty(sourceDataSet.instanceIDs)
                        sourceDataSet.instanceIDs = 1:length(sourceDataSet.Y);
                        sourceDataSet.instanceIDs = sourceDataSet.instanceIDs';
                    end
                    %{
                    sourceSplit = sourceDataSet.generateSplitArray(1,0,obj.configs);
                    sourceToUse = sourceSplit == 1;
                    sourceDataSet.remove(~sourceToUse);
                    %}
                    if obj.has('maxTrainNumPerLabel')
                        numClasses = max(sourceDataSet.Y);
                        numItems = numClasses*obj.get('maxTrainNumPerLabel');
                        [sampledSource] = sourceDataSet.stratifiedSample(numItems);
                        sourceDataSet = sampledSource;
                    end
                    if obj.has('sourceNoise') && obj.get('sourceNoise') > 0
                        sourceNoise = obj.get('sourceNoise');
                        allData.addRandomClassNoise(sourceNoise);
                    end
                    sourceDataSet.name = obj.dataAndSplits.sourceNames{i};
                    obj.dataAndSplits.sourceDataSets{i} = sourceDataSet;
                end                
            end                 
            obj.dataAndSplits.allData = allData;
            obj.dataAndSplits.allSplits = allSplits;
            if exist('metadata','var')
                obj.dataAndSplits.metadata = metadata;
            end
            
            if obj.has('minInstancesPerFeature')                
                Xall = obj.dataAndSplits.allData.X;
                if isfield(obj.dataAndSplits,'sourceDataSets')
                    for sourceIdx=1:length(obj.dataAndSplits.sourceDataSets)
                        Xall = [Xall ; obj.dataAndSplits.sourceDataSets{sourceIdx}.X];
                    end                    
                end
                featuresToKeep = sum(Xall > 0) >= obj.get('minInstancesPerFeature');
                obj.dataAndSplits.allData.keepFeatureInds(featuresToKeep);
                for sourceIdx=1:length(obj.dataAndSplits.sourceDataSets)
                    obj.dataAndSplits.sourceDataSets{sourceIdx}.keepFeatureInds(featuresToKeep);
                end
            end
            obj.dataAndSplits.configs = obj.configs;                        
        end
        function [] = saveSplit(obj)
            c = getProjectConstants();
            outputFile = [obj.get('outputFilePrefix') '/' obj.get('outputFile')];
            Helpers.MakeDirectoryForFile(outputFile);
            dataAndSplits = obj.dataAndSplits;
            display(['Saving splits to:' outputFile]);
            save(outputFile,'dataAndSplits');            
        end
    end
end

