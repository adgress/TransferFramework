classdef VisualizationConfigs < Configs
    %VISUALIZATIONCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = VisualizationConfigs()
            obj = obj@Configs();            
            obj.configsStruct.showCorrelation = false;
            obj.configsStruct.showTrain = false;
            obj.configsStruct.showTest = true;
            obj.configsStruct.showLegend = true;
            obj.configsStruct.showTable = false;
            obj.configsStruct.tableColumns = {'Relative Transfer Acc','Our Measure','Our Measure Just Targets'};                                              
            obj.configsStruct.showPostTransferMeasures = true;
            obj.configsStruct.showPreTransferMeasures = true;
            obj.configsStruct.showRelativePerformance = false;
            obj.configsStruct.showRelativeMeasures = false;
            obj.configsStruct.numColors = 4;
            obj.configsStruct.axisToUse = [];
            obj.configsStruct.relativeType = Constants.RELATIVE_PERFORMANCE;
            obj.configsStruct.xAxisField = 'numLabeledPerClass';
            obj.configsStruct.xAxisDisplay = 'Target Labels Per Class';
            obj.configsStruct.yAxisDisplay = 'Accuracy';
            if obj.get('showRelativePerformance')
                if obj.get('showCorrelations')
                    obj.configsStruct.relativeType = Constants.CORRELATION;
                    obj.configsStruct.yAxisDisplay = 'Measure-Accuracy Correlation';
                else
                    obj.configsStruct.relativeType = Constants.DIFF_PERFORMANCE;
                    obj.configsStruct.yAxisDisplay = 'Measure/Accuracy Difference';
                    %{
                    obj.configsStruct.relativeType = Constants.RELATIVE_PERFORMANCE;
                    obj.configsStruct.yAxisDisplay = 'Measure/Accuracy';
                    %}                    
                end
            end
            
            fileNames = {};            
            showKNN = true;            
            if ~showKNN                        
                if ~showRelativePerformance
                    fileNames{end+1} = 'TO_LLGC.mat';
                end
                fileNames{end+1} = 'S+T_LLGC.mat';
            else
                fileNames{end+1} = 'TO_kNN-k=1.mat';
                fileNames{end+1} = 'S+T_kNN-k=1.mat';        
            end
            fileNames{end+1} = 'TM/CT_S+T.mat';            
            
            obj.makePlotConfigs(fileNames);                                                                        
            
            obj.configsStruct.resultQueries = {};
        end
        
        function [] = setTommasi(obj)
            obj.configsStruct.datasetToViz = Constants.TOMMASI_DATA;
            obj.configsStruct.dataSet = 'tommasi_data';
            obj.configsStruct.prefix = 'results_tommasi/tommasi_data';
             %{
            sourceData = {'10', '15', '23','25'};
            targetData = {'10', '15', '23','25'};
            %}
            obj.configsStruct.targetData = {[10 15]};
            sourceLabels = [23 25 26 30 41];
            sourceData = Helpers.MakeCrossProductNoDupe(sourceLabels,sourceLabels);
            obj.configsStruct.sourceData = sourceData;
            obj.configsStruct.numSubplotRows = 5;
            obj.configsStruct.numSubplotCols = 5;
        end
        
        function [] = setCV(obj)
            %prefix = 'results/CV-small_10-13';
            %prefix = 'results/CV-small';
            %prefix = 'results/CV-small_numLabeledPerClass';        
            obj.configsStruct.sourceData = {'A','C','D','W'};
            obj.configsStruct.targetData = {'A','C','D','W'};
            obj.configsStruct.numSubplotRows = numel(sourceData);
            obj.configsStruct.numSubplotCols = numel(targetData);
        end
        
        function [] = setNumSourcePerClass(obj)
            obj.configsStruct.xAxisField = 'numSourcePerClass';
            obj.configsStruct.xAxisDisplay = 'Num Source Instances';
        end
        
        function [] = makePlotConfigs(obj,fileNames)
            measureLossConfigs = Configs();    
            measureLossJustTarget = SoftFUMeasureLoss(measureLossConfigs);
            measureLossJustTarget.set('justTarget',true);
            measureLossAll = FUMeasureLoss(measureLossConfigs);
            measureLossAll.set('justTarget',true); 
            
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile','TO_LLGC.mat');
            basePlotConfigs.set('measureLoss',measureLossAll);
            
            plotConfigs = {};
            for fileIdx=1:length(fileNames)
                configs = basePlotConfigs.copy();
                configs.set('resultFileName',fileNames{fileIdx});
                plotConfigs{fileIdx} = configs;
            end
            configs = basePlotConfigs.copy();
            configs.set('measureLoss',measureLossJustTarget);
            configs.set('resultFileName','TM/CT_S+T.mat');
            plotConfigs{end+1} = configs;
            obj.configsStruct.plotConfigs = plotConfigs;
        end
        
        function [] = setRepair(obj)
            numIterations = 3;
            percToRemove = '0.035';
            fixSigma=1;
            saveInv=1;
            fileNames = {};
            %fileNames{end+1} = 'TR_strategy=Random_percToRemove=0.1_numIterations=3_useECT=1_fixSigma=1-S+T-LLGC';
            %fileNames{end+1} = 'TR_strategy=NNPrune_percToRemove=0.1_numIterations=3_useECT=1_fixSigma=1_saveINV=0-S+T-LLGC';
            %fileNames{end+1} = 'TR_strategy=NNPrune_percToRemove=0.1_numIterations=3_useECT=0_fixSigma=1_saveINV=1-S+T-LLGC';
            %fileNames{end+1} = 'TR_strategy=None_percToRemove=0.1_numIterations=3_useECT=0_fixSigma=1_saveINV=1-S+T-LLGC';
            fileNames{end+1} = 'TR_strategy=Exhaustive_percToRemove=%s_numIterations=%d_useECT=0_fixSigma=%d_saveINV=%d-S+T-LLGC';
            for sourceIdx=1:length(fileNames)
                fileNames{sourceIdx} = ['REP/LLGC/' sprintf(fileNames{sourceIdx},percToRemove,numIterations,fixSigma,saveInv) '.mat'] ;
            end
            options.yAxisDisplay = 'Measure/Accuracy';
            options.xAxisDisplay = 'Num Repair Iterations';
        end
        
        function [] = setShowTables(obj)            
            obj.configsStruct.tableColumns = tableColumns;
            obj.configsStruct.table = uitable('RowName',[],'units','normalized',...
                'pos',[(sourceIdx-1)/4 (4-targetIdx)/4 .25 .25]);
            obj.configsStruct.resultQueries = {Helpers.MakeQuery('numLabeledPerClass',{2})};
        end
    end
    
end

