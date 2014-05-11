classdef TransferMeasure < Saveable
    %TRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configs
    end
    
    methods
        function obj = TransferMeasure(configs)
            obj.configs = configs;
        end
        
        function [score,percCorrect,Ypred,Yactual,perLabelMeasures,val] = ...
                computeGraphMeasure(obj,source,target,options,...
                useHF)
            targetWithLabels = target.Y > 0;
            if sum(targetWithLabels) == 0 || ...
                sum(targetWithLabels) <= max(target.Y)
                score = nan;
                percCorrect = nan;
                Ypred = [];
                Yactual = [];
                numLabels = max(source.Y);
                perLabelMeasures = nan(1,numLabels);
                return;
            end
            useCV = 1;
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
                W = Kernel.Distance(Xall);
                W = DistanceMatrix(W,Y,type);
            end            
            [W,Ys,Yt,type,isTarget] = W.prepareForSourceHF();                      
            if ~obj.configs('useSourceForTransfer')                
                W = W(isTarget,isTarget);
                type = type(isTarget);
                Ys = zeros(0,size(Ys,2));
                isTarget = isTarget(isTarget);            
            end
            [sigma,score,percCorrect] = GraphHelpers.autoSelectSigma(W,[Ys;Yt],isTarget,useCV,useHF,type);            
            
            rerunLOOCV = 0;
            if rerunLOOCV            
                W = Helpers.distance2RBF(W,sigma);
                addpath(genpath('libraryCode'));
                [score, percCorrect,Ypred,Yactual] = GraphHelpers.LOOCV(W,...
                    [],[Ys ; Yt],useHF,type);
            else
                display('TransferMeasure: Not rerunning LOOCV');
                perLabelMeasures = [];
                Ypred = [];
                Yactual = [];
            end
            if obj.configs('useSoftLoss')
                val = score;
                display('Not using softloss for perLabelAccuracy');
                if rerunLOOCV
                    perLabelMeasures = ...
                        Helpers.getAllLabelAccuracy(Ypred,Yactual);
                end
            else
                val = percCorrect;
                if rerunLOOCV
                    perLabelMeasures = ...
                        Helpers.getAllLabelAccuracy(Ypred,Yactual);
                end
            end
            
            obj.displayMeasure(val);
        end
        
        function [mVals,metadata] = computeMultisourceMeasure(obj,...
                sources,target,options)
            error('UPDATE!');
            mVals = zeros(numel(sources),1);
            metadata = cell(numel(sources),1);
            for i=1:numel(sources)
                s = sources{i};
                [mVals(i),metadata{i}] = computeMeasure(s,target,options);
            end
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

