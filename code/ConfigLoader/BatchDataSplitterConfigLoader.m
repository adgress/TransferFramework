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
            %outputFilePrefix = obj.get('outputFilePrefix');
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
                    s = [sourceAcronym '2' dataSetAcronyms{i}];
                    if obj.get('classNoise') > 0
                        s = [s '-classNoise=' num2str(obj.get('classNoise'))];
                    end
                    s = [s '.mat'];
                    configCopy.set('outputFile',s);
                    configCopy.set('sourceNames', sourceNames);
                    o = DataSplitterConfigLoader(configCopy);
                    o.splitData();
                    o.saveSplit();
                end
            else
                data = load([inputFilePrefix '/' inputDataSets{1}]);
                if isfield(data,'data')
                    data = data.data;
                end
                newData = struct();
                featureIDs = [];
                directories = [];
                classIDs = [];
                classNames = [];
                if isfield(data,'featureIDs')
                    featureIDs = data.featureIDs;
                end
                if isfield(data,'directories')
                    directories = data.directories;
                end
                if isfield(data,'classIDs')
                    classIDs = data.classIDs;
                end
                if isfield(data,'classNames')
                    classNames = data.classNames;
                end
                newData.classNames = classNames;
                newData.classIDs = classIDs;                                
                newData.featureIDs = featureIDs;
                newData.directories = directories;
                
                
                YName = configs.get('YName');
                if configs.has('XName')
                    XName = configs.get('XName');
                    if iscell(XName)                    
                        X = [];
                        Y = [];
                        for nameIdx=1:length(XName)
                            error('TODO');
                        end
                    end                                
                    X = data.(XName);                    
                    newData.X = X;
                end
                if configs.has('WName')
                    WName = configs.get('WName');
                    W = data.(WName);
                    newData.W = W;
                end
                Y = data.(YName);                
                newData.Y = Y;
                newData.WNames = Helpers.getField(data,'WNames');
                newData.YNames = Helpers.getField(data,'YNames');
                newData.WIDs = Helpers.getField(data,'WIDs');
                %TODO: Why did we need this?
                %allFields = fields(data);
                %data = data.(allFields{1});
                configCopy = configs.copy();
                configCopy.set('data',newData);
                configCopy.set('originalData',newData);
                o = DataSplitterConfigLoader(configCopy);
                o.splitData();
                o.saveSplit();
            end
        end       
    end
end

