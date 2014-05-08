classdef HFTransferMeasure < TransferMeasure
    %SCTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = HFTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [val,metadata] = computeMeasure(obj,source,target,...
                options)            
            metadata = {};                        
            
            targetWithLabels = target.Y > 0;
            if sum(targetWithLabels) == 0 || ...
                sum(targetWithLabels) <= max(target.Y)
                val = nan;
                return;
            end
            if nargin >= 4 && isfield(options,'distanceMatrix')
                W = options.distanceMatrix;                
            else                
                Xall = [source.X ; target.X];                                
                Y = [source.Y ; target.Y];
                type = [ones(numel(source.Y),1)*DistanceMatrix.TYPE_SOURCE ;...
                    ones(numel(target.Y),1)*DistanceMatrix.TYPE_TARGET_TRAIN];
                W = Kernel.Distance(Xall);
                W = DistanceMatrix(W,Y,type);
            end            
            [W,Ys,Yt,isTarget] = W.prepareForSourceHF();
            useCV = 1;
            useHF = 1;                        
            if ~obj.configs('useSourceForTransfer')
                W = W(isTarget,isTarget);
                type = type(isTarget);
                Ys = zeros(0,size(Ys,2));
                isTarget = isTarget(isTarget);            
            end
            error('Is type set properly?');
            sigma = Helpers.autoSelectSigma(W,[Ys;Yt],isTarget,useCV,useHF,type);
            W = Helpers.distance2RBF(W,sigma);
            labedTargetInds = find(Yt > 0);
            addpath(genpath('libraryCode'));
            useTraining = 1;                              
            
            if useTraining
                display('TODO: Refactor HFTransferMeasure LOOCV');
                numCorrect = 0;
                Ypred = zeros(length(labedTargetInds),1);
                score = 0;
                for i=1:numel(labedTargetInds)
                    isLabeledTargetToUse = true(size(Yt));
                    isLabeledTargetToUse(Yt < 0) = false;
                    isLabeledTargetToUse(labedTargetInds(i)) = false;
                    iInd = labedTargetInds(i) + length(Ys);                              
                    indsLabeled = [ones(size(Ys)); isLabeledTargetToUse];
                    indsUnlabeled = ~indsLabeled;
                    indsUnlabeled(iInd) = 0;
                    newPerm = [find(indsLabeled); iInd; find(indsUnlabeled)];
                    Wl = W(newPerm,newPerm);
                    
                    Yl = [Ys ; Yt(isLabeledTargetToUse)];
                    YlLabelMatrix = Helpers.createLabelMatrix(Yl);
                    [fu, fu_CMN] = harmonic_function(Wl, YlLabelMatrix);                
                    [~,predicted] = max(fu,[],2);
                    [~,predictedCMN] = max(fu_CMN,[],2);
                    
                    if obj.configs('useCMN')
                        Ypred(i) = predictedCMN(1);
                    else
                        Ypred(i) = predicted(1);
                    end
                    Yact = Yt(labedTargetInds(i));                    
                    numCorrect = numCorrect + (Ypred(i) == Yact);
                    score = score + fu_CMN(i,Yact);
                end   
                score = score/length(labedTargetInds);
                percCorrect = numCorrect/length(labedTargetInds);
            else
                %display('HFTransferMeasure: Not using labeled target for measure');
                YsLabelMatrix = Helpers.createLabelMatrix(Ys);
                
                [fu, fu_CMN] = harmonic_function(W, YsLabelMatrix);
                [~,predicted] = max(fu,[],2);
                [~,predictedCMN] = max(fu_CMN,[],2);
                fu2 = fu(labedTargetInds,:);
                fu_CMN2 = fu_CMN(labedTargetInds,:);
                classPriors = histc(Ys,1:10)./length(Ys);
                
                Ypred = predicted(labedTargetInds);
                Yact = Yt(labedTargetInds);
                YactLabelMatrix = Helpers.createLabelMatrix(Yact);
                Yvals = fu_CMN2.*YactLabelMatrix;
                numCorrect = sum(Ypred == Yact);
                percCorrect = numCorrect/length(labedTargetInds);
                score = sum(Yvals(:))
                score = score/length(labedTargetInds);                
            end
            if obj.configs('useSoftLoss')
                val = score;
            else
                val = percCorrect;
            end
            obj.displayMeasure(val);
        end
                     
        function [ri] = calculateRandIndex(obj,C,Y,isTarget)
            numClasses = max(Y);
            numClusters = size(C,2);
            numCorrect = zeros(numClasses,1);
            numIncorrect = numCorrect;
            for i=1:numClasses
                for j=1:numClusters
                    clj = C(:,j);
                    targetiJ = clj & Y == i & isTarget;                    
                    if sum(targetiJ) == 0
                        continue;
                    end
                    sourceiJ = clj & Y == i;
                    sourceiOther = clj & Y ~= i;
                    nc = sum(targetiJ)*sum(sourceiJ);
                    nic = sum(targetiJ)*sum(sourceiOther);
                    numCorrect(i) = numCorrect(i) + nc;                    
                    numIncorrect(i) = numIncorrect(i) + nic;
                    %{
                    for k = 1:numClusters
                        if j==k
                            continue;
                        end
                        clk = C(:,k);
                        sourcekJ = clk & Y == i;
                        sourcekOther = clk & Y ~= i;
                        nc = sum(targetiJ)*sum(sourcekOther);
                        nic = sum(targetiJ)*sum(sourcekJ);
                        numCorrect(i) = numCorrect(i) + nc;
                        numIncorrect(i) = numIncorrect(i) + nic;
                    end
                    %}
                end
            end
            accs = numCorrect./(numCorrect+numIncorrect);
            ri = mean(accs);
        end
        function [purity] = calculateClusterPurity(obj,C,Y,isTarget)
            sourceWithLabel = ~isTarget & Y > 0;
            targetWithLabel = isTarget & Y > 0;
            
            [purity,clusterLabels,clusterPurities] = ...
                 SCTransferMeasure.CalculateClusterPurity(C,Y);
        end
                
        
        function [name] = getPrefix(obj)
            name = 'HF';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'useCMN','useSoftLoss'};
        end
    end
    
    methods(Static)
        function [purity,clusterLabels,clusterPurities] =...
                CalculateClusterPurity(C,Y)
            clusterLabels = zeros(size(C,2),1);
            clusterPurities = clusterLabels;
            withLabel = Y > 0;
            for i=1:numel(clusterLabels)
                ci = C(:,i);          
                ci_withLabel = ci & withLabel;
                clusterLabels(i) = mode(Y(ci_withLabel));
                clusterPurities(i) = sum(Y(ci_withLabel) ~= clusterLabels(i))/...
                    sum(ci_withLabel);
            end
            clusterPurities(isnan(clusterPurities)) = -1;
            purity = mean(clusterPurities(clusterPurities >= 0));
        end 
    end
    
end

