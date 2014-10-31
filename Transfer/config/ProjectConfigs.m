classdef ProjectConfigs
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function [c] = VisualizationConfigs()
            c = VisualizationConfigs();
            c.setTommasi();            
        end
        
        function [c] = BatchConfigs()
            c = BatchConfigs();
            c.setTommasiData();
            c.setLLGCConfigs();
            %c.setMeasureConfigs();
        end
        
        function [c] = SplitConfigs()
            c = SplitConfigs();
            c.setTommasi();
        end
    end
    
end

