classdef SimilarityDataSet < handle 
    properties
        X
        W
        dataSetInds
    end
    
    methods
        function obj = SimilarityDataSet(X,W)
            if isa(X,'SimilarityDataSet')
                obj.X = X.X;
                obj.W = X.W;
                obj.dataSetInds = X.dataSetInds;
            else
                obj.X = X;
                obj.W = W;            
                numDataSets = length(X);            
                obj.dataSetInds = [];
                for i=1:numDataSets
                    n = size(obj.X{i},1);
                    obj.dataSetInds = [obj.dataSetInds ; i*ones(n,1)];
                end
            end
            obj.verify();
        end
        function [] = removeLastKFeatures(obj,k)
            numFeats = size(obj.X{1},2);
            shouldRemove = [false(numFeats-k,1) ; true(k,1)];
            obj.removeFeatures(shouldRemove);
        end
        function [] = removeFeatures(obj,shouldRemove)
            for i=1:length(obj.X)
                origX = obj.X{i};
                obj.X{i} = origX(:,~shouldRemove);
            end
        end
        function [W] = getCellW(obj)
            W = SimilarityDataSet.CreateCellW(obj.W,obj.dataSetInds);
        end
        
        function [X] = getBlockX(obj)
            X = SimilarityDataSet.CreateBlockX(obj.X);
        end                
        
        function [W] = getSubW(obj,sets1,sets2)
            if nargin < 3
                sets2 = sets1;
            end
            inds1 = zeros(size(obj.dataSetInds));
            inds2 = inds1;
            for i=1:length(sets1)
                inds1 = inds1 | obj.dataSetInds == sets1(i);
            end
            for i=1:length(sets2)
                inds2 = inds2 | obj.dataSetInds == sets2(i);
            end
            W = obj.W(inds1, inds2);
        end
        function [] = setSubW(obj,subW,set1,set2)
            inds1 = obj.dataSetInds == set1;
            inds2 = obj.dataSetInds == set2;
            obj.W(inds1,inds2) = subW;
            obj.W(inds2,inds1) = subW';
            obj.verify();
        end
        
        function [m] = numDataSets(obj)
            m = length(obj.X);
        end
        
        function [sizes] = getDataSetSizes(obj)
            m = obj.numDataSets();
            sizes = zeros(m,1);
            for i=1:m
                sizes(i) = size(obj.X{i},1);
            end
        end
        
        function [] = verify(obj)
            sizes = obj.getDataSetSizes();
            assert(sum(sizes) == length(obj.dataSetInds));
            assert(issorted(obj.dataSetInds));
            for i=1:obj.numDataSets()
                assert(sizes(i) == sum(obj.dataSetInds == i));                
            end
            assert(size(obj.W,1) == size(obj.W,2));
            assert(sum(sizes) == size(obj.W,1));
        end
    end
    
    %% Splitting Methods
    methods
        function [split] = splitDataAtInd(obj,percTrain,percTest,ind)
            numX = size(obj.X{ind},1);
            numTrain = floor(percTrain*numX);
            numValidate = ceil((1-percTrain-percTest)*numX);
            numTest = numX-numTrain-numValidate;
            
            split = Constants.TRAIN*ones(numX,1);
            p = randperm(numX);
            split(p(numTrain+1:numTrain+numValidate)) = Constants.VALIDATE;
            split(p(numTrain+numValidate+1:end)) = Constants.TEST;
        end
        
        function [] = removeData(obj,shouldRemove,ind)
            obj.X{ind}(shouldRemove,:) = [];
            newW = cell(obj.numDataSets());
            for i=1:obj.numDataSets()
                for j=1:obj.numDataSets()
                    Wij = obj.getSubW(i,j);
                    if i == ind
                        Wij(shouldRemove,:) = [];
                    end
                    if j==ind
                        Wij(:,shouldRemove) = [];
                    end
                    newW{i,j} = Wij;
                end
            end
            start = min(find(obj.dataSetInds == ind));
            obj.dataSetInds(start+find(shouldRemove)-1) = [];
            obj.W = SimilarityDataSet.CreateBlockW(newW);
            obj.verify();
        end
        
        function [dataSets] = createDataSetsWithSplit(obj,split,ind)
            sizes = histc(split,1:max(split));
            dataSets = {};
            for i=Constants.TRAIN:Constants.TEST
                shouldSelect = split == i;
                dataSets{i} = SimilarityDataSet(obj.X,obj.W);
                dataSets{i}.removeData(~shouldSelect,ind);
                dataSets{i}.verify();
            end
        end
        
        function [split] = generateSplitArray(obj,percTrain,percTest,xInd,yInd)
            error('Not yet implemented');
            percValidate = 1 - percTrain - percTest;
            numX = size(obj.X{xInd},1);
            numY = size(obj.X{yInd},1);
            Wxy = obj.getSubW(xInd,yInd);
            numPerY = sum(Wxy);
            numYPerSplit = zeros(numY,Constants.TEST);
            for i=1:numY
                ni = numPerY(i);            
                numYPerSplit(i,Constants.TRAIN) = floor(percTrain*ni);
                numYPerSplit(i,Constants.VALIDATE) = ceil(percValidate*ni);
                numYPerSplit(i,Constants.TEST) = ni - sum(numYPerSplit(i,:));
            end
            split = ones(numX,1);            
        end 
        function [sampledTrain,kept] = randomSampleInstances(obj,percTrain,trainIndex,s)
            if nargin < 4
                s = 0;
            end
            numInstances = size(obj.X{trainIndex},1);
            rs = RandStream('mt19937ar','Seed',s);
            perm = rs.randperm(numInstances);
            toRemove = perm(1:floor((1-percTrain)*numInstances));
            shouldRemove = false(numInstances,1);
            shouldRemove(toRemove) = true;
            
            sampledTrain = SimilarityDataSet(obj.X,obj.W);
            sampledTrain.removeData(shouldRemove,trainIndex);
            kept = ~shouldRemove;
        end
        
        function sampledTrain = randomSampleRelations(obj,percTrain,trainIndex,testIndex)
            Wij = obj.getSubW(trainIndex,testIndex);
            numPerLabel = sum(Wij);
            numRelations = sum(numPerLabel);
            rs = RandStream('mt19937ar','Seed',1);
            perm = rs.randperm(numRelations);
            permToClear = perm(1:floor((1-percTrain)*length(perm)));
            relationInds = find(Wij(:));
            relationsToClear = relationInds(permToClear);
            sampledWij = Wij;
            sampledWij(relationsToClear) = 0;
            
            sampledTrain = SimilarityDataSet(obj.X,obj.W);
            sampledTrain.setSubW(sampledWij,trainIndex,testIndex);
        end
    end
    
    methods(Static)
        function [blockX] = CreateBlockX(X)
            sizes = zeros(length(X),1);
            for i=1:length(X)
                sizes(i) = size(X{i},1);
            end
            numCols = 0;
            for i=1:length(X)
                numCols = numCols + size(X{i},2);
            end
            total = sum(sizes);
            blockX = zeros(total,numCols);
            startRow = 0;
            startCol = 0;
            for i=1:length(sizes)
                n = size(X{i},1);                
                m = size(X{i},2);
                rangeRow = startRow+1:startRow+n;
                rangeCol = startCol+1:startCol+m;
                blockX(rangeRow,rangeCol) = X{i};
                startRow = startRow+n;
                startCol = startCol+m;
            end
        end
        
        function W = CreateCellW(blockW,inds)
            numBlocks = max(inds);
            W = cell(numBlocks);
            for i=1:numBlocks
                for j=1:numBlocks
                    Wij = blockW(inds == i,inds==j)
                    W{i,j} = Wij;                    
                end
            end
        end
        
        function [blockW] = CreateBlockW(W)
            [totalRows,totalCols] = SimilarityDataSet.GetWSize(W);
            blockW = zeros(totalRows,totalCols);
            startRow = 0;
            for i=1:size(W,1)
                startCol = 0;
                numRows = size(W{i,1},1);
                for j=1:size(W,2)
                    Wij = W{i,j};                    
                    numCols = size(Wij,2);
                    rows = startRow+1:startRow+numRows;
                    cols = startCol+1:startCol+numCols;
                    blockW(rows,cols) = Wij;
                    startCol = startCol+numCols;
                end
                startRow = startRow+numRows;                
            end
        end
        function [numRows,numCols] = GetWSize(W)
            numRows = 0;
            numCols = 0;
            for i=1:size(W,1)
                numRows = numRows + size(W{i,1},1);
            end
            for j=1:size(W,2)
                numCols = numCols + size(W{1,j},2);
            end
        end
    end
end