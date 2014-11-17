classdef ProjectConfigs
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)        
    end
    
    methods(Static)                
        function [c] = BatchConfigs()
            c = BatchConfigs();
            c.get('experimentConfigsClass').configsStruct.labelsToUse = 1:2;
        end
        
        function [c] = SplitConfigs()
            c = SplitConfigs();            
        end
        
        function [c] = VisualizationConfigs()
            c = VisualizationConfigs();
            if ProjectConfigs.dataSet == Constants.TOMMASI_DATA
                c.setTommasi();           
            else
                c.setCV();
                %c.configsStruct.prefix = 'results/CV-small_10classes';
            end
            
            c.configsStruct.showKNN = false;
            c.configsStruct.showSoftMeasures = true;
            c.configsStruct.showHardMeasures = true;
            c.configsStruct.showLLGCMeasure = true;
            c.configsStruct.showRelativePerformance = false;
            c.configsStruct.numColors = 5;
            
            %c.configsStruct.axisToUse = [1.5 2.5 0 .3];            
            c.configsStruct.vizMultiple = true;
            %c.makePlotConfigs();            
            
            if c.c.vizMultiple
                c.delete('axisToUse');
                c.configsStruct.showSoftMeasures = false;
                c.makeMultiMeasurePlotConfigs();
            end
        end
    end
    
end

