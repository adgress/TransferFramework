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
            useMeanSigma = obj.configs.get('useMeanSigma');
            if nargin >= 4 && isfield(options,'distanceMatrix')
                error('Not yet implemented!');
                W = options.distanceMatrix;                
            else                
                XallCombined = [source.X ; target.X];  
                if obj.configs.get('zscore')
                    XallCombined = zscore(XallCombined);
                end
                YCombined = [source.Y ; target.Y];
                typeCombined = [source.type ; target.type];
                if exist('savedData','var') && isfield(savedData,'W')
                    W = savedData.W;
                else
                    W = Kernel.Distance(XallCombined);                    
                    if exist('savedData','var')
                        savedData.W = W;
                    end
                end
                W = DistanceMatrix(W,YCombined,typeCombined);
            end            
            [W,Ys,Yt,typeCombined,isTarget] = W.prepareForSourceHF();                      
            if ~obj.configs.get('useSourceForTransfer')                
                W = W(isTarget,isTarget);
                typeCombined = typeCombined(isTarget);
                Ys = zeros(0,size(Ys,2));
                isTarget = isTarget(isTarget);            
            end
            if isKey(obj.configs,'sigma')
                error('Why are we using this sigma?');
                sigma = obj.configs.get('sigma');
            else
                [sigma,~,~] = GraphHelpers.autoSelectSigma(W,[Ys;Yt],isTarget,useMeanSigma,useHF,typeCombined);            
            end
            metadata.sigma = sigma;
            rerunLOOCV = 1;
            if rerunLOOCV
                W = Helpers.distance2RBF(W,sigma);                
                if exist('savedData','var')
                    [score, percCorrect,Ypred,Yactual,labeledTargetScores,savedData] = GraphHelpers.LOOCV(W,...
                        [],[Ys ; Yt],useHF,typeCombined,savedData,obj.configs);
                else
                    [score, percCorrect,Ypred,Yactual,labeledTargetScores] = GraphHelpers.LOOCV(W,...
                        [],[Ys ; Yt],useHF,typeCombined);
                end
            else
                display('TransferMeasure: Not rerunning LOOCV');
                labeledTargetScores = [];
                Ypred = [];
                Yactual = [];
            end
            if obj.configs.get('useSoftLoss')
                val = score;                                
            else
                val = percCorrect;                
            end          
            if ~obj.configs.get('quiet')
                obj.displayMeasure(val);
            end
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

