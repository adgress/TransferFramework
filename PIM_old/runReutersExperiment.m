function [] = runReutersExperiment
    languages = {'EN','FR','GR','IT','SP'};
    for i=1:numel(languages)
        filename = ['reuters/' languages{i} '.mat'];
        if ~exist(filename)
            allData = loadReutersData(languages{i},languages);
            save(filename,'allData');
        end
    end
    for i=1:numel(languages)        
        allData = containers.Map;
        maxDim = 0;
        for j=1:numel(languages)
            readFile = ['reuters/' languages{j} '.mat'];
            x = load(readFile);
            key = [languages{j} '-' languages{i}];
            key
            data = x.allData(key);
            maxDim = max([maxDim size(data.features,2)]);
            allData(languages{j}) = data;
        end
        filename = ['reuters/orig-' languages{i}];
        save(filename,'allData');
    end
end

function [allData] = loadReutersData(src,dest)
    allData = containers.Map;
    key2index = containers.Map;
    key2index('C15') = 1;
    key2index('CCAT') = 2;
    key2index('E21') = 3;
    key2index('ECAT') = 4;
    key2index('GCAT') = 5;
    key2index('M11') = 6;
    for i=1:numel(dest)
        d = dest{i};
        fileName = ['reuters/' src '/Index_' d '-' src];        
        labels = zeros(30000,1);
        features = sparse(30000,30000);
        dataSize = 0;
        maxDim = 0;
        fid = fopen(fileName);
        while true
            line = fgetl(fid);
            if ~ischar(line)
                break;
            end
            dataSize = dataSize + 1;
            [A] = textscan(line,'%s ');
            A = A{1};
            textLabel = A{1};
            labels(dataSize) = key2index(textLabel);
            A = A(2:end);
            for j=1:numel(A)
                A{j} = [A{j} ' '];
            end
            s = cell2mat(A');
            if length(s) == 0
                s = '';
            end
            indVals = sscanf(s,'%d:%f');
            indices = indVals(1:2:end);
            vals = indVals(2:2:end);
            features(dataSize,indices) = vals;
            maxDim = max([maxDim max(indices)]);
        end
        fclose(fid);
        labels = labels(1:dataSize);
        features = features(1:dataSize,1:maxDim);
        data = struct();
        data.features = features;
        data.labels = labels;
        key = [src '-' d];
        allData(key) = data;
        dataSize
        maxDim
    end
end