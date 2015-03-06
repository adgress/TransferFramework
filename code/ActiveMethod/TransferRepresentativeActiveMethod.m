classdef TransferRepresentativeActiveMethod < ActiveMethod
    %TRANSFERREPRESENTATIVEACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function obj = TransferRepresentativeActiveMethod(configs)            
            obj = obj@ActiveMethod(configs);
        end
        
        function [queriedIdx,scores] = queryLabel(obj,input,results,s)               
            
            unlabeledScores = obj.getScores(input,results,s);
            unlabeledInds = find(input.train.Y < 0);
            [~,maxIdx] = max(unlabeledScores);
            queriedIdx = unlabeledInds(maxIdx);
            
            scores = -ones*size(input.train.Y);
            scores(unlabeledInds) = unlabeledScores;
        end  
        
        function [scores] = getScores(obj,input,results,s)
            sigmaScale = .2;
            W = Helpers.CreateDistanceMatrix(input.train.X);
            Wrbf = Helpers.distance2RBF(W,mean(W(:))*sigmaScale);
                        
            unlabeledInds = find(input.train.Y < 0);      
            sourceInds = find(input.train.isSource());
            
            unlabeled2source = Wrbf(unlabeledInds,sourceInds);
            unlabeledScores = sum(unlabeled2source,2);
            scores = unlabeledScores;
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'TransferRep';
        end 
    end
    
end

