classdef SimilarityDataSet < handle 
    properties
        X
        W
        dataSetInds
    end
    
    methods
        function obj = SimilarityDataSet(X,W)
            obj.X = X;
            obj.W = W;            
            numDataSets = length(X);            
            obj.dataSetInds = [];
            for i=1:numDataSets
                n = size(obj.X{i},1);
                obj.dataSetInds = [obj.dataSetInds ; i*ones(n,1)];
            end
            obj.verify();
        end                
        
        function [X] = getBlockX(obj)
            X = SimilarityDataSet.CreateBlockX(obj.X);
        end
        
        function [W] = getSubW(obj,ind1,ind2)
            W = obj.W(obj.dataSetInds == ind1, obj.dataSetInds == ind2);
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