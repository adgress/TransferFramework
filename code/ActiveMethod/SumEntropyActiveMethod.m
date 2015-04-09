classdef SumEntropyActiveMethod < EntropyActiveMethod
    %PAIREDACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = SumEntropyActiveMethod(configs)            
            obj = obj@EntropyActiveMethod(configs);
            obj.set('method',1);
        end
        function [scores] = getScores(obj,input,results,s)
            H = [];            
            HTarget = [];
            fuTrain = results.trainFU;
            fuTrainTarget = s.preTransferResults.trainFU;
            unlabeledInds = find(input.train.Y < 0);            
            cvAcc = results.learnerMetadata.cvAcc;
            preCVAcc = s.preTransferResults.learnerMetadata.cvAcc;
            s = 3;
            pPosTransfer = exp(s*cvAcc)/(exp(s*cvAcc) + exp(s*preCVAcc));
            for i=unlabeledInds'
                assert(length(i) == 1);
                H(end+1) = obj.entropy(fuTrain(i,:));
                HTarget(end+1) = obj.entropy(fuTrainTarget(i,:));
            end
            H = Helpers.NormalizeRange(H);
            HTarget = Helpers.NormalizeRange(HTarget);
            scores = H + HTarget;
            if obj.get('method') == 1
                if pPosTransfer > .5
                    [maxVal,maxInd] = max(H);
                    scores = H;
                else
                    [maxVal,maxInd] = max(HTarget);
                    scores = HTarget;
                end
            else
                [maxVal,maxInd] = max(H + HTarget);
            end
            [maxHTarget,maxTargetInd] = max(HTarget);
            HMax = H(maxInd);
            HTargetMax = HTarget(maxInd);
            fuInd = unlabeledInds(maxInd);
            %queriedIdx = unlabeledInds(maxInd);
            %queriedIdx = unlabeledInds(maxTargetInd);
            %display(['Sum Best: ' num2str(max(H)/maxVal) ' ' num2str(max(HTarget)/maxVal)]);
            %display(['Target Best: ' num2str(max(H)/maxHTarget) ' ' num2str(max(H))]);
            format shortEng
            %format compact
            display(['Sum Best: ' num2str(Helpers.Normalize(HMax,H)) ' ' num2str(Helpers.Normalize(HTargetMax,HTarget))]);
            display(['Target Best: ' num2str(Helpers.Normalize(H(maxTargetInd),H)) ' ' num2str(Helpers.Normalize(HTarget(maxTargetInd),HTarget))]);
            format                       
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'SumEntropy';
        end  
        function [nameParams] = getNameParams(obj)
            nameParams = {};
            if obj.has('method') && obj.get('method') > 0
                nameParams{end+1} = 'method';
            end
        end
    end
    
end

