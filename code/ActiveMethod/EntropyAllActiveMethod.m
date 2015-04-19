classdef EntropyAllActiveMethod < EntropyActiveMethod
    %ENTROPYACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = EntropyAllActiveMethod(configs)            
            obj = obj@EntropyActiveMethod(configs);
            obj.set('normalize',1);
        end
        %{
        function [queriedIdx,scores] = queryLabel(obj,input,results,s)   
            H = obj.getScores(input,results,s);
            [~,maxInd] = max(H);
            unlabeledInds = find(input.train.Y < 0);
            queriedIdx = unlabeledInds(maxInd);
            scores = -ones*size(input.train.Y);
            scores(unlabeledInds) = H;
        end        
        %}
        function [scores] = getScores(obj,input,results,s)
            r = s.preTransferResults;
            unlabeledInds = find(input.train.Y < 0);
            scores = zeros(length(unlabeledInds),length(r.modelResults));
            for indIdx=1:length(unlabeledInds)
                ind = unlabeledInds(indIdx);
                for modelIdx=1:length(r.modelResults)                    
                    scores(indIdx,modelIdx) = ...
                        obj.entropy(r.modelResults(modelIdx).dataFU(ind,:));
                end
            end
            %{
            for modelIdx=1:size(scores,2)
                scores(:,modelIdx) = Helpers.NormalizeRange(scores(:,modelIdx));
            end
            %}
            scores = mean(scores,2);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'EntropyAll';
        end        
    end
    
end

