classdef LabeledData < matlab.mixin.Copyable
    %LABELEDDATA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Y
        type
        name
        trueY
        instanceIDs
        isValidation
        
        %Map of Data Set IDs to original label data
        ID2Labels
        
        %For multilabel data
        labelSets
        
        objectType
        YNames
    end
    
    properties(Dependent)
        numClasses
        classes
        isNoisy
        numPerClass
        percLabeledNoisy
        numLabels
        isMultilabel
        isLabeled
    end
    
    methods
        function [obj] = LabeledData()
            obj.Y = [];
            obj.type = [];
            obj.isValidation = [];
            obj.name = '';
            obj.objectType = [];
            obj.YNames = [];
            obj.labelSets = [];
        end
        function [] = removeLabels(obj,shouldRemove)
            if ~islogical(shouldRemove)
                I = false(size(obj.Y,2),1);
                I(shouldRemove) = true;
                shouldRemove = I;
            end
            obj.keepLabels(~shouldRemove);
        end
        function [] = keepLabels(obj,shouldKeep)
            obj.Y = obj.Y(:,shouldKeep);
            obj.trueY = obj.trueY(:,shouldKeep);
            if size(obj.Y,2) == 0
                warning('All labels removed!');
            end
        end
        function [] = clearLabels(obj, shouldClearLabels)
            obj.Y(shouldClearLabels,:) = -1;
        end
        
        function [] = swapSourceAndTarget(obj)
            targetInds = obj.isTarget();
            obj.type(targetInds) = Constants.SOURCE;
            obj.type(~targetInds) = Constants.TARGET_TRAIN;
        end
        function [I] = isLabeledTargetTrain(obj)
            I = obj.isTargetTrain() & obj.isLabeled();
        end
        function [I] = isTarget(obj)
            I = obj.type == Constants.TARGET_TRAIN | ...
                obj.type == Constants.TARGET_TEST;
        end
        function [I] = isTargetTrain(obj)
            I = obj.type == Constants.TARGET_TRAIN;
        end
        function [I] = isTargetTest(obj)
            I = obj.type == Constants.TARGET_TEST;
        end        
        function [I] = isLabeledTarget(obj)
            I = obj.isTarget() & obj.isLabeled();
        end
        
        function [I] = isUnlabeledTarget(obj)
            I = obj.isTarget() & ~obj.isLabeled();
        end
        
        function [I] = isSource(obj)
            I = obj.type == Constants.SOURCE;
        end
        
        function [I] = isLabeledSource(obj)
            I = obj.isSource() & obj.isLabeled();
        end
        
        function [I] = get.isLabeled(obj,yIdx)
            if ~exist('yIdx','var')
                yIdx = 1;
            end
            I = obj.Y(:,yIdx) > 0;
        end
        
        function [b] = get.isMultilabel(obj)
            b = size(obj.Y,2) > 1;
        end
        
        function [n] = get.numClasses(obj)
            n = length(obj.classes());
        end
        
        function [v] = get.classes(obj,yIdx)
            if ~exist('yIdx','var')
                yIdx = 1;
            end
            v = unique(obj.Y(obj.isLabeled(),yIdx));
        end
        
        function [v] = get.isNoisy(obj)
            v = obj.Y ~= obj.trueY & obj.isLabeled();
        end
        
        function [v] = get.numPerClass(obj)
            v = [];
            for i=obj.classes(:)'
                v(i) = length(find(obj.Y == i));
            end
            v = v';
        end
        
        function [v] = get.percLabeledNoisy(obj)
            v = mean(obj.isNoisy(obj.isLabeled()));
        end
        
        function [v] = get.numLabels(obj)
            v = 1;
            if ~isempty(obj.labelSets)
                v = length(unique(obj.labelSets));
            end
        end
        
        function [n] = size(obj)
            n = size(obj.Y,1);
        end
        
        function [n] = numSource(obj)
            n = sum(obj.type == Constants.SOURCE);
        end
        function [n] = numLabeledSource(obj)
            n = sum(obj.Y > 0 & ...
                obj.type == Constants.SOURCE);
        end
        
        function [Yu] = getBlankLabelVector(obj)
            Yu = obj.Y;
            Yu(:) = -1;
        end
        function [b] = hasTypes(obj)
            b = length(obj.Y) == length(obj.type) && ...
                isempty(find(obj.type == Constants.NO_TYPE));
        end
        function [b] = isSourceDataSet(obj)
            b = sum(obj.type == Constants.SOURCE) == length(obj.Y);            
        end
        function [b] = isTargetDataSet(obj)
            b = sum(obj.type == Constants.TARGET_TRAIN | ...
                obj.type == Constants.TARGET_TEST) == length(obj.Y);            
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
            obj.Y(obj.type == Constants.TARGET_TEST,:) = -1;
        end 
        function [inds] = isClass(obj,class)
            inds = false(length(obj.Y),1);
            for i=class
                inds = inds | obj.Y == i;
            end
        end
        function [] = labelData(obj,inds)
            obj.Y(inds,:) = obj.trueY(inds,:);
        end
        function [] = addRandomClassNoise(obj,classNoise,inds)
            if ~exist('inds','var')
                inds = ones(size(obj.Y));
            end
            assert(size(obj.Y,2) == 1);
            originalY = obj.Y;
            allClasses = obj.classes;
            for currClass=allClasses'
                isClass = find((originalY == currClass) & inds);
                permIsClass = isClass(randperm(length(isClass)));
                remainingClasses = allClasses(allClasses ~= currClass);               
                newLabelVector = randsample(remainingClasses,length(permIsClass),true);
                
                %If first argument to randsample is scalar, then it samples
                %from 1 to the scalar
                if length(remainingClasses) == 1
                    newLabelVector(:) = remainingClasses;
                end
                numToUse = floor(classNoise*length(isClass));
                obj.Y(permIsClass(1:numToUse)) = newLabelVector(1:numToUse);
            end
        end
        
        function [] = addRandomClassNoiseToTrain(obj,classNoise)
            obj.addRandomClassNoise(classNoise,obj.isTargetTrain());
        end
        
        function [split] = generateSplitArray(obj,percTrain,percTest,configs,dim)
            if ~exist('dim','var')
                dim = 1;
            end
            percValidate = 1 - percTrain - percTest;
            if ~exist('configs','var')
                split = DataSet.generateSplit([percTrain percTest percValidate],...
                    obj.Y,dim);            
            else
                IDs = 1:length(obj.Y);
                if isempty(obj.X) && ~isempty(obj.WIDs)
                    IDs = obj.WIDs{dim};
                end
                split = DataSet.generateSplit([percTrain percTest percValidate],...
                    obj.Y,configs,dim,IDs);            
            end
        end
    end

    methods(Static)  
        function [split] = generateSplit(percentageArray,Y,configs,dim,IDs)
            if ~exist('IDs','var')
                IDs = 1:length(Y);
            end
            if ~exist('dim','var')
                dim = 1;
            end
            maxTrainNumPerLabel = inf;
            if exist('configs','var') && isKey(configs,'maxTrainNumPerLabel')
                maxTrainNumPerLabel = configs.get('maxTrainNumPerLabel');
            end
            assert(sum(percentageArray) == 1,'Split doesn''t sum to one');
            percentageArray = cumsum(percentageArray);
            dataSize = size(Y,1);
            split = zeros(dataSize,1);
            uniqueY = unique(Y(Y > 0));
            isMultilabel = size(Y,2) > 1;
            if isMultilabel
                uniqueY = 1;
            end
            for i=1:length(uniqueY)
                thisClass = find(Y == uniqueY(i));   
                if isMultilabel
                    thisClass = 1:dataSize;
                end
                numThisClass = numel(thisClass);
                assert(numThisClass >= length(unique(percentageArray)));
                perm = randperm(numThisClass);
                thisClassRandomized = thisClass(perm);
                numToPick = ceil(numThisClass*percentageArray);
                %diff = max(numToPick(1)-maxTrainNumPerLabel,0);
                numToPick(1) = min(numToPick(1),maxTrainNumPerLabel);
                %numToPick = numToPick-diff;                
                if numToPick(2) == numToPick(1)
                    numToPick(1) = numToPick(1) - 1;
                end
                assert(numToPick(2)-numToPick(1) > 0);
                numEach = [0 numToPick];
                for j=1:numel(percentageArray)       
                    if numEach(j) == numEach(j+1)
                        %display('TODO: Potential off by one error');
                        continue;
                    end
                    indices = thisClassRandomized(numEach(j)+1:numEach(j+1));
                    split(indices) = j;  
                    if j < 3
                        assert(length(indices) > 0);
                    end
                end
                assert(sum(split(thisClassRandomized) == 1) == numToPick(1));
            end
            isLabeled = sum(Y > 0,2) > 0;
            splitIsLabeled = split(isLabeled > 0);
            assert(sum(splitIsLabeled==0) == 0);
        end
        
        function [I] = ResampleTargetTrainData(type)
            %assert(length(type) == length(Y));
            isTarget = type == Constants.TARGET_TRAIN;
            isSource = type == Constants.SOURCE;
            numTarget = sum(isTarget);
            numSource = sum(isSource);
            if numTarget >= numSource
                I = 1:length(type);
                return
            end
            I = zeros(numSource,1);
            targetInds = find(isTarget);
            for i=1:numSource
                I(i) = targetInds(mod(i-1,numTarget)+1);
            end
            I = [I ; find(isSource)];
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
end

