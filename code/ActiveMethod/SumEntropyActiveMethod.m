classdef SumEntropyActiveMethod < EntropyActiveMethod
    %PAIREDACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = SumEntropyActiveMethod(configs)            
            obj = obj@EntropyActiveMethod(configs);                     
        end
        function [queriedIdx] = queryLabel(obj,input,results,s)
            H = [];            
            fuTrain = results.trainFU;
            fuTrainTarget = s.preTransferResults.trainFU;
            unlabeledInds = find(input.train.Y < 0);            
            for i=unlabeledInds'
                assert(length(i) == 1);
                H(end+1) = obj.entropy(fuTrain(i,:)) + ...
                    obj.entropy(fuTrainTarget(i,:));
            end
            [~,maxInd] = max(H);
            queriedIdx = unlabeledInds(maxInd);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'SumEntropy';
        end  
    end
    
end

