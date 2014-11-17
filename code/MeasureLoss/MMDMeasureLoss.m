classdef MMDMeasureLoss < FUMeasureLoss
    %MMDMEASURELOSS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = MMDMeasureLoss(configs)
            obj = obj@FUMeasureLoss(configs);
        end
        
        function [value] = getFUScore(obj,fuSource,fuTarget,measureResults)
            if obj.configs.get('justTarget')                
                isTarget = measureResults.dataType == Constants.TARGET_TRAIN | ...
                    measureResults.dataType == Constants.TARGET_TEST;
                fuSource = fuSource(isTarget,:);
                fuTarget = fuTarget(isTarget,:);
            end
            [~,predSource] = max(fuSource,[],2);
            [~,predTarget] = max(fuTarget,[],2);
            assert(length(measureResults.sources{1}) == 1);
            targetX = measureResults.sampledTrain.X;
            %sourceX = measureResults.sources{1}.X;
            numLabels = size(fuSource,2);
            score = zeros(numLabels,1);
            for i=1:numLabels
                sourcePred_i = find(predSource == i);
                targetPred_i = find(predTarget == i);
                if isempty(sourcePred_i) || isempty(targetPred_i);
                    score(i) = nan;
                    continue;
                end
                assert(~isempty(sourcePred_i) && ~isempty(targetPred_i));                
                targetX_i = targetX(targetPred_i,:); 
                sourceX_i = targetX(sourcePred_i,:);               
                options = DMMD_Ustat_initialization(1);
                score(i) = DMMD_Ustat_estimation(targetX_i',sourceX_i',options);
                %{
                options = DKL_kNN_k_initialization(1);
                score(i) = DKL_kNN_k_estimation(targetX_i',sourceX_i',options);
                %}
            end
            score(isnan(score)) = [];
            value = 1 - mean(score);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'SoftFUML';
        end
    end
    
end

