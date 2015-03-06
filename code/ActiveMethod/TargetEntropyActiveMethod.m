classdef TargetEntropyActiveMethod < EntropyActiveMethod
    %ENTROPYACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TargetEntropyActiveMethod(configs)            
            obj = obj@EntropyActiveMethod(configs);
        end
        
        function [queriedIdx,scores] = queryLabel(obj,input,results,s)   
            H = getScores(input,results,s);
            [~,maxInd] = max(H);
            unlabeledInds = find(input.train.Y < 0);
            queriedIdx = unlabeledInds(maxInd);
            scores = -ones*size(input.train.Y);
            scores(unlabeledInds) = H;
        end      
        
        function [scores] = getScores(obj,input,results,s)
            scores = [];
            fuTrain = s.preTransferResults.trainFU;
            unlabeledInds = find(input.train.Y < 0);
            for i=unlabeledInds'
                assert(length(i) == 1);
                scores(end+1) = obj.entropy(fuTrain(i,:));
            end
            scores = scores';           
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'TargetEntropy';
        end        
    end
    
end

