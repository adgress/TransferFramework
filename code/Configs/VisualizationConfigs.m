classdef VisualizationConfigs < Configs
    %VISUALIZATIONCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        
    end
    
    methods
        function obj = VisualizationConfigs()
            obj = obj@Configs();            
            obj.configsStruct.axisToUse = [0 10 0 1.1];
            obj.configsStruct.showCorrelation = false;
            obj.configsStruct.showTrain = false;
            obj.configsStruct.showTest = true;
            obj.configsStruct.showLegend = true;
            obj.configsStruct.showTable = false;
            obj.configsStruct.tableColumns = {'Relative Transfer Acc','Our Measure','Our Measure Just Targets'};                                              
            obj.configsStruct.showPostTransferMeasures = true;
            obj.configsStruct.showPreTransferMeasures = true;
            obj.configsStruct.showRelativePerformance = false;
            obj.configsStruct.showRelativeMeasures = true;
            obj.configsStruct.numColors = 5;
            obj.configsStruct.relativeType = Constants.DIFF_PERFORMANCE ;
            obj.configsStruct.sizeField = 'numLabeledPerClass';
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
            obj.configsStruct.showKNN = false;
            obj.configsStruct.showSoftMeasures = true;
            obj.configsStruct.showHardMeasures = false;
            obj.configsStruct.showLLGCMeasure = true;
            obj.configsStruct.vizMultiple = false;
            obj.makePlotConfigs();
            
            obj.configsStruct.resultQueries = {};
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
        
        function [] = setCV(obj)
            %prefix = 'results/CV-small_10-13';
            %prefix = 'results/CV-small';
            %prefix = 'results/CV-small_numLabeledPerClass';        
            sourceData = {'A','C','D','W'};
            targetData = {'A','C','D','W'};
            obj.configsStruct.sourceData = sourceData;
            obj.configsStruct.targetData = targetData;
            obj.configsStruct.numSubplotRows = numel(sourceData);
            obj.configsStruct.numSubplotCols = numel(targetData);
            obj.configsStruct.datasetToViz = Constants.CV_DATA;
            obj.configsStruct.prefix = 'results/CV-small';
        end
        
        function [] = setNumSourcePerClass(obj)
            obj.configsStruct.xAxisField = 'numSourcePerClass';
            obj.configsStruct.xAxisDisplay = 'Num Source Instances';
        end
        
        function [softMeasureFiles,hardMeasureFiles] = getMeasureFiles(obj)
            softMeasureFiles = {'TM/CT_S+T.mat'};
            hardMeasureFiles = {'TM/CT_S+T.mat'};
            
            if obj.c.showLLGCMeasure
                llgcMeasureFile = 'TM/LLGC_S+T.mat';
                softMeasureFiles{end+1} = llgcMeasureFile;
                hardMeasureFiles{end+1} = llgcMeasureFile;                    
            end
        end
        
        function [] = makeMultiMeasurePlotConfigs(obj)                         
            measureLossConfigs = Configs();
            if obj.c.showSoftMeasures
                measureLoss = SoftFUMeasureLoss(measureLossConfigs);
            else
                measureLoss = FUMeasureLoss(measureLossConfigs);
            end
            measureLoss = MMDMeasureLoss(measureLossConfigs);
            measureLoss.set('justTarget',true);
            
            basePlotConfigs = obj.makeBasePlotConfigs();
            basePlotConfigs.set('measureLoss',measureLoss);
            if obj.c.showKNN
                basePlotConfigs.set('methodFileName','S+T_kNN-k=1.mat');
            else
                basePlotConfigs.set('methodFileName','S+T_LLGC.mat')
            end
            plotConfigs = {};
            %multiMeasureFiles = {'TM/CT_S+T.mat'};
            multiMeasureFiles = {'TM/CT-saveFeatures=1_S+T.mat'};
            if obj.c.showLLGCMeasure
                multiMeasureFiles{end+1} = 'TM/LLGC_S+T.mat';;
            end
            
            multiMeasureObjects = {MultiMeasureBest(),...
                MultiMeasureWorst(),MultiMeasureAverage()};
            for idx=1:length(multiMeasureObjects)
                configs = basePlotConfigs.copy();                
                configs.set('resultFileName',multiMeasureFiles{1});                
                configs.set('multiMeasure',multiMeasureObjects{idx});
                plotConfigs{end+1} = configs;           
            end
            for idx=1:length(multiMeasureFiles)
                configs = basePlotConfigs.copy();
                configs.set('resultFileName',multiMeasureFiles{idx});
                configs.set('multiMeasure',MultiMeasure());
                plotConfigs{end+1} = configs;           
            end
            obj.configsStruct.plotConfigs = plotConfigs;
        end
        
        function [basePlotConfigs] = makeBasePlotConfigs(obj)
            basePlotConfigs = Configs();
            if obj.c.showKNN
                basePlotConfigs.set('baselineFile','TO_kNN-k=1.mat');
            else
                basePlotConfigs.set('baselineFile','TO_LLGC.mat');
            end                        
        end
        
        function [] = makePlotConfigs(obj)                                           
            basePlotConfigs = obj.makeBasePlotConfigs();
            methodResultsFileNames = {};            
            if obj.c.showKNN
                basePlotConfigs.set('baselineFile','TO_kNN-k=1.mat');
                if ~obj.c.showRelativePerformance
                    methodResultsFileNames{end+1} = 'TO_kNN-k=1.mat';
                end
                methodResultsFileNames{end+1} = 'S+T_kNN-k=1.mat';   
            else
                basePlotConfigs.set('baselineFile','TO_LLGC.mat');
                if ~obj.c.showRelativePerformance
                    methodResultsFileNames{end+1} = 'TO_LLGC.mat';
                end
                methodResultsFileNames{end+1} = 'S+T_LLGC.mat';
            end                        
            
            
            plotConfigs = {};
            for fileIdx=1:length(methodResultsFileNames)
                configs = basePlotConfigs.copy();
                configs.set('resultFileName',methodResultsFileNames{fileIdx});
                plotConfigs{end+1} = configs;
            end
            
            measureLossConfigs = Configs();    
            measureLossSoft = SoftFUMeasureLoss(measureLossConfigs);
            measureLossSoft.set('justTarget',true);
            measureLossHard = FUMeasureLoss(measureLossConfigs);
            measureLossHard.set('justTarget',true); 
                                                
            [softMeasureFiles,hardMeasureFiles] = obj.getMeasureFiles();
            for fileIdx=1:length(softMeasureFiles)
                if obj.c.showSoftMeasures
                    configs = basePlotConfigs.copy();                
                    configs.set('resultFileName',softMeasureFiles{fileIdx});
                    configs.set('measureLoss',measureLossSoft);
                    configs.set('methodFileName','S+T_LLGC.mat')
                    plotConfigs{end+1} = configs;
                end
                if obj.c.showHardMeasures
                    configs = basePlotConfigs.copy();                
                    configs.set('resultFileName',hardMeasureFiles{fileIdx});
                    configs.set('measureLoss',measureLossHard);
                    configs.set('methodFileName','S+T_LLGC.mat')
                    plotConfigs{end+1} = configs; 
                end
            end                            
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

