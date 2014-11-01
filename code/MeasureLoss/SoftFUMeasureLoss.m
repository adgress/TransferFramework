classdef SoftFUMeasureLoss < FUMeasureLoss
    %SOFTFUMEASURELOSS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = SoftFUMeasureLoss(configs)
            obj = obj@FUMeasureLoss(configs);
        end
        
        function [value] = computeLoss(obj, measureStruct)
            value = computeLoss@FUMeasureLoss(obj,measureStruct);                        
            if isfield(measureStruct.measureMetadata,'fuSourceProp')
                '';
            end
        end
        
        function [value] = getFUScore(obj,fuSource,fuTarget,measureResults)
            if obj.configs.get('justTarget')                
                isTarget = measureResults.dataType == Constants.TARGET_TRAIN | ...
                    measureResults.dataType == Constants.TARGET_TEST;
                fuSource = fuSource(isTarget,:);
                fuTarget = fuTarget(isTarget,:);
            end
            values = zeros(size(fuSource,1),1);
            for idx=1:size(fuSource,1)
                si = fuSource(idx,:);
                ti = fuTarget(idx,:);
                maxDim = max(length(si),length(ti));
                si = [si zeros(1,maxDim-length(si))];
                ti = [ti zeros(1,maxDim-length(ti))];
                values(idx) = 1 - pdist2(si,ti,'cityblock')/2;
            end            
            value = mean(values);
            if isinf(value) || isnan(value)
                display('SoftFUMeasureLoss: nan or inf!');
            end
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'SoftFUML';
        end
        function [v] = discreteKLDivergence(obj,x,y)
            v = 0;
            for idx=1:length(x)
                t = x(idx)*log(x(idx)/y(idx));                
                v = v + t;
            end
        end
    end
    
end

