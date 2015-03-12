classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();
            c = ProjectConfigs.Create();
            %obj.configsStruct.paramsToVary={'sigmaScale','k','alpha'};
            obj.configsStruct.paramsToVary={'sigmaScale','k'};
            obj.configsStruct.sigmaScale = num2cell(c.sigmaScale);
            obj.configsStruct.k = num2cell(c.k);
            obj.configsStruct.alpha = c.alpha;
            obj.configsStruct.mainConfigs=SepLLGCMainConfigs();    
            obj.configsStruct.overrideConfigs = {Configs()};
        end        
    end
end

