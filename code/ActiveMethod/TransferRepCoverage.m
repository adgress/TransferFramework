classdef TransferRepCoverage < ActiveMethod
    %TRANSFERREPCOVERAGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TransferRepCoverage(configs)            
            obj = obj@ActiveMethod(configs);
            obj.set('method',3);
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
            %W = Helpers.SparsifyDistanceMatrix(W,20);
            m = mean(W(W(:) > 0));
            Wrbf = Helpers.distance2RBF(W,m*sigmaScale);
            Wrbf(W(:) == 0) = 0;
            labeledTargetInds = find(input.train.isLabeledTarget());
            unlabeledInds = find(input.train.Y < 0);
            sourceInds = find(input.train.isSource());            
            labeledTarget2source = Wrbf(labeledTargetInds,sourceInds);
            unlabeled2source = Wrbf(unlabeledInds,sourceInds);
            
            switch obj.get('method')
                case 0
                    sourceScores = sum(labeledTarget2source);
                    sourceScores = sourceScores + 1e-3;
                    sourceScores = 1./sourceScores;                    

                    scores = unlabeled2source*sourceScores';
                case 2
                    sourceScores = sum(labeledTarget2source) ./ size(labeledTarget2source,1);
                    sourceScores = sourceScores + 1e-6;
                    invSourceScores = sourceScores;
                    sourceScores = 1./sourceScores;                    
                    scores = unlabeled2source*sourceScores';
                    %display('');
                case 3
                    targetEntropy = TargetEntropyActiveMethod(Configs());
                    [~,entropyScores] = targetEntropy.queryLabel(input,results,s);
                    %s1 = Helpers.NormalizeRange(scores);                    
                    sourceScores = entropyScores(sourceInds);
                    scores = unlabeled2source*sourceScores';
                otherwise
                    error('');
            end            
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'TransferRepCov';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {};
            if obj.has('method') && obj.get('method') > 0
                nameParams{end+1} = 'method';
            end
        end
    end
    
end

