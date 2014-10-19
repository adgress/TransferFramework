function [] = runVisualization(dataset)
    setPaths;
    if nargin < 1
        dataset = Constants.CV_DATA;
    end
    close all
    
    showBaselines = 1;
    showMeasures = 1;
    showRepair = 0;    
    showDiff = 0;
    
    showRepairChange = 0;
    
    %prefix = 'CV-small_10-13';
    prefix = 'CV-small';
    
    showPostTransferMeasures = 1;
    showPreTransferMeasures = 1;
    showRelativePerformance = 0;
    showRelativeMeasures = 0;
    
    numColors = 3;
    
    
    if dataset == Constants.CV_DATA
        axisToUse = [0 5 0 1];
        if showRelativePerformance || showRelativeMeasures
            axisToUse(end) = 2;
        end
    else
        axisToUse = [0 20 0 1.2];
    end
    
    usePerLabel = 0;
    labelToShow = 2;
       
    numLabelsToUse = 2;
        
    showCorrelations = 0;
    showTrain = false;
    showTest = true;
    showLegend = true;
    
    measuresToShow = containers.Map();
    measuresToShow('NNTransferMeasure') = 0;
    measuresToShow('LLGCTransferMeasure') = 1;
    measuresToShow('HFTransferMeasure') = 0;
    measuresToShow('CTTransferMeasure') = 1;
    
    methodsToShow = containers.Map();
    methodsToShow('NearestNeighborMethod') = 0;
    methodsToShow('LLGCMethod') = 1;
    methodsToShow('HFMethod') = 0;
    
    measureLossConfigs = Configs();
    measureLossConfigs.set('justTarget',true);
    measureLoss = FUMeasureLoss(measureLossConfigs);
    
    %baselineFiles = {'TO-kNN_k=1.mat','TO-LLGC.mat'};
    baselineFiles = {'TO_LLGC.mat'};
    fileNames = {};
    
    
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
        %fileNames{end+1} = 'S+T-kNN_k=1.mat';
        fileNames{end+1} = 'S+T_LLGC.mat';
    end
    if showMeasures
        %fileNames{end+1} = 'TM/HF_useCMN=0_useSoftLoss=1_S+T.mat';
        %fileNames{end+1} = 'TM/LLGC-S+T.mat';
        fileNames{end+1} = 'TM/HF_S+T.mat';
        fileNames{end+1} = 'TM/NN_S+T.mat';
        fileNames{end+1} = 'TM/CT_S+T.mat';
    end
    if showDiff
        fileNames = {{'TO_LLGC.mat','S+T_LLGC.mat'}}
    end
    if dataset == Constants.CV_DATA
        sourceData = {'A','C','D','W'};
        targetData = {'A','C','D','W'};
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
            dataSet = [targetData{targetIdx} '2' sourceData{sourceIdx}];
            
            options = struct();
            options.prefix = prefix;
            options.fileNames = fileNames;
            options.showLegend = showLegend;
            options.showTrain = showTrain;
            options.showTest = showTest;
            options.dataSet = dataSet;
            options.showPostTransferMeasures = showPostTransferMeasures;
            options.showRelativePerformance = showRelativePerformance;
            options.showPreTransferMeasures = showPreTransferMeasures;
            options.measuresToShow = measuresToShow;
            options.methodsToShow = methodsToShow;
            options.showRelativeMeasures = showRelativeMeasures;
            options.relativeType = Constants.RELATIVE_PERFORMANCE;
            options.subPlotField = 'C';
            options.xAxisField = 'targetLabelsPerClass';
            options.xAxisDisplay = 'Target Labels Per Class';
            options.yAxisDisplay = 'Accuracy';
            options.baselineFiles = baselineFiles;
            options.axisToUse = axisToUse;
            options.usePerLabel = usePerLabel;
            options.labelToShow = labelToShow;
            options.numLabelsToUse = numLabelsToUse;
            options.showRepair = showRepair;
            options.numColors = numColors;
            options.showRepairChange = showRepairChange;
            options.measureLoss = measureLoss;
            options.showDiff = showDiff;
            if options.showRepair
                options.yAxisDisplay = 'Measure/Accuracy';
                options.xAxisDisplay = 'Num Repair Iterations';
            elseif options.showRelativePerformance
                if showCorrelations
                    options.relativeType = Constants.CORRELATION;
                    options.yAxisDisplay = 'Measure-Accuracy Correlation';
                else
                    options.relativeType = Constants.RELATIVE_PERFORMANCE;
                    options.yAxisDisplay = 'Measure/Accuracy';
                end
            end
            
            subplotIndex = (sourceIdx-1)*numel(sourceData) + targetIdx;
            subplot(numel(sourceData),numel(targetData),subplotIndex);
            title(['Target=' targetData{targetIdx} ',Source=' sourceData{sourceIdx}]);
            [~,returnStruct] = visualizeResults(options,f);
            if returnStruct.numItemsInLegend > 0
                showLegend = false;
            end
        end
    end
    
end