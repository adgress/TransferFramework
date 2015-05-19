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
            obj.set('scale',ProjectConfigs.activeMethodScale);
        end
        function n = getDisplayName(obj)
            n = obj.getPrefix();
        end
        
        function [queriedIdx,scores,metadata] = queryLabel(obj,input,results,s)               
            metadata = struct();
            metadata.divergence = 0;
            labelsPerIteration = obj.get('labelsPerIteration');
            unlabeledScores = obj.getScores(input,results,s);  
            unlabeledInds = find(input.train.Y < 0);
            %[~,maxIdx] = max(unlabeledScores);
                        
            if obj.get('valWeights')
                remainingScores = unlabeledScores;
                if sum(remainingScores) <= 1e-14
                    display('sum(remainingScores) <= 1e-14.  Making weights uniform');
                    remainingScores(:) = 1;
                end
                v = obj.get('valWeights');
                remainingScores = remainingScores .^ obj.get('scale');
                o = ones(size(remainingScores))/length(remainingScores);
                remainingScores = remainingScores ./ sum(remainingScores);
                metadata.divergence = norm(remainingScores - o);
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
                    pdfVals = remainingScores(bestInd);
                    sizes = length(remainingScores);
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
            metadata.pdfVals = scores;
            metadata.sizes = scores;
            scores(unlabeledInds) = unlabeledScores;
            
            if obj.get('valWeights') == 1
                metadata.sizes(queriedIdx) = sizes;
                metadata.pdfVals(queriedIdx) = pdfVals;
                scores(queriedIdx) = chosenScores;
            end
        end  
        function [nameParams] = getNameParams(obj)
            nameParams = {};           
            useValWeights = obj.has('valWeights') && obj.get('valWeights');
            if useValWeights
                nameParams{end+1} = 'valWeights';
            end
            if obj.has('scale') && obj.get('scale') ~= 1 && useValWeights
                nameParams{end+1} = 'scale';
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

