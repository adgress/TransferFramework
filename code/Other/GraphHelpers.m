classdef GraphHelpers
    %GRAPHHELPERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function [score,percCorrect,Ypred,Yactual,labeledTargetScores,savedData] ...
                = LOOCV(W,labeledInds,Y,useHF,type,savedData)
            if nargin < 4
                useHF = false;
            end
            addpath(genpath('libraryCode'));  
            numClasses = max(Y);
            if useHF
                WdistMat = DistanceMatrix(W,Y,type);                
                [W,Y,type] = WdistMat.prepareForHF_LOOCV() ; 
                isLabeled = Y > 0;
                assert(issorted(~isLabeled));                
                lastLabeledInd = max(find(isLabeled));
                isLabeledTrain = isLabeled & type == Constants.TARGET_TRAIN;
                lastLabeledTargetInd = max(find(isLabeledTrain));
                Yscore = zeros(lastLabeledTargetInd,1);
                Ypred = Yscore;
                Yactual = Y(1:lastLabeledTargetInd);  
                labeledTargetScores = zeros(lastLabeledTargetInd,numClasses);
                for i=1:lastLabeledTargetInd
                    Ycurr = Y(Y > 0);
                    Ycurr(i) = Ycurr(end);
                    Ycurr(end) = [];
                    YLabelMatrix = Helpers.createLabelMatrix(Ycurr);
                    W = Kernel.swapElements(W,i,lastLabeledInd);
                    [fu, ~] = harmonic_function(W, YLabelMatrix);
                    fu_1 = fu(1,:);
                    [~,Ypred(i)] = max(fu_1);                    
                    Yscore(i) = fu_1(Yactual(i));
                    labeledTargetScores(i,:) = fu_1;
                    W = Kernel.swapElements(W,lastLabeledInd,i);
                end                
            else
                isLabeledTarget = Y > 0 & type == Constants.TARGET_TRAIN;
                labeledTargetInds = find(isLabeledTarget);
                Yscore = zeros(size(labeledTargetInds));
                Ypred = Yscore;
                Yactual = Y(labeledTargetInds);
                Ymat = full(Helpers.createLabelMatrix(Y));
                labeledTargetScores = zeros(length(labeledTargetInds),numClasses);
                if exist('savedData','var') && isfield(savedData,'invM');
                    invM = savedData.invM;
                end
                for i=1:length(labeledTargetInds)
                    ind = labeledTargetInds(i);                    
                    yi = Ymat(ind,:);
                    Ymat(ind,:) = 0;
                    warning off;
                    if ~exist('invM','var')
                        [fu,invM] = llgc(W,Ymat);
                    else
                        [fu,~] = llgc(W,Ymat,invM);
                    end
                    warning on;
                    Yactual_i = Yactual(i);
                    Yscore(i) = fu(ind,Yactual_i);
                    [~,Ypred(i)] = max(fu(ind,:));
                    Ymat(ind,:) = yi;
                    labeledTargetScores(i,:) = fu(ind,:);
                end
                if exist('savedData','var')
                    savedData.invM = invM;
                end
            end
                     
            Yscore(isnan(Yscore)) = 0;
            n = length(Yactual);
            score = sum(Yscore)/n;
            percCorrect = sum(Ypred == Yactual)/n;
        end
        function [sigma,bestScore,bestAcc] = autoSelectSigma(W,Y,isTrain,useMeanSigma,useHF,type)
            meanDistance = mean(W(:));
            
            if nargin < 6
                useHF = false;
            end
            expVals = -3:3;
            if useMeanSigma
                expVals = 0;
            end
            sigmas = zeros(length(expVals),1);            
            base = 5;
            for i=1:length(expVals)
                sigmas(i) = meanDistance*base^expVals(i);
            end

            scores = zeros(size(sigmas));
            percCorrect = scores;
            labeledInds = find(Y > 0 & isTrain);
            for i=1:length(sigmas)
                S = Helpers.distance2RBF(W,sigmas(i));
                [scores(i),percCorrect(i),~,~] = GraphHelpers.LOOCV(S,labeledInds,Y,useHF,type);
            end
            [~,bestInd] = max(scores);
            sigma = sigmas(bestInd);
            bestScore = scores(bestInd);
            bestAcc = percCorrect(bestInd);
            
            %scores'
            %percCorrect'
        end        
    end
    
end

