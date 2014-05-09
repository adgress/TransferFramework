classdef DistanceMatrix < handle
    %DISTANCEMATRIX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
    end
    properties
        Y
        type
        W
    end
    
    methods
        function [obj] = DistanceMatrix(W,Y,type)
            if nargin < 3
                type = ones(size(Y))*Constants.TARGET_TRAIN;
            end
            obj.W = W;
            obj.Y = Y;
            obj.type = type;
            assert(numel(obj.type) == numel(obj.Y));
            assert(numel(obj.type) == size(W,1));
        end
        
        function [W] = getRBFKernel(obj,sigma)
            W = exp(-2*obj.W./(sigma));
            W = DistanceMatrix(W,obj.Y,obj.type);
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
        
        function [W,YTrainLabeled,YTest,isTest,type] = prepareForHF(obj)
            W = obj.W;
            isTest = obj.type == Constants.TARGET_TEST;
            labeledTrain = (obj.type  == Constants.TARGET_TRAIN | ...
                obj.type == Constants.SOURCE) & obj.Y > 0;
            perm = [find(labeledTrain) ; find(~labeledTrain)];
            isTest = isTest(perm);
            W = W(perm,perm);
            YTrainLabeled = obj.Y(labeledTrain);
            YTest = obj.Y(isTest);
            type = obj.type(perm);
        end
        
        function [] = shiftLabeledDataToFront(obj)
            isLabeled = obj.Y > 0;
            newPerm = [find(isLabeled); find(~isLabeled)];            
            obj.permuteData(newPerm);
        end
        function [] = shiftLabeledTargetDataToFront(obj)
            isLabeledTarget = obj.Y > 0 & obj.type ~= Constants.SOURCE;
            newPerm = [find(isLabeledTarget) ; find(~isLabeledTarget)];
            obj.permuteData(newPerm);
            
        end
        function [] = permuteData(obj,newPerm)
            if issorted(newPerm)
                return;
            end
            obj.W = obj.W(newPerm,newPerm);
            obj.type = obj.type(newPerm);
            obj.Y = obj.Y(newPerm);
        end
        
        function [W,Y,isTarget] = prepareForHF_LOOCV(obj)
            obj.shiftLabeledDataToFront();
            obj.shiftLabeledTargetDataToFront();
            W = obj.W;
            Y = obj.Y;
            isTarget = obj.type ~= Constants.SOURCE;
        end
        
        function [W,Ys,Yt,type,isTarget] = prepareForSourceHF(obj)
            W = obj.W;
            sourceInds = find(obj.type == Constants.SOURCE);
            targetInds = find(obj.type ~= Constants.SOURCE);
            allInds = [sourceInds; targetInds];
            Ys = obj.Y(sourceInds);
            Yt = obj.Y(targetInds);
            W = W(allInds,allInds);
            type = obj.type(allInds);
            isTarget = type == Constants.TARGET_TEST | ...
                    type == Constants.TARGET_TRAIN;
        end
        
        function [I] = isTarget(obj)
            I = obj.type == Constants.TARGET_TRAIN | ...
                obj.type == Constants.TARGET_TEST;
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
        
        function [I] = isLabeled(obj)
            I = obj.Y > 0;
        end
        
    end
    
end

