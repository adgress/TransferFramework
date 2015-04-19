classdef ActiveMethod < Saveable
    %ACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ActiveMethod(configs)            
            obj = obj@Saveable(configs);
            if ~obj.has('valWeights')
                obj.set('valWeights',0);
            end
        end
        function n = getDisplayName(obj)
            n = obj.getPrefix();
        end
        
        function [queriedIdx,scores] = queryLabel(obj,input,results,s)               
            labelsPerIteration = obj.get('labelsPerIteration');
            unlabeledScores = obj.getScores(input,results,s);  
            unlabeledScores = unlabeledScores .^ 5;
            unlabeledInds = find(input.train.Y < 0);
            %[~,maxIdx] = max(unlabeledScores);
                        
            if obj.get('valWeights')           
                remainingScores = unlabeledScores;
                %remainingScores = ones(size(unlabeledScores));
                
                remainingInds = unlabeledInds;
                scoreIndsToChoose = zeros(labelsPerIteration,1);
                chosenScores = zeros(labelsPerIteration,1);
                for i=1:labelsPerIteration
                    remainingScores = remainingScores ./ sum(remainingScores);
                    %[remainingScores, remainingInds] = sort(remainingScores,'ascend');
                    r = rand();
                    a = cumsum(remainingScores);
                    I = find(r <= a);
                    assert(~isempty(I));
                    bestInd = min(I);
                    scoreIndsToChoose(i) = remainingInds(bestInd);                    
                    chosenScores(i) = ...
                        length(remainingScores)*remainingScores(bestInd);                    
                    remainingScores(bestInd) = [];
                    remainingInds(bestInd) = [];
                end
                %chosenScores(:) = 1;
                %unlabeledScores(scoreIndsToChoose) = chosenScores;                
                unlabeledScores = ones(size(unlabeledScores));
                queriedIdx = scoreIndsToChoose;
            else
                [sortedScores,scoreInds] = sort(unlabeledScores,'descend');
                scoreIndsToChoose = scoreInds(1:labelsPerIteration);                
                unlabeledScores = ones(size(unlabeledScores));
                queriedIdx = unlabeledInds(scoreIndsToChoose);
            end
                                    
            
            scores = -ones(size(input.train.Y,1),1);
            scores(unlabeledInds) = unlabeledScores;
            if obj.get('valWeights') == 1 || obj.get('valWeights') == 3
                scores(queriedIdx) = chosenScores;
            end
        end  
        function [nameParams] = getNameParams(obj)
            nameParams = {};
            if obj.has('valWeights') && obj.get('valWeights')
                nameParams{end+1} = 'valWeights';
            end
        end
        function [d] = getDirectory(obj)
            error('Do we save based on active method?');
        end
    end
    
    methods(Abstract)  
        [scores] = getScores(obj,input,results,s)
    end  
    
end

