function [] = runVisualization(dataset)
    setPaths;
    if nargin < 1
        dataset = Constants.CV_DATA;
    end
    close all
    
    showBaselines = 1;
    showMeasures = 1;
    showRepair = 0;    
    
    showRepairChange = 0;
    
    %prefix = 'results/CV-small_10-13';
    %prefix = 'results/CV-small';
    %prefix = 'results/CV-small_numLabeledPerClass';
    
    prefix = 'results_tommasi/tommasi_data';
    dataset = Constants.TOMMASI_DATA;
    
    showPostTransferMeasures = 1;
    showPreTransferMeasures = 1;
    
    showRelativePerformance = 0;
    showRelativeMeasures = 0;
    
    numColors = 4;    
    
    if dataset == Constants.CV_DATA || dataset == Constants.TOMMASI_DATA
        axisToUse = [0 5 0 1];
        if showRelativePerformance || showRelativeMeasures
            axisToUse = [0 5 0 .5];
        end
    else
        axisToUse = [0 20 0 1.2];
    end   
       
    numLabelsToUse = 2;
        
    showCorrelations = 0;
    showTrain = false;
    showTest = true;
    showLegend = true;   
    
    showTables = 0;
    tableColumns = {'Relative Transfer Acc','Our Measure','Our Measure Just Targets'};
    
    measureLossConfigs = Configs();    
    measureLossJustTarget = SoftFUMeasureLoss(measureLossConfigs);
    measureLossJustTarget.set('justTarget',true);
    measureLossAll = FUMeasureLoss(measureLossConfigs);
    measureLossAll.set('justTarget',true);
    fileNames = {};    
    
    basePlotConfigs = Configs();
    basePlotConfigs.set('baselineFile','TO_LLGC.mat');
    basePlotConfigs.set('measureLoss',measureLossAll);
    
    
    if showRepair
        showBaselines = 0;
        showMeasures = 0;
        numIterations = 3;
        percToRemove = '0.035';
        fixSigma=1;
        saveInv=1;
        
        %fileNames{end+1} = 'TR_strategy=Random_percToRemove=0.1_numIterations=3_useECT=1_fixSigma=1-S+T-LLGC';
        %fileNames{end+1} = 'TR_strategy=NNPrune_percToRemove=0.1_numIterations=3_useECT=1_fixSigma=1_saveINV=0-S+T-LLGC';
        %fileNames{end+1} = 'TR_strategy=NNPrune_percToRemove=0.1_numIterations=3_useECT=0_fixSigma=1_saveINV=1-S+T-LLGC';
        %fileNames{end+1} = 'TR_strategy=None_percToRemove=0.1_numIterations=3_useECT=0_fixSigma=1_saveINV=1-S+T-LLGC';
        fileNames{end+1} = 'TR_strategy=Exhaustive_percToRemove=%s_numIterations=%d_useECT=0_fixSigma=%d_saveINV=%d-S+T-LLGC';
        for sourceIdx=1:length(fileNames)
            fileNames{sourceIdx} = ['REP/LLGC/' sprintf(fileNames{sourceIdx},percToRemove,numIterations,fixSigma,saveInv) '.mat'] ;
        end
        axisToUse = [0 numIterations 0 .9];
    end    
    
    if showBaselines
        if ~showRelativePerformance
            fileNames{end+1} = 'TO_LLGC.mat';
        end
        fileNames{end+1} = 'S+T_LLGC.mat';
    end
    if showMeasures
        %fileNames{end+1} = 'TM/LLGC_S+T.mat';
        %fileNames{end+1} = 'TM/NN_S+T.mat';
        fileNames{end+1} = 'TM/CT_S+T.mat';
    end
    
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
    if dataset == Constants.CV_DATA
        sourceData = {'A','C','D','W'};
        targetData = {'A','C','D','W'};
    elseif dataset == Constants.TOMMASI_DATA
        sourceData = {'10', '15', '23','25'};
        targetData = {'10', '15', '23','25'};
    else
        sourceData = {'CR1','CR2','CR3','CR4'};
        targetData = {'CR1','CR2','CR3','CR4'};        
    end
    f = figure;
    %annotation('textbox', [0,0.15,0.1,0.1],'String', 'Source');
    for sourceIdx=1:numel(sourceData)
        for targetIdx=1:numel(targetData)            
            if sourceIdx == targetIdx
                continue;
            end
            delim = '2';
            if dataset == Constants.TOMMASI_DATA
                delim = '-to-';
            end
            dataSet = [targetData{targetIdx} delim sourceData{sourceIdx}];
            
            options = struct();
            options.prefix = prefix;
            options.plotConfigs = plotConfigs;
            options.showLegend = showLegend;
            options.showTrain = showTrain;
            options.showTest = showTest;
            options.dataSet = dataSet;
            options.showPostTransferMeasures = showPostTransferMeasures;
            options.showRelativePerformance = showRelativePerformance;
            options.showPreTransferMeasures = showPreTransferMeasures;
            options.showRelativeMeasures = showRelativeMeasures;
            options.relativeType = Constants.RELATIVE_PERFORMANCE;
            options.subPlotField = 'C';
            
            options.xAxisField = 'numLabeledPerClass';
            options.xAxisDisplay = 'Target Labels Per Class';
            %{
            options.xAxisField = 'numSourcePerClass';
            options.xAxisDisplay = 'Num Source Instances';
            axisToUse = [0 20 -.1 .5];
            %}
            options.yAxisDisplay = 'Accuracy';
            options.axisToUse = axisToUse;
            options.numLabelsToUse = numLabelsToUse;
            options.showRepair = showRepair;
            options.numColors = numColors;
            options.resultQueries = {};
            options.showRepairChange = showRepairChange;            
            if options.showRepair
                options.yAxisDisplay = 'Measure/Accuracy';
                options.xAxisDisplay = 'Num Repair Iterations';
            elseif options.showRelativePerformance
                if showCorrelations
                    options.relativeType = Constants.CORRELATION;
                    options.yAxisDisplay = 'Measure-Accuracy Correlation';
                else
                    options.relativeType = Constants.DIFF_PERFORMANCE;
                    options.yAxisDisplay = 'Measure/Accuracy Difference';
                    %{
                    options.relativeType = Constants.RELATIVE_PERFORMANCE;
                    options.yAxisDisplay = 'Measure/Accuracy';
                    %}                    
                end
            end
            options.showTables = showTables;            
            if options.showTables
                options.tableColumns = tableColumns;
                options.table = uitable('RowName',[],'units','normalized',...
                    'pos',[(sourceIdx-1)/4 (4-targetIdx)/4 .25 .25]);
                options.resultQueries = {Helpers.MakeQuery('numLabeledPerClass',{2})};
            else
                subplotIndex = (sourceIdx-1)*numel(sourceData) + targetIdx;
                subplot(numel(sourceData),numel(targetData),subplotIndex);
                title(['Target=' targetData{targetIdx} ',Source=' sourceData{sourceIdx}]);
            end
            [~,returnStruct] = visualizeResults(options,f);
            if returnStruct.numItemsInLegend > 0
                showLegend = false;
            end
        end
    end
    
end