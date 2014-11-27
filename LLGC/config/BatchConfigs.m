classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();
            obj.configsStruct.paramsToVary={'sigmaScale','k','alpha'};
            obj.configsStruct.sigmaScale = num2cell(ProjectConfigs.sigmaScale);
            obj.configsStruct.k = num2cell(ProjectConfigs.k);
            obj.configsStruct.alpha = num2cell(ProjectConfigs.alpha);
            obj.configsStruct.experimentConfigsClass=LLGCMainConfigs();
            
            obj.configsStruct.makeSubDomains = true;
        end        
    end
end

