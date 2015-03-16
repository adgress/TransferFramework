classdef EntropyActiveMethod < ActiveMethod
    %ENTROPYACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = EntropyActiveMethod(configs)            
            obj = obj@ActiveMethod(configs);
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
            scores = [];
            fuTrain = results.trainFU;
            unlabeledInds = find(input.train.Y < 0);
            for i=unlabeledInds'
                assert(length(i) == 1);
                scores(end+1) = obj.entropy(fuTrain(i,:));
            end
            scores = scores';
        end
        
        %From http://stackoverflow.com/questions/22074941/shannons-entropy-calculation
        function [H] = entropy(obj,p)
            H = sum(-(p(p>0).*(log2(p(p>0))))); 
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'Entropy';
        end        
    end
    
end

