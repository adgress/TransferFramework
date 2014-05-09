classdef TransferMeasure < handle
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
                Y = [source.Y ; target.Y];
                type = [ones(numel(source.Y),1)*Constants.SOURCE ;...
                    ones(numel(target.Y),1)*Constants.TARGET_TRAIN];
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
            sigma = GraphHelpers.autoSelectSigma(W,[Ys;Yt],isTarget,useCV,useHF,type);
            W = Helpers.distance2RBF(W,sigma);
            addpath(genpath('libraryCode'));

            [score, percCorrect,Ypred,Yactual] = GraphHelpers.LOOCV(W,...
                [],[Ys ; Yt],useHF,type);
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

        function [displayName] = getDisplayName(obj)
            displayName = obj.getResultFileName(',');
        end
        function [name] = getResultFileName(obj,delim)
             if nargin < 2
                delim = '_';                
             end
            name = obj.getPrefix();
            params = obj.getNameParams();            
            for i=1:numel(params)
                n = params{i};
                if isKey(obj.configs,n)
                    v = obj.configs(n);
                else
                    v = '0';
                    display([n ' Missing: setting to 0']);
                end
                if ~isa(v,'char')
                    v = num2str(v);
                end
                name = [name delim n '=' v];
            end
            name = ['/TM/' name];
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {'transferMethodClass'};
        end
        function [] = displayMeasure(obj,val)
            display([obj.getPrefix() ' TransferMeasure: ' num2str(val)]); 
        end
    end
    methods(Static)
        function [name] = GetDisplayName(measureName,configs)
            measureFunc = str2func(measureName);
            measureObject = measureFunc(configs);
            name = measureObject.getDisplayName();
        end
    end
    methods(Abstract)
        [val,perLabelMeasures,metadata] = computeMeasure(obj,source,target,options)
        [name] = getPrefix(obj)       
    end
    
end

