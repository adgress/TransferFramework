classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();
            obj.configsStruct.paramsToVary={'sigmaScale','k'};
            obj.configsStruct.sigmaScale = num2cell(ProjectConfigs.sigmaScale);
            obj.configsStruct.k = num2cell(ProjectConfigs.k);
            obj.configsStruct.experimentConfigsClass=LLGCMainConfigs();
        end        
    end
end

