classdef DistanceMatrix < double
    %DISTANCEMATRIX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        TYPE_TARGET_TRAIN = 1
        TYPE_TARGET_TEST = 2
        TYPE_SOURCE = 3
    end
    properties
        Y
        type
    end
    
    methods
        function [obj] = DistanceMatrix(W,Y,type)
            obj = obj@double(W);
            obj.Y = Y;
            obj.type = type;
            assert(numel(obj.type) == numel(obj.Y));
            assert(numel(obj.type) == size(W,1));
        end
        
        function [W] = getRBFKernel(obj,sigma)
            W = exp(-2*double(obj)./(sigma^2));
            W = DistanceMatrix(W,obj.Y,obj.type);
        end
        
        function [W,labels] = getTestToLabeled(obj)
            W = double(obj);
            W = W(obj.type == obj.TYPE_TARGET_TEST,obj.Y > 0);
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
            W = double(obj);
            W = W(indices,obj.Y > 0);
            labels = obj.Y(obj.Y > 0);
        end
        
        function [W,Yt,Y] = getLabeledTrainToSource(obj)
            W = double(obj);
            It = obj.type == obj.TYPE_TARGET_TRAIN & obj.Y > 0;
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
        
        function [W,YTrainLabeled,YTest,isTest] = prepareForHF(obj)
            W = double(obj);
            isTest = obj.type == DistanceMatrix.TYPE_TARGET_TEST;
            labeledTrain = (obj.type  == DistanceMatrix.TYPE_TARGET_TRAIN | ...
                obj.type == DistanceMatrix.TYPE_SOURCE) & obj.Y > 0;
            perm = [find(labeledTrain) ; find(~labeledTrain)];
            isTest = isTest(perm);
            W = W(perm,perm);
            YTrainLabeled = obj.Y(labeledTrain);
            YTest = obj.Y(isTest);
        end
        
        function [W,Ys,Yt] = prepareForSourceHF(obj)
            W = double(obj);            
            sourceInds = find(obj.type == DistanceMatrix.TYPE_SOURCE);
            targetInds = find(obj.type ~= DistanceMatrix.TYPE_SOURCE);
            allInds = [sourceInds; targetInds];
            Ys = obj.Y(sourceInds);
            Yt = obj.Y(targetInds);
            W = W(allInds,allInds);
        end
        
        function [I] = isTarget(obj)
            I = obj.type == DistanceMatrix.TYPE_TARGET_TRAIN | ...
                obj.type == DistanceMatrix.TYPE_TARGET_TEST;
        end
        
        function [I] = isLabeledTarget(obj)
            I = obj.isTarget() & obj.isLabeled();
        end
        
        function [I] = isUnlabeledTarget(obj)
            I = obj.isTarget() & ~obj.isLabeled();
        end
        
        function [I] = isSource(obj)
            I = obj.type == DistanceMatrix.TYPE_SOURCE;
        end
        
        function [I] = isLabeledSource(obj)
            I = obj.isSource() & obj.isLabeled();
        end
        
        function [I] = isLabeled(obj)
            I = obj.Y > 0;
        end
        
    end
    
end

