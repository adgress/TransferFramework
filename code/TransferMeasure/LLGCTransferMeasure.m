classdef LLGCTransferMeasure < TransferMeasure
    %SCTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LLGCTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [val,metadata] = computeMeasure(obj,source,target,...
                options)            
            metadata = {};                        
            
            targetWithLabels = target.Y > 0;
            if sum(targetWithLabels) == 0 || ...
                sum(targetWithLabels) <= max(target.Y)
                val = nan;
                return;
            end
            if nargin >= 4 && isfield(options,'distanceMatrix')
                W = options.distanceMatrix;
            else                
                Xall = [source.X ; target.X];                                
                Y = [source.Y ; target.Y];
                type = [ones(numel(source.Y),1)*DistanceMatrix.TYPE_SOURCE ;...
                    ones(numel(target.Y),1)*DistanceMatrix.TYPE_TARGET_TRAIN];
                W = Kernel.Distance(Xall);
                W = DistanceMatrix(W,Y,type);
                clear type;
            end            
            [W,Ys,Yt,isTarget] = W.prepareForSourceHF();
            sigma = Helpers.autoSelectSigma(W,Ys,Yt,~isTarget,true,false);
            W = Helpers.distance2RBF(W,sigma);
            addpath(genpath('libraryCode'));
            Y = [Ys ; Yt];            
            labeledTarget = length(Ys) + find(Yt > 0);            
            numCorrect = 0;
            score = 0;
            Ymat = full(Helpers.createLabelMatrix(Y));
            for i=1:length(labeledTarget)
                ind = labeledTarget(i);
                yi = Ymat(ind,:);
                Ymat(ind,:) = 0;
                if i==1
                    [fu,invM] = llgc(W,Ymat);
                else
                    [fu,~] = llgc(W,Ymat,invM);
                end
                fu_i = fu(ind,:);
                yActual = Y(ind);
                [~,yPred] = max(fu_i);
                score = score + fu_i(yActual);  
                numCorrect = numCorrect + (yPred == yActual);
                Ymat(ind,:) = yi;
            end
            n = length(labeledTarget);
            score = score/n;
            numCorrect = numCorrect/n;
            %{
            [fu] = llgc(W, Helpers.createLabelMatrix(Y));
            Yactual = Yt(Yt > 0);
            labelMat = Helpers.createLabelMatrix(Yactual);
            n = length(Yactual);
            isLabeledTarget = length(Ys) + find(Yt > 0);
            fuLabeledTarget = fu(isLabeledTarget,:);            
            
            score = sum(fuLabeledTarget(logical(labelMat)))/n;
            [~,pred] = max(fuLabeledTarget,[],2);
            numCorrect = sum(Yactual==pred)/n;
            %}
            if obj.configs('useSoftLoss')
                val = score;
            else
                val = numCorrect;
            end
            obj.displayMeasure(val);
        end            
        
        function [name] = getPrefix(obj)
            name = 'LLGC';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'useSoftLoss'};
        end
    end    
end

