classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();
            c = ProjectConfigs.Create();
            obj.configsStruct.paramsToVary={'sigmaScale','k','alpha'};
            obj.configsStruct.sigmaScale = num2cell(c.sigmaScale);
            obj.configsStruct.k = num2cell(c.k);
            obj.configsStruct.alpha = num2cell(c.alpha);
            obj.configsStruct.experimentConfigsClass=LLGCMainConfigs();                        
        end        
    end
end

