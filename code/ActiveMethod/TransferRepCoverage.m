classdef TransferRepCoverage < ActiveMethod
    %TRANSFERREPCOVERAGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TransferRepCoverage(configs)            
            obj = obj@ActiveMethod(configs);
            obj.set('method',9);
        end
        
        function [queriedIdx,scores] = queryLabel(obj,input,results,s)   
            if obj.get('method') == 6 && mod(sum(input.train.Y > 0),2) == 1
                targetEntropy = TargetEntropyActiveMethod(Configs());
                [queriedIdx,scores] = targetEntropy.queryLabel(input,results,s);
            else
                [queriedIdx,scores] = queryLabel@ActiveMethod(obj,input,results,s);
                %{
                unlabeledScores = obj.getScores(input,results,s);
                [~,maxIdx] = max(unlabeledScores);
                unlabeledInds = find(input.train.Y < 0);
                queriedIdx = unlabeledInds(maxIdx);

                scores = -ones*size(input.train.Y);
                scores(unlabeledInds) = unlabeledScores;
                %}
            end
            
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
            
            targetEntropy = TargetEntropyActiveMethod(Configs());
            [~,entropyScores] = targetEntropy.queryLabel(input,results,s);
            
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
                    
                    %s1 = Helpers.NormalizeRange(scores);        
                    D = diag(sum(unlabeled2source,2));
                    sourceScores = entropyScores(sourceInds);
                    scores = inv(D)*unlabeled2source*sourceScores';
                case 4                    
                    sourceScores = entropyScores(sourceInds);
                    sourceScores = Helpers.NormalizeRange(sourceScores);
                    scores = unlabeled2source*sourceScores';
                case {5,6}
                    %targetInds = find(input.train.isTarget());
                    %source2target = Wrbf(sourceInds,targetInds);
                    source2unlabeledTarget = Wrbf(sourceInds,unlabeledInds);
                    [sortedVals,sortedInds] = sort(source2unlabeledTarget,2,'ascend');
                    scores = zeros(size(unlabeledInds));
                    toUse = sortedInds(:,1:3);
                    toUse = toUse(:);
                    [freq,uniqueVals] = hist(toUse,unique(toUse));
                    scores(uniqueVals) = freq;                   
                                        
                    %{
                    targetEntropy = TargetEntropyActiveMethod(Configs());
                    [~,entropyScores] = targetEntropy.queryLabel(input,results,s);                    
                    sourceScores = entropyScores(sourceInds);
                    sourceScores = Helpers.NormalizeRange(sourceScores);
                    scores2 = unlabeled2source*sourceScores';
                    %}
                    sourceScores = ones(size(unlabeled2source,2),1);
                    scores2 = unlabeled2source*sourceScores;
                    display(['5: ' num2str(argmax(scores)) ', 4: ' num2str(argmax(scores2))]);
                case {7,8,9}
                    unlabeledScores = sum(unlabeled2source,2);  
                    entropyScores = entropyScores';
                    unlabeledEntropyScores = entropyScores(unlabeledInds);
                    unlabeledEntropyScores = Helpers.NormalizeRange(unlabeledEntropyScores);
                    if obj.get('method') == 8
                        unlabeledScores = Helpers.NormalizeRange(unlabeledScores);
                    end
                    if obj.get('method') == 9
                        scores = unlabeledScores + unlabeledEntropyScores;
                    else
                        scores = unlabeledScores .* unlabeledEntropyScores;
                    end
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

