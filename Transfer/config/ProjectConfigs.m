classdef ProjectConfigs < ProjectConfigsBase
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)        
        cvLabels = 1:10;
        %dataSet = Constants.CV_DATA
        dataSet = Constants.TOMMASI_DATA
        
        instance = ProjectConfigs.CreateSingleton()
        
        experimentSetting = 1
        numLabeled = 4:2:20
        
        EXPERIMENT_LLGC = 1
        EXPERIMENT_REPAIR = 2
        EXPERIMENT_MEASURE = 3
        
        vizMeasureCorrelation = false
        
        sourceNoise = .0;
    end
    
    properties
        sigmaScale
        alpha
        numSource
        numTarget
        tommasiLabels
    end
    
    methods(Static)    
        function [c] = CreateSingleton()
            c = ProjectConfigs();
            c.sigmaScale = .2;
            c.alpha = .9;
        end
        function [c] = Create()
            c = ProjectConfigs.instance;
        end
        function [c] = BatchConfigs()
            c = BatchConfigs();
            if ProjectConfigs.dataSet == Constants.TOMMASI_DATA
                c.setTommasiData();
            else
                c.get('experimentConfigsClass').configsStruct.labelsToUse = 1:10;
            end
            if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_LLGC
                c.setLLGCConfigs();
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_REPAIR
                c.setRepairConfigs(ProjectConfigs.sourceNoise);
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_MEASURE
                c.setMeasureConfigs();
            else
                error('');
            end
            %c.setCTMeasureConfigs();
            %c.setLLGCMeasureConfigs();            
        end
        
        function [c] = SplitConfigs()
            c = SplitConfigs();
            if ProjectConfigs.dataSet == Constants.TOMMASI_DATA
                c.setTommasi();
            else
                c.setCVSmall(ProjectConfigs.sourceNoise);
            end
        end
        
        function [c] = VisualizationConfigs()
            c = VisualizationConfigs();
            if ProjectConfigs.dataSet == Constants.TOMMASI_DATA
                c.setTommasi();           
            else
                c.setCV(ProjectConfigs.sourceNoise);
                %c.configsStruct.prefix = 'results/CV-small_10classes';
            end
            
            c.configsStruct.showKNN = false;
            c.configsStruct.showSoftMeasures = true;
            c.configsStruct.showHardMeasures = true;
            c.configsStruct.showLLGCMeasure = true;
            c.configsStruct.numColors = 5;
            
            %c.configsStruct.axisToUse = [1.5 2.5 0 .3];            
            c.configsStruct.vizMultiple = false;
            %c.makePlotConfigs();            
            
            if ProjectConfigs.experimentSetting == ...
                    ProjectConfigs.EXPERIMENT_REPAIR
                [plotConfigs,legend] = ProjectConfigs.MakeRepairPlotConfigs();                
                c.configsStruct.sizeField = 'numLabeledPerClass';
                c.configsStruct.xAxisField = 'numLabeledPerClass';
                c.configsStruct.xAxisDisplay = 'Repair Iterations';
                c.configsStruct.yAxisDisplay = 'Accuracy';
                c.configsStruct.showRepair = true;                                  
            elseif c.c.vizMultiple
                c.delete('axisToUse');
                c.configsStruct.showSoftMeasures = false;
                c.makeMultiMeasurePlotConfigs();
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_MEASURE
                [plotConfigs,legend] = ProjectConfigs.MakeMeasurePlotConfigs();                
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_LLGC
                %[plotConfigs,legend] = ProjectConfigs.MakeMeasurePlotConfigs();
                files = {};
                legend = {};
                files{end+1} = 'TO_LLGC-sigmaScale=0.2-alpha=0.9.mat';
                legend{end+1} = 'LLGC';

                files{end+1} = 'S+T_LLGC-sigmaScale=0.2-alpha=0.9.mat';
                legend{end+1} = 'Transfer LLGC';
                plotConfigs = {};
                for i=1:length(files)
                    p = Configs();
                    %measureLoss = FUMeasureLoss();
                    %measureLoss.set('justTarget',true);
                    %c.set('measureLoss',measureLoss);
                    p.set('resultFileName',files{i});
                    plotConfigs{end+1} = p;
                end
            end
            c.set('plotConfigs',plotConfigs);
            c.set('legend',legend);
            c.set('showLegend',true);
                
            c.set('vizMeasureCorrelation',ProjectConfigs.vizMeasureCorrelation);
            
            %Indicies of displayVals to use for correlation between
            %transfer measure and transfer performance
            c.set('relativeValues',{[1 3],[2 3]});
            relativeLegend = {...
                'Transfer Measure Correlation', ...
                'Cross Validation  Correlation'
            };
            c.set('relativeScale',[-1,1]);
            c.set('relativeLegend',relativeLegend);
        end
          
        function [plotConfigs,legend] = MakeMeasurePlotConfigs()
            basePlotConfigs = Configs();
            %{
            basePlotConfigs.set('baselineFile',...
                'TR-strategy=None_S+T_LLGC-sigmaScale=0.2-alpha=0.9.mat');
            %}
            files = {};
            legend = {};
            files{end+1} = 'TM/CT-saveFeatures=1_S+T.mat';
            legend{end+1} = 'FU Measure Loss';
            
            files{end+1} = 'TM/LLGC_S+T.mat';
            legend{end+1} = 'LLGC Cross Validation Error';
            
            %{
            files{end+1} = 'S+T_LLGC-sigmaScale=0.2-alpha=0.9.mat';
            legend{end+1} = 'Transfer LLGC';
            files{end+1} = 'TO_LLGC-sigmaScale=0.2-alpha=0.9.mat';
            legend{end+1} = 'Target Only LLGC';
            %}
            files{end+1} = 'S+T_LLGC-sigmaScale=0.2-alpha=0.9.mat';
            legend{end+1} = 'Relative Transfer Performance';
            plotConfigs = {};
            for i=1:length(files)
                c = basePlotConfigs.copy();
                measureLoss = FUMeasureLoss();
                measureLoss.set('justTarget',true);
                c.set('measureLoss',measureLoss);
                c.set('resultFileName',files{i});
                plotConfigs{end+1} = c;
            end
            %Use MeasureLoss for LLGC measure
            plotConfigs{2}.set('measureLoss',MeasureLoss(basePlotConfigs.copy()));
            
            plotConfigs{3}.set('baselineFile','TO_LLGC-sigmaScale=0.2-alpha=0.9.mat');
            plotConfigs{3}.set('showRelativePerformance',true);
        end
        
        function [plotConfigs,legend] = MakeRepairPlotConfigs()
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',...
                'TR-strategy=None_S+T_LLGC-sigmaScale=0.2-alpha=0.9.mat');
            files = {};
            legend = {};
            files{end+1} = 'TR-strategy=None_S+T_LLGC-sigmaScale=0.2-alpha=0.9.mat';                        
            legend{end+1} = 'Strategy = None';
            files{end+1} = 'TR-strategy=Exhaustive_S+T_LLGC-sigmaScale=0.2-alpha=0.9.mat';
            legend{end+1} = 'Stategy = Exhaustive';
            plotConfigs = {};
            for i=1:length(files)
                c = basePlotConfigs.copy();
                c.set('resultFileName',files{i});
                plotConfigs{end+1} = c;
            end
        end                
    end
    
end

