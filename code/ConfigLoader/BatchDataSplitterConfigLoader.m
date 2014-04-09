classdef BatchDataSplitterConfigLoader < ConfigLoader
    %DATASPLITTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dataAndSplits
        numSplits
    end
    
    methods
        function obj = BatchDataSplitterConfigLoader(configs,commonConfigFile)
            obj = obj@ConfigLoader(configs,commonConfigFile); 
            inputFilePrefix = obj.configs('inputFilePrefix');
            inputDataSets = obj.configs('inputDataSets');
            dataSetAcronyms = obj.configs('dataSetAcronyms');
            outputFilePrefix = obj.configs('outputFilePrefix');
            baseConfigLoader = ConfigLoader(commonConfigFile,commonConfigFile);
            for i=1:numel(inputDataSets)
                for j=1:numel(inputDataSets)
                    if i==j
                        continue;
                    end
                    configCopy = baseConfigLoader.configs;
                    configCopy('inputFile') = ...
                        [inputFilePrefix inputDataSets{i}];
                    configCopy('outputFile') = [outputFilePrefix ...
                        dataSetAcronyms{i} '2' dataSetAcronyms{j} '.mat'];
                    configCopy('sourceFiles') = ...
                        {[inputFilePrefix inputDataSets{j}]};
                    o = DataSplitterConfigLoader(configCopy,'');
                    o.splitData();
                    o.saveSplit();
                end
            end
        end       
    end
end

