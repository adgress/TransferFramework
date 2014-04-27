classdef DataSet < handle
    %DATASET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
        data
        dataFile
        X
        Y
    end    
    methods
        function obj = DataSet(dataFile,XName,YName,X,Y)
            obj.dataFile = '';
            if ~isempty(dataFile)
                obj.dataFile = dataFile;
                obj.data = load(dataFile);
                if isfield(obj.data,'data')
                    obj.data = obj.data.data;
                end
                obj.X = obj.data.(XName);
                obj.Y = obj.data.(YName);
            end
            if nargin > 3
                obj.X = X;
                obj.Y = Y;
            end
            assert(size(obj.X,1) == size(obj.Y,1));
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
                allDataSets{i} = DataSet('','','',XSplit{i},YSplit{i});
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
            sampledDataSet = DataSet('','','',obj.X,YCopy);
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
    end
    
    methods(Static)
        function [split] = generateSplitForLabels(percentageArray,Y)
            split = DataSet.generateSplit(percentageArray,Y);
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

