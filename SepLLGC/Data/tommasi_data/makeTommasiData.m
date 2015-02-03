function [] = makeTommasiData()
    directories = {'SIFT','RECOV','PHOG','LBP'};    
    dataDir = 'Transfer/Data/tommasi_data/';
    data = struct();
    data.directories = directories;
    for dirIdx=1:length(directories)        
        currDataDir = [dataDir directories{dirIdx} '/'];
        dirData = dir(currDataDir);
        dirData = removeDirectories(dirData);
        fileNames = getFileNames(dirData);        
        allData = {};
        for fileIdx=1:length(dirData)
            fileName = [currDataDir  fileNames{fileIdx}];
            y = load(fileName);
            allFields = fields(y);            
            assert(length(allFields) == 1);
            allData{fileIdx} = y.(allFields{1});
        end        
        if dirIdx == 1
            data.classNames = getClassNames(dirData);
            data.classIDs = getClassIDs(dirData);
            data.X = [];
            Y = makeLabelVector(allData,data.classIDs);
            data.Y = Y;
            data.featureIDs = [];
        end        
        X = makeDataMatrix(allData);   
        data.X = [data.X X];
        m = size(X,2);
        data.featureIDs = [data.featureIDs repmat(dirIdx,1,m)];
    end
    save([dataDir 'tommasi_data.mat'],'data')
end

function [X] = makeDataMatrix(allData)
    numItems = cellfun(@(x) size(x,1),allData);
    numDims = size(allData{1},2);
    X = zeros(sum(numItems),numDims);
    XIdx = 0;
    for allDataIdx=1:length(allData)
        X(XIdx+1:XIdx+numItems(allDataIdx),:) = allData{allDataIdx};
        XIdx = XIdx + numItems(allDataIdx);
    end
end

function [Y] = makeLabelVector(allData,labels)
    numItems = cellfun(@(x) size(x,1),allData);
    Y = zeros(sum(numItems),1);
    YIdx = 0;
    for idx=1:length(labels)
        label = labels(idx);
        n = numItems(idx);
        Y(YIdx+1:YIdx+n) = repmat(label,n,1);
        YIdx = YIdx + n;
    end
end

function [fileNames] = getFileNames(dirData)
    fileNames = {};
    for idx=1:length(dirData)
        fileNames{idx} = dirData(idx).name;
    end
end

function [classNames] = getClassNames(dirData)
    classNames = {};
    for idx=1:length(dirData)
        assert(~dirData(idx).isdir);
        s = dirData(idx).name;
        classNames{idx} = StringHelpers.RemoveSuffix(s,'.mat');
    end
end

function [classIDs] = getClassIDs(dirData)
    classNames = getClassNames(dirData);
    classIDs = [];
    for idx=1:length(classNames)
        s = classNames{idx};
        classIDs(idx) = str2num(s(1:3));
    end
end

function [dirData] = removeDirectories(dirData)
    idx=1;
    while idx <= length(dirData);
        if dirData(idx).isdir
            dirData(idx) = [];
            continue            
        end
        idx = idx + 1;
    end
end