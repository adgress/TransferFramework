classdef TransferRepEntropyActiveMethod < ActiveMethod
    %TRANSFERREPENTROPYACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TransferRepEntropyActiveMethod(configs)            
            obj = obj@ActiveMethod(configs);
        end
        
        function [queriedIdx,scores] = queryLabel(obj,input,results,s)                           
            unlabeledScores = obj.getScores(input,results,s);
            
            [~,maxIdx] = max(unlabeledScores);
            unlabeledInds = find(input.train.Y < 0);
            queriedIdx = unlabeledInds(maxIdx);
            
            scores = -ones*size(input.train.Y);
            scores(unlabeledInds) = unlabeledScores;
        end  
        
        function [scores] = getScores(obj,input,results,s)
            targetEntropy = TargetEntropyActiveMethod(Configs());
            transferRep = TransferRepresentativeActiveMethod(Configs());
            s1 = Helpers.NormalizeRange(targetEntropy.getScores(input,results,s));
            s2 = transferRep.getScores(input,results,s);
            scores = s1 .* s2;
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'TransferRepEnt';
        end 
    end
    
end

