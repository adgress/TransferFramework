classdef VisualizationConfigs < Configs
    %VISUALIZATIONCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        CONF_INTERVAL_STD = 1
        CONF_INTERVAL_BINOMIAL = 2
    end
    
    methods
        function obj = VisualizationConfigs()
            obj = obj@Configs();      
            obj.configsStruct.confidenceInterval = VisualizationConfigs.CONF_INTERVAL_STD;
            obj.configsStruct.axisToUse = [0 10 0 1.1];
            obj.configsStruct.showLegend = true;
            obj.configsStruct.showTable = false;
            obj.configsStruct.showPlots = true;
            obj.configsStruct.tableColumns = {'Relative Transfer Acc','Our Measure','Our Measure Just Targets'};                                              
            obj.configsStruct.sizeField = 'numLabeledPerClass';
            obj.configsStruct.xAxisField = 'numLabeledPerClass';
            obj.configsStruct.xAxisDisplay = 'Target Labels Per Class';
            obj.configsStruct.yAxisDisplay = 'Accuracy';
            obj.configsStruct.showXAxisLabel = true;
            obj.configsStruct.showYAxisLabel = true;  
            obj.set('autoAdjustXAxis',true);
            obj.set('autoAdjustYAxis',false);
            
            obj.configsStruct.resultQueries = {};
            obj.configsStruct.measure = Measure(Configs());
            
            c.configsStruct.showPostTransferMeasures = false;
            c.configsStruct.showPreTransferMeasures = false;
            c.configsStruct.showRelativePerformance = false;
            c.configsStruct.showRelativeMeasures = false;
            c.configsStruct.showSoftMeasures = false;
            c.configsStruct.showHardMeasures = false;
            c.configsStruct.showLLGCMeasure = false;
        end        
        
        function [] = setTommasi(obj)
            obj.configsStruct.datasetToViz = Constants.TOMMASI_DATA;
            obj.configsStruct.dataSet = 'tommasi_data';
            obj.configsStruct.prefix = 'results_tommasi/tommasi_data';
            obj.configsStruct.numSubplotRows = 5;
            obj.configsStruct.numSubplotCols = 5;                        
            [obj.configsStruct.targetData,obj.configsStruct.sourceData] = ...
                ProjectConfigs.MakeDomains();            
        end
        
        function [] = setCV(obj, sourceNoise)
            sourceData = {'A','C','D','W'};
            targetData = {'A','C','D','W'};
            obj.configsStruct.sourceData = sourceData;
            obj.configsStruct.targetData = targetData;
            obj.configsStruct.numSubplotRows = numel(sourceData);
            obj.configsStruct.numSubplotCols = numel(targetData);
            obj.configsStruct.datasetToViz = Constants.CV_DATA;
            obj.configsStruct.prefix = 'results/CV-small';
            if sourceNoise > 0
                obj.configsStruct.prefix = ['results/CV-small-' num2str(sourceNoise)];
            end
        end
   
        function [] = setShowTables(obj)            
            obj.configsStruct.tableColumns = tableColumns;
            obj.configsStruct.table = uitable('RowName',[],'units','normalized',...
                'pos',[(sourceIdx-1)/4 (4-targetIdx)/4 .25 .25]);
            obj.configsStruct.resultQueries = {Helpers.MakeQuery('numLabeledPerClass',{2})};
        end
    end
    
end

