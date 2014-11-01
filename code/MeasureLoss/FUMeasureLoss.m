classdef FUMeasureLoss < MeasureLoss
    %FUMEASURELOSS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = FUMeasureLoss(configs)
            obj = obj@MeasureLoss(configs);
        end
        
        function [value] = computeLoss(obj, measureStruct)
            value = computeLoss@MeasureLoss(obj,measureStruct);                        
            if isfield(measureStruct.measureMetadata,'fuSourceProp')
                fuSource = full(measureStruct.measureMetadata.fuSourceProp);
                fuTarget = full(measureStruct.measureMetadata.fuTargetProp);
                assert(~isempty(fuSource) && ~isempty(fuTarget));
                value = obj.getFUScore(fuSource,fuTarget,measureStruct.measureResults);
            else
                fu = measureStruct.measureResults.labeledTargetScores;
                yActual = measureStruct.measureResults.yActual;
                labelMat = Helpers.createLabelMatrix(yActual);
                scores = fu.*labelMat;
                value = sum(scores(:))/nnz(labelMat);
            end
        end
        function [value] = getFUScore(obj,fuSource,fuTarget,measureResults)
            [~,sourcePropPred] = max(fuSource,[],2);
            [~,targetPropPred] = max(fuTarget,[],2);
            if obj.configs.get('justTarget')
                isTarget = measureResults.dataType == Constants.TARGET_TRAIN | ...
                    measureResults.dataType == Constants.TARGET_TEST;
                sourcePropPred = sourcePropPred(isTarget);
                targetPropPred = targetPropPred(isTarget);
            end
            value = sum(sourcePropPred==targetPropPred)/length(sourcePropPred);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'FUML';
        end

        function [nameParams] = getNameParams(obj)
            nameParams = {'justTarget'};
        end
    end
    
end

