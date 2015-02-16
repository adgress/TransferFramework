classdef VarianceMinimizationActiveMethod < ActiveMethod
    %VARIANCEMINIMIZATIONACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = VarianceMinimizationActiveMethod(configs)            
            obj = obj@ActiveMethod(configs);
        end
        function [queriedIdx] = queryLabel(obj,input,results,s)               
            unlabeledInds = find(input.train.Y < 0);            
            labeledInds = find(input.train.Y > 0);
            W = Helpers.CreateDistanceMatrix(input.train.X);
            distMat = DistanceMatrix(W,input.train.Y,input.train.type,...
                input.train.trueY,input.train.instanceIDs);
            [Wrbf,YtrainMat,sigma,Y_testCleared,instanceIDs] = ...
                input.learner.makeLLGCMatrices(distMat);
            L = LLGC.make_L_unnormalized(Wrbf);
            %Luu = L(unlabeledInds,unlabeledInds);
            %Iu = eye(size(Luu));
            In = eye(size(L));
            
            [X,D] = eig(L);
            D = diag(D);
            [D,sortedInds] = sort(D,'descend');
            X = X(:,sortedInds);            
                        
            M = diag(D) + In;
            M_inv = inv(M);
            A0 = M_inv - In;
            
            %Q = SX
            Al = A0;
            for labeledInd=labeledInds'
                %Note: We use rows of X even though columns are
                %eigenvectors
                pi = X(labeledInd,:);
                Al = Al + pi*pi';
            end
            Al_inv = inv(Al);
            T = Al_inv*M_inv*Al_inv;
            v = [];
            for unlabeledInd=unlabeledInds'
                p = X(unlabeledInd,:)';
                v(end+1) = (p'*T*p)/(1+p'*Al_inv*p);
            end
            [~,minInd] = min(v);
            queriedIdx = unlabeledInds(minInd);
        end   
        function [prefix] = getPrefix(obj)
            prefix = 'VM';
        end
    end
    
end

