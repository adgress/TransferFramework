classdef TransferMeasure < Saveable
    %TRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = TransferMeasure(configs)
            obj = obj@Saveable(configs);
        end
        
        function [score,percCorrect,Ypred,Yactual,labeledTargetScores,val,metadata,savedData] = ...
                computeGraphMeasure(obj,source,target,options,...
                useHF,savedData)
            metadata = struct();
            targetWithLabels = target.Y > 0;
            if sum(targetWithLabels) == 0 || ...
                sum(targetWithLabels) <= max(target.Y)
                score = nan;
                percCorrect = nan;
                Ypred = [];
                Yactual = [];
                numLabels = max(source.Y);
                labeledTargetScores = nan(size(targetWithLabels,1),numLabels);
                return;
            end
            useMeanSigma = obj.configs('useMeanSigma');
            if nargin >= 4 && isfield(options,'distanceMatrix')
                error('Not yet implemented!');
                W = options.distanceMatrix;                
            else                
                Xall = [source.X ; target.X];  
                if obj.configs('zscore')
                    Xall = zscore(Xall);
                end
                Y = [source.Y ; target.Y];
                %{
                type = [ones(numel(source.Y),1)*Constants.SOURCE ;...
                    ones(numel(target.Y),1)*Constants.TARGET_TRAIN];
                %}
                type = [source.type ; target.type];
                if exist('savedData','var') && isfield(savedData,'W')
                    W = savedData.W;
                else
                    W = Kernel.Distance(Xall);                    
                    if exist('savedData','var')
                        savedData.W = W;
                    end
                end
                W = DistanceMatrix(W,Y,type);
            end            
            [W,Ys,Yt,type,isTarget] = W.prepareForSourceHF();                      
            if ~obj.configs('useSourceForTransfer')                
                W = W(isTarget,isTarget);
                type = type(isTarget);
                Ys = zeros(0,size(Ys,2));
                isTarget = isTarget(isTarget);            
            end
            if isKey(obj.configs,'sigma')
                sigma = obj.configs('sigma');
            else
                [sigma,~,~] = GraphHelpers.autoSelectSigma(W,[Ys;Yt],isTarget,useMeanSigma,useHF,type);            
            end
            metadata.sigma = sigma;
            rerunLOOCV = 1;
            if rerunLOOCV
                W = Helpers.distance2RBF(W,sigma);                
                if exist('savedData','var')
                    [score, percCorrect,Ypred,Yactual,labeledTargetScores,savedData] = GraphHelpers.LOOCV(W,...
                        [],[Ys ; Yt],useHF,type,savedData);
                else
                    [score, percCorrect,Ypred,Yactual,labeledTargetScores] = GraphHelpers.LOOCV(W,...
                        [],[Ys ; Yt],useHF,type);
                end
            else
                display('TransferMeasure: Not rerunning LOOCV');
                labeledTargetScores = [];
                Ypred = [];
                Yactual = [];
            end
            if obj.configs('useSoftLoss')
                val = score;                                
            else
                val = percCorrect;                
            end            
            obj.displayMeasure(val);
            metadata.Ypred = Ypred;
            metadata.Yactual = Yactual;
        end         
        
        function [d] = getDirectory(obj)
            d = 'TM';
        end
        function [] = displayMeasure(obj,val)
            display([obj.getPrefix() ' TransferMeasure: ' num2str(val)]); 
        end
    end
    
    methods(Abstract)
        [val,perLabelMeasures,metadata] = computeMeasure(obj,source,target,options)        
    end
    
end

