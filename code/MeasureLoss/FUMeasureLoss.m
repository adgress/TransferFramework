classdef FUMeasureLoss < MeasureLoss
    %FUMEASURELOSS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = FUMeasureLoss(configs)
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@MeasureLoss(configs);
        end
        
        function [value] = computeLoss(obj, measureStruct)
            value = computeLoss@MeasureLoss(obj,measureStruct);                        
            if isfield(measureStruct.measureMetadata,'fuSourceProp')
                fuSource = full(measureStruct.measureMetadata.fuSourceProp);
                fuTarget = full(measureStruct.measureMetadata.fuTargetProp);
                assert(~isempty(fuSource) && ~isempty(fuTarget));
                value = obj.getFUScore(fuSource,fuTarget,measureStruct.measureResults);
                valueKLD = obj.getKLD(fuSource,fuTarget,measureStruct.measureResults);
                value = valueKLD;
            else
                error('Why no fuSourceProp?');
                fu = measureStruct.measureResults.labeledTargetScores;
                yActual = measureStruct.measureResults.yActual;
                labelMat = Helpers.createLabelMatrix(yActual);
                scores = fu.*labelMat;
                value = sum(scores(:))/nnz(labelMat);
            end
        end
        function [value] = getKLD(obj,fuSource,fuTarget,measureResults)
            isTarget = measureResults.dataType == Constants.TARGET_TRAIN | ...
                    measureResults.dataType == Constants.TARGET_TEST;
            scores = [];
            for i=1:size(fuSource,2)
                p = fuTarget(:,i);
                q = fuSource(:,i);                
                if obj.get('justTarget')
                    p = p(isTarget);
                    q = q(isTarget);
                end
                N = length(p);
                pq = (1/N)*p.*log(p./q);
                pq(isnan(pq)) = 0;
                qp = (1/N)*q.*log(q./p);
                qp(isnan(qp)) = 0;
                tp = sum(pq);
                tq = sum(qp);
                scores(i) = .5*tp + .5*tq;
                assert(~isnan(scores(i)));
            end
            %If score is 0 then the label isn't used
            value = mean(scores(find(scores)));
            assert(~isnan(value));
        end
        function [value] = getFUScore(obj,fuSource,fuTarget,measureResults)
            [~,sourcePropPred] = max(fuSource,[],2);
            [~,targetPropPred] = max(fuTarget,[],2);
            if obj.get('justTarget')
                isTarget = measureResults.dataType == Constants.TARGET_TRAIN | ...
                    measureResults.dataType == Constants.TARGET_TEST;
                sourcePropPred = sourcePropPred(isTarget);
                targetPropPred = targetPropPred(isTarget);
            end
            value = sum(sourcePropPred==targetPropPred)/length(sourcePropPred);
            assert(~isnan(value));
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'FUML';
        end

        function [nameParams] = getNameParams(obj)
            nameParams = {'justTarget'};
        end
    end
    
end

