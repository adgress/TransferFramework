classdef DataSet < handle
    %DATASET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
    end
    properties        
        data
        dataFile
        X
        Y        
        type
    end    
    methods
        function obj = DataSet(dataFile,XName,YName,X,Y,type)
            obj.dataFile = '';
            if nargin < 6
                display('');
            end
            if ~isempty(dataFile)
                obj.dataFile = dataFile;
                obj.data = load(dataFile);
                if isfield(obj.data,'data')
                    obj.data = obj.data.data;
                end
                obj.X = obj.data.(XName);
                obj.Y = obj.data.(YName);
            else
                obj.X = X;
                obj.Y = Y;
            end                                             
            assert(size(obj.X,1) == size(obj.Y,1));
            if nargin > 3
                obj.type = type;
                assert(length(obj.type) == length(obj.Y));
            end
        end
          
        function [n] = size(obj)
            n = length(obj.Y);
        end
        function [n] = numSource(obj)
            n = sum(obj.type == Constants.SOURCE);
        end
        function [n] = numLabeledSource(obj)
            n = sum(obj.Y > 0 & ...
                obj.type == Constants.SOURCE);
        end
        function [split] = generateSplitArray(obj,percTrain,percTest)            
            percValidate = 1 - percTrain - percTest;
            split = DataSet.generateSplit([percTrain percTest percValidate],...
                obj.Y);
        end
        
        function [train,test,validation] = splitDataSet(obj,split)            
            XSplit = DataSet.splitMatrix(obj.X,split);
            YSplit = DataSet.splitMatrix(obj.Y,split);
            allDataSets = cell(3,1);
            for i=1:numel(allDataSets)
                type = DataSet.NoType(length(YSplit{i}));
                allDataSets{i} = DataSet('','','',XSplit{i},YSplit{i},type);
            end
            train = allDataSets{1};
            test = allDataSets{2};
            validation = allDataSets{3};
        end
        
        function [sampledDataSet] = stratifiedSample(obj,numItems)
            [selectedItems] = obj.stratifiedSelection(numItems);
            sampledDataSet = DataSet('','','',...
                obj.X(selectedItems,:),obj.Y(selectedItems,:));
        end
        
        function [sampledDataSet] = stratifiedSampleByLabels(obj,numItems)
            [selectedItems] = obj.stratifiedSelection(numItems);
            YCopy = obj.Y;
            YCopy(~selectedItems) = -1;
            dataType = DataSet.NoType(length(YCopy));
            sampledDataSet = DataSet('','','',obj.X,YCopy,dataType);
        end
        
        function [selectedItems] = stratifiedSelection(obj,numItems)
            numClasses = max(obj.Y);
            itemsPerClass = ceil(numItems/numClasses);
            selectedItems = logical(zeros(size(obj.X,1),1));
            for i=1:numClasses
                XWithClass = find(obj.Y==i);
                itemsToUse = min([itemsPerClass size(XWithClass,1)]);
                selectedItems(XWithClass(1:itemsToUse)) = 1;                
            end
        end
        function [Xl, Yl, indices] = getLabeledData(obj)
            indices = obj.Y > 0;
            Xl = obj.X(indices,:);
            Yl = obj.Y(indices,:);
        end
        function [Yu] = getBlankLabelVector(obj)
            Yu = obj.Y;
            Yu(:) = -1;
        end
        function [b] = hasTypes(obj)
            b = length(obj.Y) == length(obj.type) && ...
                isempty(find(obj.type == Constants.NO_TYPE));
        end
        function [b] = isSource(obj)
            b = sum(obj.type == Constants.SOURCE) == length(obj.Y);            
        end
        function [b] = isTarget(obj)
            b = sum(obj.type == Constants.TARGET_TRAIN | ...
                obj.type == Constants.TARGET_TEST) == length(obj.Y);            
        end
        function [] = remove(obj,shouldRemove)
            if ~islogical(shouldRemove)
                logArray = false(obj.size(),1);
                logArray(shouldRemove) = true;
                shouldRemove = logArray;
            end
            obj.X = obj.X(~shouldRemove,:);
            obj.Y = obj.Y(~shouldRemove);
            obj.type = obj.type(~shouldRemove);
        end
        function [] = setTargetTrain(obj)
            obj.type = DataSet.TargetTrainType(obj.size());
        end
        function [] = setTargetTest(obj)
            obj.type = DataSet.TargetTestType(obj.size());
        end
        function [] = setSource(obj)
            obj.type = DataSet.SourceType(obj.size());
        end
        function [] = removeTestLabels(obj)
            obj.Y(obj.type == Constants.TARGET_TEST) = -1;
        end 
        function [d] = getDataOfType(obj,dataType)
            isType = obj.type == dataType;
            d = DataSet('','','',obj.X(isType,:),obj.Y(isType),...
                obj.type(isType));
        end
        function [d] = getSourceData(obj)
            d = obj.getDataOfType(Constants.SOURCE);            
        end
        function [d] = getTargetData(obj)
            d = DataSet.Combine(obj.getDataOfType(Constants.TARGET_TRAIN),...
                obj.getDataOfType(Constants.TARGET_TEST));
        end
    end
    
    methods(Static)
        function [split] = generateSplitForLabels(percentageArray,Y)
            split = DataSet.generateSplit(percentageArray,Y);
        end
        function [dataSet] = CreateDataSet(targetTrain,targetTest,source)
            assert(targetTrain.isTarget());
            assert(targetTest.isTarget());
            assert(source.isSource);
            dataSet = combine(targetTrain,targetTest);
            dataSet = combine(dataSet,source);
        end
        function [f] = Combine(d1,d2)
            f = DataSet('','','',[d1.X ; d2.X],[d1.Y;d2.Y],...
                [d1.type;d2.type]);
        end
        
        function [v] = TargetTrainType(n)
            v = Constants.TARGET_TRAIN*ones(n,1);
        end
        function [v] = TargetTestType(n)
            v = Constants.TARGET_TEST*ones(n,1);
        end
        function [v] = SourceType(n)
            v = Constants.SOURCE*ones(n,1);
        end
        function [v] = NoType(n)
            v = Constants.NO_TYPE*ones(n,1); 
        end
    end
    
    methods(Access=private,Static)
        function [split] = generateSplit(percentageArray,Y)
            assert(sum(percentageArray) == 1,'Split doesn''t sum to one');
            percentageArray = cumsum(percentageArray);
            dataSize = size(Y,1);
            split = zeros(dataSize,1);
            for i=1:max(Y)
                thisClass = find(Y == i);
                numThisClass = numel(thisClass);
                perm = randperm(numThisClass);
                thisClassRandomized = thisClass(perm);
                numEach = [1 ceil(numThisClass*percentageArray)];
                
                for j=1:numel(percentageArray)       
                    if numEach(j) == numEach(j+1)
                        display('TODO: Potential off by one error');
                        continue;
                    end
                    indices = thisClassRandomized(numEach(j):numEach(j+1));
                    split(indices) = j;
                end
            end            
        end
        
        function [allSplits] = splitMatrix(mat,splits)
            allSplits = cell(max(splits),1);
            for i=1:3
                allSplits{i} = mat(splits == i,:);
            end
        end
    end
end

