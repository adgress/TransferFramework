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
            switch c.dataSet
                case Constants.ITS_DATA
                    %obj.set('overrideConfigs',BatchConfigs.makeITSOverrideConfigs());
                otherwise                    
                    error('unknown data set');
            end
        end                
    end
    methods(Static)                
        
    end
end

