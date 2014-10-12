classdef GraphHelpers
    %GRAPHHELPERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        
        function [fu] = RunHarmonicFunction(W, Y)
            YLabelMatrix = Helpers.createLabelMatrix(Y);                   
            [fu, ~] = harmonic_function(W, YLabelMatrix);
        end
        
        function [fu,invM] = RunLLGC(W,Y,invM)
            Ymat = full(Helpers.createLabelMatrix(Y));            
            if exist('invM','var')
                [fu,invM] = llgc(W,Ymat,invM);
            else
                [fu,invM] = llgc(W,Ymat);
            end
        end
        
        function [score,percCorrect,Ypred,Yactual,labeledTargetScores,savedData] ...
                = LOOCV(distMat,useHF,savedData)
            if nargin < 2
                useHF = false;
            end             
            if useHF          
                [W,Y,type] = distMat.prepareForHF_LOOCV() ; 
                isLabeled = Y > 0;
                assert(issorted(~isLabeled));                
                lastLabeledInd = max(find(isLabeled));
                isLabeledTrain = isLabeled & type == Constants.TARGET_TRAIN;
                lastLabeledTargetInd = max(find(isLabeledTrain));
                Yscore = zeros(lastLabeledTargetInd,1);
                Ypred = Yscore;
                Yactual = Y(1:lastLabeledTargetInd);  
                labeledTargetScores = zeros(lastLabeledTargetInd,distMat.numClasses);
                for i=1:lastLabeledTargetInd
                    Ycurr = Y(Y > 0);
                    Ycurr(i) = Ycurr(end);
                    Ycurr(end) = [];
                    W = Kernel.swapElements(W,i,lastLabeledInd);
                    fu = GraphHelpers.RunHarmonicFunction(W,Ycurr);
                    fu_1 = fu(1,:);
                    [~,Ypred(i)] = max(fu_1);                    
                    Yscore(i) = fu_1(Yactual(i));
                    labeledTargetScores(i,:) = fu_1;
                    W = Kernel.swapElements(W,lastLabeledInd,i);
                end                
            else
                labeledTargetInds = find(distMat.isLabeledTarget());
                Yscore = zeros(size(labeledTargetInds));
                Ypred = Yscore;
                Yactual = distMat.Y(labeledTargetInds);
                labeledTargetScores = zeros(length(labeledTargetInds),distMat.numClasses);
                if exist('savedData','var') && isfield(savedData,'invM');
                    invM = savedData.invM;
                end 
                
                for i=1:length(labeledTargetInds)
                    ind = labeledTargetInds(i);
                    Ycurr = distMat.Y;
                    Ycurr(ind) = -1;
                    warning off;
                    if exist('invM','var')
                        [fu,invM] = GraphHelpers.RunLLGC(distMat.W,Ycurr,invM);
                    else
                        [fu,invM] = GraphHelpers.RunLLGC(distMat.W,Ycurr);
                    end
                    warning on;
                    Yactual_i = Yactual(i);
                    Yscore(i) = fu(ind,Yactual_i);
                    [~,Ypred(i)] = max(fu(ind,:));
                    labeledTargetScores(i,:) = fu(ind,:);
                end
                
                if exist('savedData','var')
                    savedData.invM = invM;
                end
            end
                     
            Yscore(isnan(Yscore)) = 0;
            n = length(Yactual);
            Yscore = Yscore(Ypred ~= Yactual);
            if isempty(Yscore)
                score = 0;
            else
                score = mean(Yscore);
            end
            percCorrect = sum(Ypred == Yactual)/n;
        end
        function [sigma,bestScore,bestAcc] = autoSelectSigma(distMat,useMeanSigma,useHF)
            
            if nargin < 3
                useHF = false;
            end
            %expVals = -3:3;
            expVals = -5:5;
            if useMeanSigma
                expVals = 0;
            end
            sigmas = zeros(length(expVals),1);            
            base = 2;
            for i=1:length(expVals)
                sigmas(i) = distMat.meanDistance*base^expVals(i);
            end

            scores = zeros(size(sigmas));
            percCorrect = scores;
            for i=1:length(sigmas)
                S = Helpers.distance2RBF(distMat.W,sigmas(i));
                rbfDistMat = DistanceMatrix(S,distMat.Y,distMat.type);
                [scores(i),percCorrect(i)] = ...
                    GraphHelpers.LOOCV(rbfDistMat,useHF);
            end
            %[~,bestInd] = max(scores);
            [~,bestInd] = max(percCorrect);
            sigma = sigmas(bestInd);
            bestScore = scores(bestInd);
            bestAcc = percCorrect(bestInd);
        end        
    end
    
end

