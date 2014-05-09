classdef LLGCTransferMeasure < TransferMeasure
    %SCTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LLGCTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [val,perLabelMeasures,metadata] = computeMeasure(obj,source,target,...
                options)            
            metadata = {};                        
            
            targetWithLabels = target.Y > 0;
            if sum(targetWithLabels) == 0 || ...
                sum(targetWithLabels) <= max(target.Y)
                val = nan;
                numLabels = max(source.Y);
                perLabelMeasures = nan(1,numLabels);
                return;
            end
            if nargin >= 4 && isfield(options,'distanceMatrix')
                W = options.distanceMatrix;
            else                
                Xall = [source.X ; target.X];                                
                Y = [source.Y ; target.Y];
                type = [ones(numel(source.Y),1)*Constants.SOURCE ;...
                    ones(numel(target.Y),1)*Constants.TARGET_TRAIN];
                W = Kernel.Distance(Xall);
                W = DistanceMatrix(W,Y,type);
                clear type;
            end            
            [W,Ys,Yt,type,isTarget] = W.prepareForSourceHF();       
            if ~obj.configs('useSourceForTransfer')
                W = W(isTarget,isTarget);
                Ys = zeros(0,size(Ys,2));
                type = type(isTarget);
                isTarget = isTarget(isTarget);               
            end            
            sigma = Helpers.autoSelectSigma(W,[Ys;Yt],~isTarget,true,false,type);
            W = Helpers.distance2RBF(W,sigma);                        
            Y = [Ys ; Yt];
            [score,percCorrect,Ypred,Yactual] = Helpers.LOOCV(W,[],Y,false,type);
            if obj.configs('useSoftLoss')
                val = score;
                display('Not using softloss for perLabelAccuracy');
                perLabelMeasures = ...
                    Helpers.getAllLabelAccuracy(Ypred,Yactual);
            else
                val = percCorrect;
                perLabelMeasures = ...
                    Helpers.getAllLabelAccuracy(Ypred,Yactual);
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

