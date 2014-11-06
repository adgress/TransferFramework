classdef BatchDataSplitterConfigLoader < ConfigLoader
    %DATASPLITTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dataAndSplits
        numSplits
    end
    
    methods
        function obj = BatchDataSplitterConfigLoader(configs)
            obj = obj@ConfigLoader(configs); 
            inputFilePrefix = obj.get('inputFilePrefix');
            inputDataSets = obj.get('inputDataSets');
            dataSetAcronyms = obj.get('dataSetAcronyms');
            outputFilePrefix = obj.get('outputFilePrefix');
            if length(inputDataSets) > 1
                for i=1:numel(inputDataSets)
                    configCopy = configs.copy();
                    configCopy.set('inputFile',[inputFilePrefix inputDataSets{i}]);
                    sourceFiles = {};
                    sourceAcronym = '';
                    sourceNames = {};
                    for j=1:numel(inputDataSets)
                        if i==j
                            continue;
                        end
                        sourceNames{end+1} = dataSetAcronyms{j};
                        sourceFiles{end+1} = [inputFilePrefix inputDataSets{j}];
                        sourceAcronym = [sourceAcronym dataSetAcronyms{j}];
                        
                    end
                    configCopy.set('targetName',dataSetAcronyms{i});
                    configCopy.set('sourceFiles', sourceFiles);
                    configCopy.set('outputFile',[sourceAcronym '2' dataSetAcronyms{i} '.mat']);
                    configCopy.set('sourceNames', sourceNames);
                    o = DataSplitterConfigLoader(configCopy);
                    o.splitData();
                    o.saveSplit();
                end
            else
                data = load(Helpers.MakeProjectURL([inputFilePrefix inputDataSets{1}]));
                allFields = fields(data);
                data = data.(allFields{1});
                configCopy = configs.copy();
                configCopy.set('data',data);
                o = DataSplitterConfigLoader(configCopy);
                o.splitData();
                o.saveSplit();
            end
        end       
    end
end

