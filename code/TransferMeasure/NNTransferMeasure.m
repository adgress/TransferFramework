classdef NNTransferMeasure < TransferMeasure
    %NNTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = NNTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [val,perLabelMeasures,metadata] = computeMeasure(obj,source,target,options)            
            metadata = struct();
            k = obj.configs('k');
            assert(k==1);
            targetWithLabels = target.Y > 0;
            sourceWithLabels = source.Y > 0;
            if sum(targetWithLabels) == 0
                val = nan;
                return;
            end
            includeTarget = 1;
            if isfield(options,'distanceMatrix')
                W = options.distanceMatrix;
                [Yactual, Ynn] = W.getLabeledTrainToSourceNN(k);
                assert(size(Ynn,2) == k);
            else
                if includeTarget
                    X = target.X(targetWithLabels,:);
                    Y = target.Y(targetWithLabels,:);
                    if obj.configs('useSourceForTransfer')
                        X = [X ; source.X(sourceWithLabels,:)];
                        Y = [Y ; source.Y(sourceWithLabels,:)];
                    end
                    startIndex = 2;
                    endIndex = k+1;
                else
                    error('Not yet implemented');
                    startIndex = 1;
                    endIndex = k;
                    X = source.X(sourceWithLabels,:);
                    Y = source.Y(sourceWithLabels,:);
                end
                %{
                [Dtl,Itl] = pdist2(X,target.X(targetWithLabels,:),'euclidean','Smallest',endIndex);                
                Dtl = Dtl';
                Itl = Itl';
                Dtl = Dtl(:,startIndex:endIndex);
                Itl = Itl(:,startIndex:endIndex);
                Yactual = target.Y(targetWithLabels);
                Ynn = Y(Itl);
                %}
                [minInds] = Helpers.KNN(X,target.X(targetWithLabels,:),endIndex);
                minInds = minInds(:,startIndex:endIndex);
                Yactual = target.Y(targetWithLabels);
                Ynn = Y(minInds);
                %{
                Dt = D(numSource+1:end,1:numSource);
                It = I(numSource+1:end,1:numSource);
                numTarget = sum(It > numSource,2)/k;
                val = mean(numTarget);
                %}                                
            end            
            numTargetLabeled = ...
                sum(Ynn == repmat(Yactual,1,k),2)/k;   
            
            assert(k == 1);
            perLabelMeasures = ...
                Helpers.getAllLabelAccuracy(Ynn,Yactual);
            metadata.Ypred = Ynn;
            metadata.Yactual = Yactual;
            val = mean(numTargetLabeled);
            obj.displayMeasure(val);          
            metadata.labeledTargetScores = [];
        end
                     
        function [name] = getPrefix(obj)
            name = 'NN';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'k'};
        end
    end
    
end

