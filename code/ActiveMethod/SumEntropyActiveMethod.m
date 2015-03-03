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
            HTarget = [];
            fuTrain = results.trainFU;
            fuTrainTarget = s.preTransferResults.trainFU;
            unlabeledInds = find(input.train.Y < 0);            
            for i=unlabeledInds'
                assert(length(i) == 1);
                H(end+1) = obj.entropy(fuTrain(i,:));
                HTarget(end+1) = obj.entropy(fuTrainTarget(i,:));
            end
            [maxVal,maxInd] = max(H + HTarget);
            [maxHTarget,maxTargetInd] = max(HTarget);
            HMax = H(maxInd);
            HTargetMax = HTarget(maxInd);
            fuInd = unlabeledInds(maxInd);
            queriedIdx = unlabeledInds(maxInd);
            %queriedIdx = unlabeledInds(maxTargetInd);
            %display(['Sum Best: ' num2str(max(H)/maxVal) ' ' num2str(max(HTarget)/maxVal)]);
            %display(['Target Best: ' num2str(max(H)/maxHTarget) ' ' num2str(max(H))]);
            display(['Sum Best: ' num2str(HMax) ' ' num2str(HTargetMax)]);
            display(['Target Best: ' num2str(H(maxTargetInd)) ' ' num2str(HTarget(maxTargetInd))]);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'SumEntropy';
        end  
    end
    
end

