classdef ActiveMethod < Saveable
    %ACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ActiveMethod(configs)            
            obj = obj@Saveable(configs);
        end
        function n = getDisplayName(obj)
            n = obj.getPrefix();
        end
        
        function [queriedIdx,scores] = queryLabel(obj,input,results,s)               
            labelsPerIteration = obj.get('labelsPerIteration');
            unlabeledScores = obj.getScores(input,results,s);
            unlabeledInds = find(input.train.Y < 0);
            %[~,maxIdx] = max(unlabeledScores);
            [sortedScores,scoreInds] = sort(unlabeledScores,'descend');
            scoreIndsToChoose = scoreInds(1:labelsPerIteration);
            queriedIdx = unlabeledInds(scoreIndsToChoose);
            scores = -ones(size(input.train.Y,1),1);
            scores(unlabeledInds) = unlabeledScores;
        end  
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
        function [d] = getDirectory(obj)
            error('Do we save based on active method?');
        end
    end
    
    methods(Abstract)  
        [scores] = getScores(obj,input,results,s)
    end  
    
end

