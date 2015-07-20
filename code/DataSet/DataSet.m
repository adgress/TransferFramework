classdef DataSet < LabeledData
    %DATASET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
    end
    properties        
        data
        dataFile
        X
        W
        WIDs
        WNames
        YNames
        featureNames
        featureIDs
    end    
    
    methods
        function obj = DataSet(dataFile,XName,YName,X,Y,type,trueY,instanceIDs)
            obj.dataFile = '';
            if ~exist('X','var')
                X = [];
            end
            if ~exist('Y','var')
                Y = [];
            end
            if ~exist('instanceIDs','var')
                instanceIDs = 1:length(Y);
                instanceIDs = instanceIDs';
            end
            if exist('dataFile','var') && ~isempty(dataFile)
                obj.dataFile = dataFile;
                obj.data = load(dataFile);
                if isfield(obj.data,'data')
                    obj.data = obj.data.data;
                end
                obj.X = obj.data.(XName);
                obj.Y = obj.data.(YName);
                obj.instanceIDs = zeros(size(obj.Y));
            else
                obj.X = X;
                obj.Y = Y;                                
                obj.instanceIDs = instanceIDs;
            end              
            
               
            if ~exist('trueY','var')
                trueY = obj.Y;
            end
            obj.trueY = trueY;
            if exist('type','var')
                obj.type = type;                
            else
                obj.type = LabeledData.NoType(length(obj.Y));
            end
            obj.ID2Labels = containers.Map;
            assert(length(obj.type) == length(obj.Y));
            %assert(size(obj.X,1) == size(obj.Y,1));
            obj.addEmptyFields();
            obj.W = [];
        end                
        
        function [train,test,validation] = splitDataSet(obj,split,dim)
            if ~exist('dim','var')
                dim = 1;
            end
            allDataSets = cell(3,1);
            XSplit = {[],[],[]};
            WSplit = {{},{},{}};
            if isempty(obj.X)
                for idx=1:length(allDataSets);                   
                    WSplit{idx} = Helpers.selectW(obj.W,split==idx,dim);
                end
            else
                assert(isempty(obj.W));
                XSplit = DataSet.splitMatrix(obj.X,split);
            end
            
            YSplit = DataSet.splitMatrix(obj.Y,split);
            trueYSplit = DataSet.splitMatrix(obj.trueY,split);
            instanceIDsSplit = DataSet.splitMatrix(obj.instanceIDs,split);            
            for i=1:numel(allDataSets)
                type = DataSet.NoType(length(YSplit{i}));               
                allDataSets{i} = DataSet('','','',XSplit{i},YSplit{i},...
                    type,trueYSplit{i},instanceIDsSplit{i});
                allDataSets{i}.ID2Labels = obj.ID2Labels;
                allDataSets{i}.W = WSplit{i};
            end
            train = allDataSets{1};
            test = allDataSets{2};
            validation = allDataSets{3};
        end
        
        function [sampledDataSet] = stratifiedSample(obj,numItems)
            [selectedItems] = obj.stratifiedSelection(numItems);
            sampledDataSet = DataSet.CreateNewDataSet(obj,selectedItems);
        end
        
        function [sampledDataSet] = stratifiedSampleNumPerClass(obj,numPerClass)
            [selectedItems] = obj.stratifiedSelectionNumPerClass(numPerClass);
            sampledDataSet = DataSet.CreateNewDataSet(obj,selectedItems);
        end
        
        function [sampledDataSet] = stratifiedSampleByLabels(obj,numItems,classesToKeep)
            if ~exist('classesToKeep','var')
                classesToKeep = [];
            end
            [selectedItems] = obj.stratifiedSelection(numItems,classesToKeep);
            sampledDataSet = DataSet.CreateNewDataSet(obj);
            sampledDataSet.Y(~selectedItems) = -1;
            if sum(sampledDataSet.Y > 0) ~= numItems
                warning('Sample size is weird'); 
            end
        end
        
        function [selectedItems] = stratifiedSelectionNumPerClass(obj,itemsPerClass,classesToKeep)
            if ~exist('classesToKeep','var')
                classesToKeep = [];
            end
            selectedItems = false(size(obj.X,1),1);
            for i=obj.classes()'               
                XWithClass = find(obj.Y==i);                
                itemsToUse = size(XWithClass,1);                
                if isempty(intersect(classesToKeep,i))
                    itemsToUse = min(itemsPerClass, itemsToUse);
                end
                selectedItems(XWithClass(1:itemsToUse)) = 1;                
            end
            c = obj.classes;
            assert(isequal(i,c(end)));
            %assert(sum(selectedItems) ~= 49);
            %assert(sum(selectedItems) == itemsPerClass*length(obj.classes()));
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
            c = obj.classes;
            assert(isequal(i,c(end)));
            %assert(sum(selectedItems) ~= 49);
            %assert(sum(selectedItems) == itemsPerClass*length(obj.classes()));
        end
        function [Xl, Yl, indices] = getLabeledData(obj)
            indices = obj.Y > 0;
            Xl = obj.X(indices,:);
            Yl = obj.Y(indices,:);
        end
        
        function [] = keepWithLabels(obj,labels)
            inds = obj.hasLabel(labels);
            obj.keep(inds);           
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
            obj.trueY = obj.trueY(~shouldRemove);
            obj.instanceIDs = obj.instanceIDs(~shouldRemove);
            if ~isempty(obj.isValidation)
                obj.isValidation = obj.isValidation(~shouldRemove);
            end
        end
        
        function [d] = getSourceData(obj)
            d = obj.getDataOfType(Constants.SOURCE);
        end
        
        function [d] = getTargetData(obj)
            d1 = obj.getDataOfType(Constants.TARGET_TRAIN);
            d2 = obj.getDataOfType(Constants.TARGET_TEST);
            d = DataSet.Combine(d1,d2);
        end
        
        function [d] = getDataOfType(obj,dataType)
            isType = obj.type == dataType;
            %{
            d = DataSet('','','',obj.X(isType,:),obj.Y(isType),...
                obj.type(isType));
            %}
            d = DataSet.CreateNewDataSet(obj,isType);
        end
        function [] = permuteW(obj,permutation,dim)
            i = 0;
            p = zeros(size(obj.W,dim),1);
                
            for idx=1:length(permutation)
                I = obj.WIDs{dim} == permutation(idx);
                range = i+1:i+sum(I);
                p(range) = find(I);
                i = i+sum(I);
            end
            for idx=1:length(obj.W)
                switch dim
                    case 1
                        obj.W{idx} = obj.W{idx}(p,:);
                    case 2
                        obj.W{idx} = obj.W{idx}(:,p);
                    otherwise
                        error('');
                end
            end
        end
        function [] = applyPermutation(obj,permutation,dim)
            if ~exist('dim','var')
                dim = 1;
            end            
            if isempty(obj.X)
                obj.permuteW(permutation,dim);              
            else
                assert(length(permutation) == length(obj.type));
                assert(isempty(obj.W));
                obj.X = obj.X(permutation,:);
            end
            obj.Y = obj.Y(permutation);
            obj.type = obj.type(permutation);
            obj.trueY = obj.trueY(permutation);
            obj.instanceIDs = obj.instanceIDs(permutation);
            if isempty(obj.isValidation)                
                obj.isValidation = false(size(obj.X,1),1);
            end
        end
        function [inds] = hasLabel(obj,labels)
            labels = unique(labels);
            labels = labels(:)';
            labelMat = repmat(labels,obj.size(),1);
            YMat = repmat(obj.trueY,1,length(labels));
            inds = logical(sum(labelMat == YMat,2));
        end
        function [] = keepFeatures(obj,featureIDsToKeep)
            if isempty(obj.featureIDs)
                display('keepFeatures: No feature IDs - skipping');
                return;
            end
            shouldKeep = false(1,size(obj.X,2));
            for i=featureIDsToKeep
                shouldKeep = shouldKeep | obj.featureIDs == i;
            end
            obj.X = obj.X(:,shouldKeep);
            obj.featureIDs = obj.featureIDs(shouldKeep);
            obj.featureNames = obj.featureNames(featureIDsToKeep);
        end   
        function [] = keepFeatureInds(obj,inds)
            obj.X = obj.X(:,inds);
            if ~isempty(obj.featureIDs)
                obj.featureIDs = obj.featureIDs(inds);
            end
        end
        function [] = addEmptyFields(obj)
            if isempty(obj.isValidation)                
                obj.isValidation = false(size(obj.X,1),1);
            end
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
            error('Should this be DataSet.Combine?');
            dataSet = combine(targetTrain,targetTest);
            dataSet = combine(dataSet,source);
        end
        function [f] = Combine(varargin)
            f = varargin{1}.copy();
            f.addEmptyFields();
            for i=2:length(varargin)
                m2 = varargin{i}.ID2Labels;
                varargin{i}.addEmptyFields();
                if ~isempty(m2) && ~isempty(f.ID2Labels)
                    %TODO: fix this check?
                    %assert(isempty(intersect(f.ID2Labels.keys,m2.keys)));
                end
                f.X = [f.X ; varargin{i}.X];
                f.Y = [f.Y ; varargin{i}.Y];
                f.type = [f.type ; varargin{i}.type];
                f.trueY = [f.trueY ; varargin{i}.trueY];
                f.instanceIDs = [f.instanceIDs ; varargin{i}.instanceIDs];
                f.ID2Labels = vertcat(f.ID2Labels,m2);
                f.isValidation = [f.isValidation; varargin{i}.isValidation] ;
            end
        end        
    end
    
    methods(Access=private,Static)        
        
        function [allSplits] = splitMatrix(mat,splits)
            allSplits = cell(max(splits),1);
            for i=1:3
                allSplits{i} = mat(splits == i,:);
            end
        end                
    end
    methods(Static)
        function [d] = CreateGaussianData(n,p,k)
            assert(k == 2);
            mu = zeros(k,p);
            mu(1,1:p) = ones(1,p);
            mu(2,1:p) = -ones(1,p);
            sigma = ones(1,p);
            g = gmdistribution(mu,sigma);
            [X,Y] = g.random(n);    
            %d = DataSet('',[],[],X,Y,type,trueY,instanceIDs);
            d = DataSet('',[],[],X,Y);
        end
        function [newData] = CreateNewDataSet(data,inds)
            if ~exist('inds','var')
                inds = 1:data.size();
            end
            newData = DataSet('','','',data.X(inds,:),data.Y(inds),...
                data.type(inds,:),data.trueY(inds),data.instanceIDs(inds));
            newData.ID2Labels = data.ID2Labels;
            newData.featureNames = data.featureNames;
            newData.featureIDs = data.featureIDs;
            newData.name = data.name;            
        end
        function [data] = MakeDataFromStruct(dataStruct)
            X = [];
            if isfield(dataStruct,'X')
                X = dataStruct.X;
            end
            data = DataSet('','','',X,dataStruct.Y);            
            data.YNames = dataStruct.YNames;
            if isfield(dataStruct,'W')
                data.W = dataStruct.W;
                data.WNames = dataStruct.WNames;
                data.WIDs = dataStruct.WIDs;
                %data.instanceIDs = [];
            end
            if isfield(dataStruct,'directories')
                data.featureNames = dataStruct.directories;
            end
            if isfield(dataStruct,'featureIDs')
                data.featureIDs = dataStruct.featureIDs;
            end
            data.trueY = data.Y;
        end
    end
end

