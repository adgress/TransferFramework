classdef TransferRepair < Saveable
    %TRANSFERREPAIR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
        
    methods
        function [obj] = TransferRepair(configs)
            obj = obj@Saveable(configs);
        end
        function [d] = getDirectory(obj)
            d = 'REP';
        end
        
        function [repairedInput] = ...
                repairTransfer(obj,input,targetScores)
            percToRemove = obj.configs('percToRemove');
            
            repairedInput = input;
            strategy = obj.configs('strategy');
            
            isSource = input.train.type == Constants.SOURCE;
            sourceInds = find(isSource);
            numSource = length(sourceInds);
            numToPrune = floor(percToRemove*numSource);
            if isequal(strategy,'Random')
                toRemove = randperm(numSource,numToPrune);
                repairedInput.train.remove(sourceInds(toRemove));
            elseif isequal(strategy,'NNPrune') || isequal(strategy,'AddvancedNNPrune')
                useAdvaned = isequal(strategy,'AddvancedNNPrune');
                dataSet = DataSet.Combine(input.train,input.test);
                dataSet.removeTestLabels();
                [scores,predicted] = max(targetScores,[],2);
                labeledTargetTrainInds = find(input.train.Y > 0 & ...
                    input.train.type == Constants.TARGET_TRAIN);
                correctLabels = input.train.Y(labeledTargetTrainInds);
                isIncorrect = predicted ~= correctLabels;
                
                correctLabelMat = Helpers.createLabelMatrix(correctLabels);
                correctLabelScores = max(targetScores.*correctLabelMat,[],2);                
                
                [sortedCorrectScores,sortedInds] = sort(correctLabelScores,'ascend');                
                
                incorrectInds = labeledTargetTrainInds(isIncorrect);
                correctTargetLabels = input.train.Y(incorrectInds);
                
                percIncorrectToUse = .2;
                numIncorrectToUse = ceil(percIncorrectToUse*length(sortedInds));
                trainIndsToUse = sortedInds(1:numIncorrectToUse );
                correctTargetLabels = correctLabels(trainIndsToUse);
                if obj.configs('useECT')
                    sigma = obj.configs('sigma');
                    W = Helpers.CreateDistanceMatrix(input.train.X);
                    W = Helpers.distance2RBF(W,sigma);
                    D = diag(sum(W));
                    L = D - W;
                    distMat = pinv(L);
                end
                if useAdvaned
                    %trainIndsToUse = labeeldTargetTrainInds;
                    isSource = input.train.type == Constants.SOURCE;
                    sourceLabels = input.train.Y(isSource);
                    sourceLabelsRep = repmat(sourceLabels',length(correctLabels),1);
                    targetLabelsRep = repmat(correctLabels,1,length(sourceLabels));
                    if obj.configs('useECT')
                        distMat = distMat(trainIndsToUse,isSource);
                    else
                        distMat = Helpers.CreateDistanceMatrix(...
                            input.train.X(trainIndsToUse,:),...
                            input.train.X(isSource,:));
                    end
                    isCorrectRep = sourceLabelsRep == targetLabelsRep;
                    isIncorrectRep = ~isCorrectRep;
                    incorrectDistances = distMat.*isIncorrectRep;                    
                    incorrectSourceScores = sum(incorrectDistances);
                    [sortedScores,sortedScoreInds] = sort(incorrectSourceScores,'ascend');
                    sourceInds = find(isSource);
                    indsToPrune = sourceInds(sortedScoreInds);
                else
                    %trainIndsToUse = incorrectInds;
                    if obj.configs('useECT')
                        distMat = distMat(trainIndsToUse,:);
                    else
                        distMat = Helpers.CreateDistanceMatrix(...
                            input.train.X(trainIndsToUse,:),...
                            input.train.X);
                    end
                    [sortedD,sortedDInds] = sort(distMat,2);
                    i = 1;
                    indsToPrune = [];
                    while length(indsToPrune) < numToPrune;
                        currInds = sortedDInds(:,i);                    
                        actualLabels = input.train.Y(currInds);
                        isIncorrect = correctTargetLabels ~= actualLabels;
                        isNNSource = isSource(currInds);                    
                        shouldPrune = currInds(isNNSource & isIncorrect & ...
                            actualLabels > 0);
                        indsToPrune = [indsToPrune ; shouldPrune];
                        if length(indsToPrune) >= numToPrune
                            indsToPrune = unique(indsToPrune);
                        end
                        i = i + 1;
                    end   
                end
                indsToPrune = indsToPrune(1:numToPrune);
                repairedInput.train.remove(indsToPrune);
            else
                error(['Unknown Strategy: ' strategy]);
            end
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'TR';
        end        
        function [nameParams] = getNameParams(obj)
            nameParams = {'strategy','percToRemove','numIterations','useECT'};
        end        
    end    
end

