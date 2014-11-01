classdef ProjectConfigs
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        numTarget = 2;
        numSource = 5;
        tommasiLabels = [10 15 23 25 26 30 41 56 57];
        cvLabels = 1:10;
        dataSet = Constants.CV_DATA
    end
    
    methods(Static)                
        function [c] = BatchConfigs()
            c = BatchConfigs();
            if ProjectConfigs.dataSet == Constants.TOMMASI_DATA
                c.setTommasiData();
            end
            c.setLLGCConfigs();
            %c.setCTMeasureConfigs();
            %c.setLLGCMeasureConfigs();
            c.get('experimentConfigsClass').configsStruct.labelsToUse = 1:10;
        end
        
        function [c] = SplitConfigs()
            c = SplitConfigs();
            if ProjectConfigs.dataSet == Constants.TOMMASI_DATA
                c.setTommasi();
            else
                c.setCVSmall();
            end
        end
        
        function [c] = VisualizationConfigs()
            c = VisualizationConfigs();
            if ProjectConfigs.dataSet == Constants.TOMMASI_DATA
                c.setTommasi();           
            else
                c.setCV();
            end
            
            c.configsStruct.showKNN = false;
            c.configsStruct.showSoftMeasures = true;
            c.configsStruct.showHardMeasures = true;
            c.configsStruct.showLLGCMeasure = true;
            c.configsStruct.showRelativePerformance = true;
            c.makePlotConfigs();            
        end
                
        function [labelProduct] = MakeLabelProduct()
            numTargetLabels = ProjectConfigs.numTarget;
            numSourceLabels = ProjectConfigs.numSource;
            targetlabels = ProjectConfigs.tommasiLabels(1:numTargetLabels);
            sourceLabels = ProjectConfigs.tommasiLabels(numTargetLabels+1:numTargetLabels+numSourceLabels);
            targetDomains = Helpers.MakeCrossProductOrdered(targetlabels,targetlabels);
            sourceDomains = Helpers.MakeCrossProductNoDupe(sourceLabels,sourceLabels);
            labelProduct = Helpers.MakeCrossProduct(targetDomains,sourceDomains);
        end
        
        function [targetDomains,sourceDomains] = MakeDomains()
            numTargetLabels = ProjectConfigs.numTarget;
            numSourceLabels = ProjectConfigs.numSource;
            
            targetlabels = ProjectConfigs.tommasiLabels(1:numTargetLabels);
            targetDomains = Helpers.MakeCrossProductOrdered(targetlabels,targetlabels);
            
            sourceLabels = ProjectConfigs.tommasiLabels(numTargetLabels+1:numTargetLabels+numSourceLabels);            
            sourceDomains = Helpers.MakeCrossProductNoDupe(sourceLabels,sourceLabels);           
        end
    end
    
end

