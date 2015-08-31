classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();
            c = ProjectConfigs.Create();            
            obj.configsStruct.mainConfigs=ITSMainConfigs();
            obj.configsStruct.overrideConfigs = {Configs()};
        end                
    end
    methods(Static)                
        
    end
end

