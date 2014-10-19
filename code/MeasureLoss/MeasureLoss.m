classdef MeasureLoss < Saveable
    %MEASURELOSS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = MeasureLoss(configs)
            obj = obj@Saveable(configs);
        end
        function [value] = computeLoss(obj, measureStruct)
            transferMeasureValueName = 'transferMeasureVal';
            if isfield(measureStruct,transferMeasureValueName)
                value = measureStruct.(transferMeasureValueName);
            end
            
            if isfield(measureStruct,'fuSourceProp')
                fuSource = measureStruct.fuSourceProp;
                fuTarget = measureStruct.fuTargetProp;
                assert(~isempty(fuSource) && ~isempty(fuTarget));
                value = obj.getFUScore(fuSource,fuTarget);
            end
        end
        function [value] = getFUScore(obj,fuSource,fuTarget)
            [~,sourcePropPred] = max(fuSource,[],2);
            [~,targetPropPred] = max(fuTarget,[],2);
            value = sum(sourcePropPred==targetPropPred)/length(sourcePropPred);
        end
        function [prefix] = getPrefix(obj)
            prefix = 'ML';
        end

        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end

        function [d] = getDirectory(obj)
            error('not necessary');
        end
    end    
end

