classdef DistanceMatrix < LabeledData
    %DISTANCEMATRIX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
    end
    
    properties(Dependent)
        meanDistance
    end
    
    properties
        W
        WNames
        WIDs
    end
    
    methods
        function [obj] = DistanceMatrix(W,Y,type,trueY,instanceIDs)
            if nargin < 3
                type = ones(size(Y))*Constants.TARGET_TRAIN;
            end
            obj.W = W;
            obj.Y = Y;
            obj.type = type;
            obj.trueY = trueY;
            obj.instanceIDs = instanceIDs;
            assert(numel(obj.type) == numel(obj.Y));
            assert(numel(obj.type) == size(W,1));
            assert(numel(obj.trueY) == size(W,1));
            assert(numel(obj.instanceIDs) == size(W,1));
        end
        
        function [W] = getRBFKernel(obj,sigma)
            W = exp(-2*obj.W./(sigma));
            W = DistanceMatrix(W,obj.Y,obj.type,obj.trueY,obj.instanceIDs);
        end
        
        function [W,labels] = getTestToLabeled(obj)
            W = double(obj);
            W = W(obj.type == Constants.TARGET_TEST,obj.Y > 0);
            labels = obj.Y(obj.Y > 0);
        end
        
        function [W,labels] = getTrainToLabeled(obj,justLabeled)
            if nargin < 2
                justLabeled = false;
            end
            indices = obj.type == obj.TYPE_TARGET_TRAIN;
            if justLabeled
                indices = indices & obj.Y > 0;
            end
            W = obj.W;
            W = W(indices,obj.Y > 0);
            labels = obj.Y(obj.Y > 0);
        end
        
        function [W,Yt,Y] = getLabeledTrainToSource(obj)
            W = obj.W;
            It = obj.type == Constants.TARGET_TRAIN & obj.Y > 0;
            I = obj.Y > 0;
            W = W(It,I);
            Yt = obj.Y(It);
            Y = obj.Y(I);
        end
        
        function [Yactual, Ynn] = getLabeledTrainToSourceNN(obj,k)
            if nargin < 2
                k = 1;
            end
            [W, Yactual, Y] = obj.getLabeledTrainToSource();
            [sorted,I] = sort(W,2,'ascend');
            I = I(:,2:k+1);
            Ynn = Y(I);
        end
        
        function [nn] = getTrainToLabeledNN(obj,justLabeled,k)
            if nargin < 2
                justLabeled = false;
            end
            if nargin < 3
                k = 1;
            end
            [W,labels] = obj.getTrainToLabeled(justLabeled);
            [sorted,I] = sort(W,2,'ascend');
            I = I(:,2:k+1);
            nn = labels(I);
        end
        
        function [nn] = getTestToLabeledNN(obj,k)
            if nargin < 2
                k = 1;
            end
            [W,labels] = obj.getTestToLabeled();
            [sorted,I] = sort(W,2,'ascend');
            %I = I(:,2:k+1);
            I = I(:,1:k);
            nn = labels(I);
        end
        
        function [W,Y,isTest,type,perm] = prepareForHF(obj)
            %error('Update!');
            W = obj.W;
            isTest = obj.type == Constants.TARGET_TEST;
            labeledTrain = (obj.type  == Constants.TARGET_TRAIN | ...
                obj.type == Constants.SOURCE) & obj.Y > 0;
            perm = [find(labeledTrain) ; find(~labeledTrain)];
            isTest = isTest(perm);
            W = W(perm,perm);
            Y = obj.Y(perm);
            type = obj.type(perm);
        end
        
        function [] = shiftLabeledDataToFront(obj)
            error('Update!');
            isLabeled = obj.Y > 0;
            newPerm = [find(isLabeled); find(~isLabeled)];            
            obj.permuteData(newPerm);
        end
        function [] = shiftLabeledTargetDataToFront(obj)
            error('Update!');
            isLabeledTarget = obj.Y > 0 & obj.type ~= Constants.SOURCE;
            newPerm = [find(isLabeledTarget) ; find(~isLabeledTarget)];
            obj.permuteData(newPerm);
            
        end
        function [] = permuteData(obj,newPerm)
            error('Update!');
            if issorted(newPerm)
                return;
            end
            obj.W = obj.W(newPerm,newPerm);
            obj.type = obj.type(newPerm);
            obj.Y = obj.Y(newPerm);
        end
        
        function [W,Y,type] = prepareForHF_LOOCV(obj)
            error('Update!');
            obj.shiftLabeledDataToFront();
            obj.shiftLabeledTargetDataToFront();
            W = obj.W;
            Y = obj.Y;
            type = obj.type;
        end
        
        %function [W,Ys,Yt,type,isTarget] = prepareForSourceHF(obj)
        function [] = prepareForSourceHF(obj)
            error('Update!');
            sourceInds = find(obj.isSource());
            targetInds = find(obj.isTarget());
            allInds = [sourceInds; targetInds];
            Ys = obj.Y(sourceInds);
            Yt = obj.Y(targetInds);
            obj.W = obj.W(allInds,allInds);
            obj.type = obj.type(allInds);
            obj.Y = [Ys ; Yt];
        end
        
        function[] = removeInstances(obj, shouldRemove)
            obj.Y = obj.Y(~shouldRemove);
            obj.W = obj.W(~shouldRemove,~shouldRemove);
            obj.type = obj.type(~shouldRemove);
            obj.trueY = obj.trueY(~shouldRemove);
            obj.instanceIDs = obj.instanceIDs(~shouldRemove);
        end
        
        function [n] = get.meanDistance(obj)
            %{
            isTarget = obj.isTarget();
            targetDists = obj.W(isTarget,isTarget);
            n = mean(targetDists(:));
            %}
            n = mean(obj.W(:));
        end
    end
    
end

