function [] = createDomains
    dataSetNames = {'C','R','S','T'};
    dataSets = {};
    for i=1:length(dataSetNames)
        data = load(['dataSets/' dataSetNames{i} '.mat']);
        dataSets{i} = data.data;
    end
    for i=1:length(dataSets)        
        for j=i+1:length(dataSets)
            d1 = dataSets{i};
            d2 = dataSets{j};
            for k=1:length(d1.labels)
                d1Inds = find(d1.Y == k);
                d2Inds = find(d2.Y == k);
                data = struct();
                data.X = [d1.X(d1Inds,:) ; d2.X(d2Inds,:)];
                data.Y = [ones(size(d1Inds)) ; 2*ones(size(d2Inds))];
                data.labels = [d1.labels(k) ; d2.labels(k)];
                fileName = ['Domains/' dataSetNames{i} dataSetNames{j} ...
                    num2str(k) '.mat'];
                save(fileName,'data');
            end
        end
    end
end