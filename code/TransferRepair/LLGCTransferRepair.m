classdef LLGCTransferRepair < TransferRepair       
    properties
    end
    
    methods
        function obj = LLGCTransferRepair(configs)
            obj = obj@TransferRepair(configs);                    
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
            elseif isequal(strategy,'NNPrune')
                dataSet = DataSet.Combine(input.train,input.test);
                dataSet.removeTestLabels();
                [scores,predicted] = max(targetScores,[],2);
                labeledTargetTrainInds = find(input.train.Y > 0 & ...
                    input.train.type == Constants.TARGET_TRAIN);
                correctLabels = input.train.Y(labeledTargetTrainInds);
                isIncorrect = predicted ~= correctLabels;
                incorrectScores = targetScores(isIncorrect);
                incorrectInds = labeledTargetTrainInds(isIncorrect);
                correctTargetLabels = input.train.Y(incorrectInds);
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
                indsToPrune = indsToPrune(1:numToPrune);
                repairedInput.train.remove(indsToPrune);
            else
                error(['Unknown Strategy: ' strategy]);
            end
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'LLGC';
        end        
        function [nameParams] = getNameParams(obj)
            nameParams = {'strategy','percToRemove','numIterations'};
        end
    end
    
    
end

