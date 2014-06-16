function [] = runVisualization(dataset)
    setPaths;
    if nargin < 1
        dataset = Constants.CV_DATA;
    end
    close all
    
    showBaselines = 0;
    showMeasures = 0;
    showRepair = 1;
    
    showRepairChange = 0;
    
    numColors = 4;
    
    
    if dataset == Constants.CV_DATA
        axisToUse = [0 5 0 2];
    else
        axisToUse = [0 20 0 1.2];
    end
    
    usePerLabel = 0;
    labelToShow = 2;
    
    binPerformance = 0;
    numLabelsToUse = 2;
    
    showPostTransferMeasures = 1;
    showPreTransferMeasures = 1;
    showRelativePerformance = 1;
    showRelativeMeasures = 1;
    showCorrelations = 0;
    showTrain = false;
    showLegend = true;
    
    measuresToShow = containers.Map();
    measuresToShow('NNTransferMeasure') = 0;
    measuresToShow('LLGCTransferMeasure') = 1;
    measuresToShow('HFTransferMeasure') = 0;
    
    methodsToShow = containers.Map();
    methodsToShow('NearestNeighborMethod') = 1;
    methodsToShow('LLGCMethod') = 1;
    methodsToShow('HFMethod') = 0;
    
    baselineFiles = {'TO-kNN_k=1.mat','TO-LLGC.mat'};
    fileNames = {};
    
    
    if showRepair
        showBaselines = 0;
        showMeasures = 0;
        binPerformance = 0;
        numIterations = 3;
        percToRemove = 1;
        
        %fileNames{end+1} = 'TR_strategy=Random_percToRemove=0.1_numIterations=3_useECT=1_fixSigma=1-S+T-LLGC';
        %fileNames{end+1} = 'TR_strategy=NNPrune_percToRemove=0.1_numIterations=3_useECT=1_fixSigma=1_saveINV=0-S+T-LLGC';
        %fileNames{end+1} = 'TR_strategy=NNPrune_percToRemove=0.1_numIterations=3_useECT=0_fixSigma=1_saveINV=1-S+T-LLGC';
        %fileNames{end+1} = 'TR_strategy=None_percToRemove=0.1_numIterations=3_useECT=0_fixSigma=1_saveINV=1-S+T-LLGC';
        fileNames{end+1} = 'TR_strategy=Exhaustive_percToRemove=0.1_numIterations=3_useECT=0_fixSigma=1_saveINV=1-S+T-LLGC';
        for i=1:length(fileNames)
            fileNames{i} = ['REP/LLGC/' sprintf(fileNames{i},percToRemove,numIterations) '.mat'] ;
        end
        axisToUse = [0 3 0 1];
    end
    
    if binPerformance
        showBaselines = 0;
        showPreTransferMeasures = 0;
        showRelativePerformance = 0;
        showRelativeMeasures = 0;
        axisToUse = [0 3 0 1];
    end
    
    if showBaselines
        fileNames{end+1} = 'S+T-kNN_k=1.mat';
        fileNames{end+1} = 'S+T-LLGC.mat';
    end
    if showMeasures
        %fileNames{end+1} = 'TM/HF_useCMN=0_useSoftLoss=1_S+T.mat';
        fileNames{end+1} = 'TM/LLGC_useSoftLoss=1_useMeanSigma=0_S+T.mat';
        fileNames{end+1} = 'TM/NN_k=1_S+T.mat';
    end
    if dataset == Constants.CV_DATA
        sourceData = {'A','C','D','W'};
        targetData = {'A','C','D','W'};
        prefix = 'CV';
    else
        sourceData = {'CR1','CR2','CR3','CR4'};
        targetData = {'CR1','CR2','CR3','CR4'};
        prefix = 'NG';
    end
    f = figure;
    for i=1:numel(sourceData)
        for j=1:numel(targetData)
            if i == j
                continue;
            end
            dataSet = [sourceData{i} '2' targetData{j}];
            
            options = struct();
            options.prefix = prefix;
            options.fileNames = fileNames;
            options.showLegend = showLegend;
            options.showTrain = showTrain;
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
            options.binPerformance = binPerformance;
            options.numLabelsToUse = numLabelsToUse;
            options.showRepair = showRepair;
            options.numColors = numColors;
            options.showRepairChange = showRepairChange;
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
            
            subplotIndex = (i-1)*numel(sourceData) + j;
            subplot(numel(sourceData),numel(targetData),subplotIndex);
            visualizeResults(options,f);
            showLegend = false;
        end
    end
    
end