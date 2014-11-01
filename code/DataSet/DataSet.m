classdef DataSet < LabeledData
    %DATASET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
    end
    properties        
        data
        dataFile
        X
        featureNames
        featureIDs
    end    
    methods
        function obj = DataSet(dataFile,XName,YName,X,Y,type)
            obj.dataFile = '';
            if ~exist('X','var')
                X = [];
            end
            if ~exist('Y','var')
                Y = [];
            end
            if exist('dataFile','var') && ~isempty(dataFile)
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
            
            if exist('type','var')
                obj.type = type;                
            else
                obj.type = LabeledData.NoType(length(obj.Y));
            end
            assert(length(obj.type) == length(obj.Y));
            assert(size(obj.X,1) == size(obj.Y,1));
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
            sampledDataSet = DataSet.CreateNewDataSet(obj,selectedItems);
        end
        
        function [sampledDataSet] = stratifiedSampleByLabels(obj,numItems,classesToKeep)
            if ~exist('classesToKeep','var')
                classesToKeep = [];
            end
            [selectedItems] = obj.stratifiedSelection(numItems,classesToKeep);
            sampledDataSet = DataSet.CreateNewDataSet(obj);
            sampledDataSet.Y(~selectedItems) = -1;
        end
        
        function [selectedItems] = stratifiedSelection(obj,numItems,classesToKeep)
            if ~exist('classesToKeep','var')
                classesToKeep = [];
            end
            itemsPerClass = ceil(numItems/obj.numClasses);
            selectedItems = false(size(obj.X,1),1);
            for i=obj.classes()'               
                XWithClass = find(obj.Y==i);                
                itemsToUse = size(XWithClass,1);                
                if isempty(intersect(classesToKeep,i))
                    itemsToUse = min(itemsPerClass, itemsToUse);
                end
                selectedItems(XWithClass(1:itemsToUse)) = 1;                
            end
        end
        function [Xl, Yl, indices] = getLabeledData(obj)
            indices = obj.Y > 0;
            Xl = obj.X(indices,:);
            Yl = obj.Y(indices,:);
        end
        
        function [] = keep(obj,shouldKeep)
            if ~islogical(shouldKeep)
                logArray = false(obj.size(),1);
                logArray(shouldKeep) = true;
                shouldKeep = logArray;
            end
            obj.remove(~shouldKeep);
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
            %{
            d = DataSet('','','',obj.X(isType,:),obj.Y(isType),...
                obj.type(isType));
            %}
            d = DataSet.CreateNewDataSet(obj,isType);
        end
        function [] = applyPermutation(obj,permutation)
            assert(length(permutation) == length(obj.type));
            obj.X = obj.X(permutation,:);
            obj.Y = obj.Y(permutation);
            obj.type = obj.type(permutation);
        end
        function [inds] = hasLabel(obj,labels)
            labels = unique(labels);
            labels = labels(:)';
            labelMat = repmat(labels,obj.size(),1);
            YMat = repmat(obj.Y,1,length(labels));
            inds = logical(sum(labelMat == YMat,2));
        end
        function [] = keepFeatures(obj,featureIDsToKeep)
            shouldKeep = false(1,size(obj.X,2));
            for i=featureIDsToKeep
                shouldKeep = shouldKeep | obj.featureIDs == i;
            end
            obj.X = obj.X(:,shouldKeep);
            obj.featureIDs = obj.featureIDs(shouldKeep);
            obj.featureNames = obj.featureNames(featureIDsToKeep);
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
                maxTrainNumPerLabel = configs.get('maxTrainNumPerLabel');
            end
            assert(sum(percentageArray) == 1,'Split doesn''t sum to one');
            percentageArray = cumsum(percentageArray);
            dataSize = size(Y,1);
            split = zeros(dataSize,1);
            uniqueY = unique(Y);
            for i=1:length(uniqueY)
                thisClass = find(Y == uniqueY(i));
                numThisClass = numel(thisClass);
                perm = randperm(numThisClass);
                thisClassRandomized = thisClass(perm);
                numToPick = ceil(numThisClass*percentageArray);
                %diff = max(numToPick(1)-maxTrainNumPerLabel,0);
                numToPick(1) = min(numToPick(1),maxTrainNumPerLabel);
                %numToPick = numToPick-diff;
                numEach = [0 numToPick];
                assert(numToPick(2)-numToPick(1) > 0);
                for j=1:numel(percentageArray)       
                    if numEach(j) == numEach(j+1)
                        display('TODO: Potential off by one error');
                        continue;
                    end
                    indices = thisClassRandomized(numEach(j)+1:numEach(j+1));
                    split(indices) = j;                    
                end
                assert(sum(split(thisClassRandomized) == 1) == numToPick(1));
            end
            assert(sum(split==0) == 0);
        end
        
        function [allSplits] = splitMatrix(mat,splits)
            allSplits = cell(max(splits),1);
            for i=1:3
                allSplits{i} = mat(splits == i,:);
            end
        end                
    end
    methods(Static)
        function [newData] = CreateNewDataSet(data,inds)
            if ~exist('inds','var')
                inds = 1:data.size();
            end
            newData = DataSet('','','',data.X(inds,:),data.Y(inds,:),data.type(inds,:));
            newData.featureNames = data.featureNames;
            newData.featureIDs = data.featureIDs;
        end
        function [data] = MakeDataFromStruct(dataStruct)
            data = DataSet('','','',dataStruct.X,dataStruct.Y);
            data.featureNames = dataStruct.directories;
            data.featureIDs = dataStruct.featureIDs;
        end
    end
end

