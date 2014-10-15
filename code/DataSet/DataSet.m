classdef DataSet < LabeledData
    %DATASET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
    end
    properties        
        data
        dataFile
        X
    end    
    methods
        function obj = DataSet(dataFile,XName,YName,X,Y,type)
            obj.dataFile = '';
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
          
        
        
        function [split] = generateSplitArray(obj,percTrain,percTest,configs)
            percValidate = 1 - percTrain - percTest;
            split = DataSet.generateSplit([percTrain percTest percValidate],...
                obj.Y,configs);
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
                obj.X(selectedItems,:),obj.Y(selectedItems,:),...
                obj.type(selectedItems));
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
        
        function [d] = getDataOfType(obj,dataType)
            isType = obj.type == dataType;
            d = DataSet('','','',obj.X(isType,:),obj.Y(isType),...
                obj.type(isType));
        end        
    end
    
    methods(Static)
        function [split] = generateSplitForLabels(percentageArray,Y)
            split = DataSet.generateSplit(percentageArray,Y);
        end
        function [dataSet] = CreateDataSet(targetTrain,targetTest,source)
            assert(targetTrain.isTargetDataSet());
            assert(targetTest.isTargetDataSet());
            assert(source.isSourceDataSet());
            dataSet = combine(targetTrain,targetTest);
            dataSet = combine(dataSet,source);
        end
        function [f] = Combine(d1,d2)
            f = DataSet('','','',[d1.X ; d2.X],[d1.Y;d2.Y],...
                [d1.type;d2.type]);
        end
        
    end
    
    methods(Access=private,Static)
        function [split] = generateSplit(percentageArray,Y,configs)
            maxTrainNumPerLabel = inf;
            if exist('configs','var') && isKey(configs,'maxTrainNumPerLabel')
                maxTrainNumPerLabel = configs('maxTrainNumPerLabel');
            end
            assert(sum(percentageArray) == 1,'Split doesn''t sum to one');
            percentageArray = cumsum(percentageArray);
            dataSize = size(Y,1);
            split = zeros(dataSize,1);
            for i=1:max(Y)
                thisClass = find(Y == i);
                numThisClass = numel(thisClass);
                perm = randperm(numThisClass);
                thisClassRandomized = thisClass(perm);
                numToPick = ceil(numThisClass*percentageArray);
                diff = max(numToPick(1)-maxTrainNumPerLabel,0);
                numToPick = numToPick-diff;
                numEach = [1 numToPick];
                
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

