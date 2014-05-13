classdef GraphHelpers
    %GRAPHHELPERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function [score,percCorrect,Ypred,Yactual,labeledTargetScores] ...
                = LOOCV(W,labeledInds,Y,useHF,type)
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
                for i=1:length(labeledTargetInds)
                    ind = labeledTargetInds(i);                    
                    yi = Ymat(ind,:);
                    Ymat(ind,:) = 0;
                    if i==1
                        [fu,invM] = llgc(W,Ymat);
                    else
                        [fu,~] = llgc(W,Ymat,invM);
                    end
                    Yactual_i = Yactual(i);
                    Yscore(i) = fu(ind,Yactual_i);
                    [~,Ypred(i)] = max(fu(ind,:));
                    Ymat(ind,:) = yi;
                    labeledTargetScores(i,:) = fu(ind,:);
                end
            end
                     
            Yscore(isnan(Yscore)) = 0;
            n = length(Yactual);
            score = sum(Yscore)/n;
            percCorrect = sum(Ypred == Yactual)/n;
        end
        function [sigma,bestScore,bestAcc] = autoSelectSigma(W,Y,isTrain,useCV,useHF,type)           
            meanDistance = mean(W(:))^2;
            
            if nargin < 6
                useHF = false;
            end
            expVals = -3:3;
            sigmas = zeros(length(expVals),1);            
            base = 5;
            for i=1:length(expVals)
                sigmas(i) = meanDistance*base^expVals(i);
            end
            %maxLabel = max(Y);
            %counts = histc(Ytrain(Ytrain > 0),1:maxLabel);
            %hasEnoughLabeledTrain = sum(counts < 2) == 0;
            hasEnoughLabeledTrain = 1;
            useLOOCV = 1;
            if useLOOCV && hasEnoughLabeledTrain
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
            elseif useCV && length(Ytrain) > 0 && hasEnoughLabeledTrain
                error('Has this been updated?');
                percentageArray = [.8 .2 0];
                [split] = DataSet.generateSplitForLabels(percentageArray,Ytrain);
                trainInds = split == 1;
                cvInds = split == 2;            
                YtestTrain = Ytrain(trainInds);
                YtestTest = Ytrain(cvInds);
                if ~useHF
                    YtestTest = [YtestTest ; -1*ones(size(find(~isTrain)))];
                end
                newPerm = [find(trainInds) ; find(cvInds)];
                newPerm = [newPerm ; find(~isTrain)];
                Wperm = W(newPerm,newPerm);            
                sigma = GraphHelpers.selectBestSigma(Wperm,YtestTrain,YtestTest,sigmas,useHF);
            else
                error('Update');
                display('autoSelectSigma: Not enough YTrain, default sigma selected');
                sigma = meanDistance;
            end
            %scores'
            %percCorrect'
        end
        function [sigma] = selectBestSigma(W,Ytrain,Ytest,sigmas,useHF)
            scores = zeros(1,length(sigmas));
            percCorrect = scores;            
            if useHF
                YtrainMat = Helpers.createLabelMatrix(Ytrain); 
            else
                Yactual = [Ytrain ; Ytest];
                isTrain = ...
                    logical([ones(size(Ytrain)) ; zeros(size(Ytest))]);
                labeledTest = Yactual > 0 & ~isTrain;                
                Y = [Ytrain ; -1*ones(size(Ytest))];
                YtrainMat = Helpers.createLabelMatrix(Y);
            end
            for i=1:length(sigmas)                
                s = sigmas(i);
                K = Helpers.distance2RBF(W,s);  
                if useHF                    
                    warning off;                
                    [fu, fu_CMN] = harmonic_function(K, YtrainMat);
                    warning on;
                    fuCV = fu(1:length(Ytest),:);
                    fuCMNCV = fu_CMN(1:length(Ytest),:);
                    fu_test = fuCMNCV;
                    [percCorrect(i),scores(i)] = Helpers.getAccuracy(fu_test,...
                        Ytest);
                else                                            
                    warning off;
                    [fu] = llgc(K, YtrainMat);
                    warning on;
                    [percCorrect(i),scores(i)] = Helpers.getAccuracy(...
                        fu(labeledTest,:),Yactual(labeledTest));
                end                
            end
            [bestAcc,bestAccInd] = max(percCorrect);
            [bestScore,bestScoreInd] = max(scores);
            %[bestAcc bestScore]
            %assert(bestAccInd == bestScoreInd);
            %percCorrect
            %scores
            sigma = sigmas(bestAccInd);
        end
        function [] = asdf()
            
        end
    end
    
end

