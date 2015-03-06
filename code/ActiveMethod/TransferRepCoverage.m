classdef TransferRepCoverage < ActiveMethod
    %TRANSFERREPCOVERAGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TransferRepCoverage(configs)            
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
            sigmaScale = .2;
            W = Helpers.CreateDistanceMatrix(input.train.X);
            Wrbf = Helpers.distance2RBF(W,mean(W(:))*sigmaScale);
                        
            labeledTargetInds = find(input.train.isLabeledTarget());      
            sourceInds = find(input.train.isSource());
            labeledTarget2source = Wrbf(labeledTargetInds,sourceInds);
            %labeledTarget2source = max(labeledTarget2source(:)) - labeledTarget2source;            
            sourceScores = sum(labeledTarget2source);
            sourceScores = sourceScores + 1e-3;
            sourceScores = 1./sourceScores;
            unlabeledInds = find(input.train.Y < 0);
            unlabeled2source = Wrbf(unlabeledInds,sourceInds);
                        
            %unlabeledScores = sum(unlabeled2source,2);
            scores = unlabeled2source*sourceScores';
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'TransferRepCov';
        end
    end
    
end

