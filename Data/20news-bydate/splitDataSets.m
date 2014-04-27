function [] = splitDataSets()    
    trainX = load('train.data');
    testX = load('test.data');
    xDim = max(max(trainX(:,2)), max(testX(:,2)));
    numTrain = max(trainX(:,1));
    numTest = max(testX(:,1));
    trainX = sparse(trainX(:,1),trainX(:,2),trainX(:,3),numTrain,xDim);
    testX = sparse(testX(:,1),testX(:,2),testX(:,3),numTest,xDim);
    trainY = load('train.label');
    testY = load('test.label');
    names = {'C','R','S','T'};
    compLabels = 2:5;
    recLabels = 8:11;
    sciLabels = 12:15;
    talkLabels = 17:20;
    allLabels = {compLabels,recLabels,sciLabels,talkLabels};
    for i=1:length(allLabels)        
        labels = allLabels{i};
        X = zeros(0,xDim);
        Y = zeros(0,1);
        for j=1:length(labels)
            l = labels(j);
            trainInds = findIndsWithLabels(trainY,l);
            testInds = findIndsWithLabels(testY,l);
            num = length(trainInds) + length(testInds);
            X = [X ; trainX(trainInds,:) ; testX(testInds,:)];
            Y = [Y ; j*ones(num,1)];                      
        end
        data = struct();
        data.X = X;
        data.Y = Y;
        data.labels = labels;
        fileName = ['dataSets/' names{i} '.mat'];
        save(fileName,'data');
        clear data
    end
end

function [inds] = findIndsWithLabels(Y,labels)
    inds = false(size(Y));
    for i=1:length(labels)
        li = labels(i);
        inds = find(inds | (Y == li));
    end
end

function [X] = loadDataMatrix(file);
    X = load(file);
    X = sparse(X(:,1),X(:,2),X(:,3));
end