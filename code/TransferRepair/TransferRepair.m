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
                incorrectInds = labeledTargetTrainInds(isIncorrect);
                correctTargetLabels = input.train.Y(incorrectInds);
                if useAdvaned
                    isSource = input.train.type == Constants.SOURCE;
                    sourceLabels = input.train.Y(isSource);
                    sourceLabelsRep = repmat(sourceLabels',length(correctLabels),1);
                    targetLabelsRep = repmat(correctLabels,1,length(sourceLabels));
                    D = Helpers.CreateDistanceMatrix(...
                        input.train.X(labeledTargetTrainInds,:),...
                        input.train.X(isSource,:));
                    isCorrectRep = sourceLabelsRep == targetLabelsRep;
                    isIncorrectRep = ~isCorrectRep;
                    incorrectDistances = D.*isIncorrectRep;                    
                    incorrectSourceScores = sum(incorrectDistances);
                    [sortedScores,sortedScoreInds] = sort(incorrectSourceScores,'ascend');
                    sourceInds = find(isSource);
                    indsToPrune = sourceInds(sortedScoreInds);
                else
                    D = Helpers.CreateDistanceMatrix(...
                        input.train.X(incorrectInds,:),...
                        input.train.X);
                    [sortedD,sortedDInds] = sort(D,2);
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
            nameParams = {'strategy','percToRemove','numIterations'};
        end        
    end    
end

