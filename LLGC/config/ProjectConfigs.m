classdef ProjectConfigs
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
         %sigmaScale = .2:.2:1;
         sigmaScale = .2
         k=inf
         alpha=.9
         labelsToUse = [1 2]
         classNoise = .2
         numLabeledPerClass=10
         %labelsTouse = [3 5 8 9]
         %{
         k = [10,30,60,120, inf];
         alpha = .1:.2:.9;
         %}
    end
    
    methods(Static)                
        function [c] = BatchConfigs()
            c = BatchConfigs();
            c.get('experimentConfigsClass').configsStruct.labelsToUse = ProjectConfigs.labelsToUse;
            %c.get('experimentConfigsClass').setUSPSSmall();
            c.get('experimentConfigsClass').setCOIL20();
        end
        
        function [c] = SplitConfigs()
            c = SplitConfigs();            
            %c.setUSPSSmall();
            c.setCOIL20();
        end
        
        function [c] = VisualizationConfigs()
            c = VisualizationConfigs();                                           
            c.configsStruct.showPostTransferMeasures = false;
            c.configsStruct.showPreTransferMeasures = false;
            c.configsStruct.showRelativePerformance = false;
            c.configsStruct.showRelativeMeasures = false;
            c.configsStruct.showSoftMeasures = false;
            c.configsStruct.showHardMeasures = false;
            c.configsStruct.showLLGCMeasure = false;
            c.configsStruct.plotConfigs = ProjectConfigs.makePlotConfigs();
            c.configsStruct.numColors = length(c.c.plotConfigs); 
        end
        
        function [plotConfigs] = makePlotConfigs()  
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};
            %for k=ProjectConfigs.k
                for s=ProjectConfigs.sigmaScale
                    methodResultsFileNames{end+1} = ...
                        ['LLGC-sigmaScale=' num2str(s) '-k=%s.mat'];
                end                   
            %end
            
            plotConfigs = {};
            for fileIdx=1:length(methodResultsFileNames)
                configs = basePlotConfigs.copy();
                configs.set('resultFileName',methodResultsFileNames{fileIdx});
                plotConfigs{end+1} = configs;
            end
        end
    end
    
end

