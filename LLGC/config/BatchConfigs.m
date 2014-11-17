classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();            
            obj.configsStruct.dataSet={'ACD2W','ACW2D','ADW2C','CDW2A'};                        
            obj.configsStruct.paramsToVary={'sigma','k'};
            obj.configsStruct.sigma = {.1, .001, .0001};
            obj.configsStruct.k = {5, 10, 20};
            obj.configsStruct.experimentConfigsClass=LLGCMainConfigs();
            %obj.configsStruct.experimentConfigsClass.setNumLabeled();
        end        
    end
end

