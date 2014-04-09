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
            obj.numSplits = obj.configs('numSplits');
            XName = obj.configs('XName');
            YName = obj.configs('YName');
            inputFile = obj.configs('inputFile');            
            sourceFiles = obj.configs('sourceFiles');
            percentTrain = obj.configs('percentTrain');
            percentTest = obj.configs('percentTest');
            dataSetType = obj.configs('dataSetType');
            normalizeData = obj.configs('normalizeRows');
            dataSetTypeConstructer = str2func(dataSetType);
            allData = dataSetTypeConstructer(inputFile,XName,YName);
            allData.X = Helpers.NormalizeRows(allData.X);
            allSplits = cell(obj.numSplits,1);
            for i=1:obj.numSplits
                [allSplits{i}] = ...
                    allData.generateSplitArray(percentTrain,percentTest);
            end            
            obj.dataAndSplits.sourceDataSets = {};
            for i=1:numel(sourceFiles)
                sourceDataSet = DataSet(sourceFiles{i},XName,YName);
                if normalizeData
                    sourceDataSet.X = Helpers.NormalizeRows(sourceDataSet.X);
                end
                obj.dataAndSplits.sourceDataSets{i} = sourceDataSet;
            end
            obj.dataAndSplits.allData = allData;
            obj.dataAndSplits.allSplits = allSplits;
            obj.dataAndSplits.configs = obj.configs;                        
        end
        function [] = saveSplit(obj)
            outputFile = obj.configs('outputFile');
            dataAndSplits = obj.dataAndSplits;
            save(outputFile,'dataAndSplits');
        end
    end
end

