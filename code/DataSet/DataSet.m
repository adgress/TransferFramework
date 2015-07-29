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
        featureNames
        featureIDs
        Wdim        
    end    
    properties(Dependent)
        numInstances
    end
    
    methods
        function obj = DataSet(dataFile,XName,YName,X,Y,type,trueY,instanceIDs)            
            obj.dataFile = '';
            obj.objectType = [];
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
            obj.Wdim = -1;
        end                
        function [n] = get.numInstances(obj)
            if isempty(obj.W)
                n = size(Y,1);
            else
                if isempty(obj.Wdim)
                    n = size(obj.W{1},1);
                else
                    n = size(obj.W{1},obj.Wdim);
                end
            end
        end
        function [train,test,validation] = splitDataSet(obj,split,dim)
            if ~exist('dim','var')
                dim = obj.Wdim;
            end
            allDataSets = cell(3,1);
            XSplit = {[],[],[]};
            WSplit = {{},{},{}};
            WIDSplit = cell(3,1);
            WNameSplit = cell(3,1);
            YSplit = {};            
            trueYSplit = {};
            instanceIDsSplit = {};
            typeSplit = {};
            if isempty(obj.X)
                assert(max(split) == 2);
                %isTest = split == 2;
                %p = [find(~isTest) ; find(isTest)];
                %obj.applyPermutation(p);
                %split = split(p);
                type = obj.type;
                type(split == 1) = Constants.TARGET_TRAIN;
                type(split == 2) = Constants.TARGET_TEST;
                for idx=1:length(allDataSets);                   
                    I = split==idx;                    
                    %This is important if there's extra unlabeled data we
                    %want to use for training
                    %{
                    if idx == 1
                        I = I | split == 0;
                    end
                    
                    WSplit{idx} = Helpers.selectW(obj.W,I,dim);
                    if ~isempty(obj.WIDs)
                        WIDSplit{idx} = Helpers.selectFromCells(obj.WIDs,I,dim);
                    end
                    if ~isempty(obj.WNames)
                        WNameSplit{idx} = Helpers.selectFromCells(obj.WNames,I,dim);
                    end                    
                    %}
                    
                    %A lot of things are easier if we just don't split W
                    WSplit{idx} = obj.W;
                    WIDSplit{idx} = obj.WIDs;
                    WNameSplit{idx} = obj.WNames;
                    typeSplit{idx} = type;
                    YSplit{idx} = obj.Y;
                    trueYSplit{idx} = obj.trueY;
                    instanceIDsSplit{idx} = obj.instanceIDs;
                end
            else
                assert(isempty(obj.W));
                XSplit = DataSet.splitMatrix(obj.X,split);
                YSplit = DataSet.splitMatrix(obj.Y,split);
                trueYSplit = DataSet.splitMatrix(obj.trueY,split);
                instanceIDsSplit = DataSet.splitMatrix(obj.instanceIDs,split);            
                typeSplit = DataSet.splitMatrix(obj.type,split);
                error('Update typeSplit!');
            end
            
            
            for i=1:numel(allDataSets)
                type = DataSet.NoType(length(YSplit{i}));   
                %{
                allDataSets{i} = DataSet('','','',XSplit{i},YSplit{i},...
                    type,trueYSplit{i},instanceIDsSplit{i});
                allDataSets{i}.ID2Labels = obj.ID2Labels;
                allDataSets{i}.W = WSplit{i};
                %}
                allDataSets{i} = obj.copy();
                allDataSets{i}.X = XSplit{i};
                allDataSets{i}.Y = YSplit{i};
                allDataSets{i}.type = typeSplit{i};
                allDataSets{i}.trueY = trueYSplit{i};
                allDataSets{i}.instanceIDs = instanceIDsSplit{i};
                allDataSets{i}.W = WSplit{i};      
                allDataSets{i}.WIDs = WIDSplit{i};      
                allDataSets{i}.WNames = WNameSplit{i};
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
            keepTestLabels = true;
            if ~exist('classesToKeep','var')
                classesToKeep = [];
            end
            [selectedItems] = obj.stratifiedSelection(numItems,classesToKeep);
            sampledDataSet = DataSet.CreateNewDataSet(obj);
            if keepTestLabels
                selectedItems = selectedItems | obj.isTargetTest();
            end
            sampledDataSet.Y(~selectedItems,:) = -1;
            if sum(sampledDataSet.Y(sampledDataSet.isTargetTrain) > 0) ~= numItems
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
        
        function [selectedItems] = stratifiedSelection(obj,numItems,classesToKeep,yIdx)
            keepAllTest = true;
            if ~exist('classesToKeep','var')
                classesToKeep = [];
            end
            if ~exist('yIdx','var')
                yIdx = 1;
            end
            itemsPerClass = ceil(numItems/obj.numClasses);
            selectedItems = false(size(obj.Y,1),1);
            for i=obj.classes()'               
                if keepAllTest
                    XWithClass = find(obj.Y(:,yIdx)==i & obj.isLabeledTargetTrain());     
                else
                    XWithClass = find(obj.Y(:,yIdx)==i);     
                end
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
            if ~isempty(obj.X)
                obj.X = obj.X(~shouldRemove,:);
                assert(isempty(obj.W));
            else
                obj.W = Helpers.selectW(obj.W,~shouldRemove,obj.Wdim);
                obj.WIDs = Helpers.selectFromCells(obj.WIDs,~shouldRemove,obj.Wdim);
                obj.WNames = Helpers.selectFromCells(obj.WNames,~shouldRemove,obj.Wdim,true);
            end
            obj.Y = obj.Y(~shouldRemove,:);
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
            p = {};
            if ~isempty(dim)            
                switch dim
                    case 1
                        p = {permutation, 1:size(obj.W{1},2)};
                    case 2
                        p = {1:size(obj.W{1},1), permutation};
                    otherwise
                        error('');
                end
                for idx=1:length(obj.W)
                    obj.W{idx} = obj.W{idx}(p{:});                
                end
            else
                for idx=1:length(obj.W)
                    obj.W{idx} = obj.W{idx}(permutation,permutation);
                end
                p = {permutation};
            end
            
            for idx=1:length(obj.WIDs)
                obj.WIDs{idx} = obj.WIDs{idx}(p{idx});
                if ~isempty(obj.WNames)
                    obj.WNames{idx} = obj.WNames{idx}(p{idx});
                end
            end    
        end
        function [] = applyPermutation(obj,permutation,dim)
            if ~exist('dim','var')
                dim = obj.Wdim;
            end            
            if isempty(obj.X)
                obj.permuteW(permutation,dim);              
            else
                assert(length(permutation) == length(obj.type));
                assert(isempty(obj.W));
                obj.X = obj.X(permutation,:);
            end
            obj.Y = obj.Y(permutation,:);
            obj.type = obj.type(permutation);
            obj.trueY = obj.trueY(permutation,:);
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
        %{
        function [I] = get.isLabeled(obj)
            I = obj.Y > 0;
        end
        %}
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
                assert((isempty(f.Wdim) && isempty(f.Wdim)) || ...
                    f.Wdim == varargin{i}.Wdim);                
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
                %Things become a lot easier if we assume W isn't split
                %{
                if ~isempty(f.W)
                    di = varargin{i};
                    f.W = Helpers.combineW(f.W,di.W,f.Wdim);
                    f.WIDs = Helpers.combineCellArrays(f.WIDs,di.WIDs,f.Wdim);
                    f.WNames = Helpers.combineCellArrays(f.WNames,di.WNames,f.Wdim,true);
                end
                %}
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
            %{
            newData = DataSet('','','',data.X(inds,:),data.Y(inds),...
                data.type(inds,:),data.trueY(inds),data.instanceIDs(inds));
            %}
            newData = data.copy();
            newData.keep(inds);         
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

