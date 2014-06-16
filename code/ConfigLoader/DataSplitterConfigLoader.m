classdef DataSplitterConfigLoader < ConfigLoader
    %DATASPLITTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dataAndSplits
        numSplits
    end
    
    methods
        function obj = DataSplitterConfigLoader(configs,commonConfigFile)
            obj = obj@ConfigLoader(configs,commonConfigFile);            
        end
        function [] = splitData(obj)            
            obj.dataAndSplits = struct();
            obj.numSplits = obj.configs('numSplits');
            allSplits = cell(obj.numSplits,1);
            inputFile = obj.configs('inputFile');
            percentTrain = obj.configs('percentTrain');
            percentTest = obj.configs('percentTest');
            dataSetType = obj.configs('dataSetType');            
            if isequal(dataSetType,'SimilarityDataSet')
                inputPrefix = obj.configs('inputFilePrefix'); 
                f = Helpers.MakeProjectURL([inputPrefix '/' inputFile]);
                data = load(f);
                allData = data.data;                
                metadata = allData.metadata;
                allData = allData.data;
            else
                XName = obj.configs('XName');
                YName = obj.configs('YName');
                dataSetTypeConstructer = str2func(dataSetType);
                f = Helpers.MakeProjectURL(inputFile);
                allData = dataSetTypeConstructer(f,XName,YName);
                metadata = struct();
                normalizeRows = obj.configs('normalizeRows');  
                allData.setTargetTrain();
                if normalizeRows
                    allData.X = Helpers.NormalizeRows(allData.X);
                end                                
            end              
            for i=1:obj.numSplits
                if isa(allData,'SimilarityDataSet')
                    splitIndex = obj.configs('splitIndex');
                    metadata.splitIndex = splitIndex;
                    [allSplits{i}] = ...
                        allData.splitDataAtInd(percentTrain,percentTest,splitIndex);
                elseif isa(allData,'DataSet')
                    [allSplits{i}] = ...
                        allData.generateSplitArray(percentTrain,percentTest,obj.configs);                                    
                else
                    error('Unknown DataSet type');
                end
            end
            if isKey(obj.configs,'sourceFiles')
                d = getProjectDir();
                sourceFiles = obj.configs('sourceFiles');
                obj.dataAndSplits.sourceDataSets = {};
                for i=1:numel(sourceFiles)
                    sourceFileName = [d '/' sourceFiles{i}];
                    sourceDataSet = DataSet(sourceFileName,XName,YName);
                    if normalizeRows
                        sourceDataSet.X = Helpers.NormalizeRows(sourceDataSet.X);
                    end
                    sourceDataSet.setSource();
                    
                    %{
                    sourceSplit = sourceDataSet.generateSplitArray(1,0,obj.configs);
                    sourceToUse = sourceSplit == 1;
                    sourceDataSet.remove(~sourceToUse);
                    %}
                    if isKey(obj.configs,'maxTrainNumPerLabel')
                        numClasses = max(sourceDataSet.Y);
                        numItems = numClasses*obj.configs('maxTrainNumPerLabel');
                        [sampledSource] = sourceDataSet.stratifiedSample(numItems);
                        sourceDataSet = sampledSource;
                    end
                    obj.dataAndSplits.sourceDataSets{i} = sourceDataSet;
                end
            end     
                 
            obj.dataAndSplits.allData = allData;
            obj.dataAndSplits.allSplits = allSplits;
            obj.dataAndSplits.metadata = metadata;
            obj.dataAndSplits.configs = obj.configs;                        
        end
        function [] = saveSplit(obj)
            outputFile = Helpers.MakeProjectURL(obj.configs('outputFile'));
            Helpers.MakeDirectoryForFile(outputFile);
            dataAndSplits = obj.dataAndSplits;
            save(outputFile,'dataAndSplits');
        end
    end
end

