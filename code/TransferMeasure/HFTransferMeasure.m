classdef HFTransferMeasure < TransferMeasure
    %SCTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = HFTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [val,perLabelMeasures,metadata] = computeMeasure(obj,source,target,...
                options)            
            useHF = true;
            [score,percCorrect,Ypred,Yactual,labeledTargetScores,val,metadata] = ...
                obj.computeGraphMeasure(source,target,options,...
                useHF);
            metadata.labeledTargetScores = labeledTargetScores;
            perLabelMeasures = [];
        end
                     
        function [ri] = calculateRandIndex(obj,C,Y,isTarget)
            numClasses = max(Y);
            numClusters = size(C,2);
            numCorrect = zeros(numClasses,1);
            numIncorrect = numCorrect;
            for i=1:numClasses
                for j=1:numClusters
                    clj = C(:,j);
                    targetiJ = clj & Y == i & isTarget;                    
                    if sum(targetiJ) == 0
                        continue;
                    end
                    sourceiJ = clj & Y == i;
                    sourceiOther = clj & Y ~= i;
                    nc = sum(targetiJ)*sum(sourceiJ);
                    nic = sum(targetiJ)*sum(sourceiOther);
                    numCorrect(i) = numCorrect(i) + nc;                    
                    numIncorrect(i) = numIncorrect(i) + nic;
                    %{
                    for k = 1:numClusters
                        if j==k
                            continue;
                        end
                        clk = C(:,k);
                        sourcekJ = clk & Y == i;
                        sourcekOther = clk & Y ~= i;
                        nc = sum(targetiJ)*sum(sourcekOther);
                        nic = sum(targetiJ)*sum(sourcekJ);
                        numCorrect(i) = numCorrect(i) + nc;
                        numIncorrect(i) = numIncorrect(i) + nic;
                    end
                    %}
                end
            end
            accs = numCorrect./(numCorrect+numIncorrect);
            ri = mean(accs);
        end
        function [purity] = calculateClusterPurity(obj,C,Y,isTarget)
            sourceWithLabel = ~isTarget & Y > 0;
            targetWithLabel = isTarget & Y > 0;
            
            [purity,clusterLabels,clusterPurities] = ...
                 SCTransferMeasure.CalculateClusterPurity(C,Y);
        end
                
        
        function [name] = getPrefix(obj)
            name = 'HF';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'useSoftLoss','useMeanSigma'};
        end
    end
    
    methods(Static)
        function [purity,clusterLabels,clusterPurities] =...
                CalculateClusterPurity(C,Y)
            clusterLabels = zeros(size(C,2),1);
            clusterPurities = clusterLabels;
            withLabel = Y > 0;
            for i=1:numel(clusterLabels)
                ci = C(:,i);          
                ci_withLabel = ci & withLabel;
                clusterLabels(i) = mode(Y(ci_withLabel));
                clusterPurities(i) = sum(Y(ci_withLabel) ~= clusterLabels(i))/...
                    sum(ci_withLabel);
            end
            clusterPurities(isnan(clusterPurities)) = -1;
            purity = mean(clusterPurities(clusterPurities >= 0));
        end 
    end
    
end

