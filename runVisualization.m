function [] = runVisualization(dataset)
    if nargin < 1
        dataset = Constants.CV_DATA;
    end    
    close all
    setPaths;
    
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
    measuresToShow('NNTransferMeasure') = 1;
    measuresToShow('LLGCTransferMeasure') = 1;
    measuresToShow('HFTransferMeasure') = 1;    
    
    methodsToShow = containers.Map();
    methodsToShow('NearestNeighborMethod') = 1;
    %methodsToShow('HFMethod') = 1;
    
    baselineFiles = {'TO.mat'};    
    
    showBaselines = 1;
    showAdvanced10 = 0;
    showAdvanced20 = 0;
    showMeasures = 1;
    
    if binPerformance
        showBaselines = 0;
        showPreTransferMeasures = 0;
        showRelativePerformance = 0;
        showRelativeMeasures = 0;
    end
    
    fileNames = {};
    if showBaselines
        %fileNames{end+1} = 'TO.mat';
        %fileNames{end+1} = 'SO.mat';
        fileNames{end+1} = 'S+T.mat';
    end
    if showAdvanced10
        %fileNames{end+1} = 'GFK_d=10_usePLS=1.mat';
        %fileNames{end+1} = 'SA_d=10_usePLS=0.mat';
    end
    if showAdvanced20
        fileNames{end+1} = 'GFK_d=20_usePLS=1.mat';
        fileNames{end+1} = 'SA_d=20_usePLS=0.mat';
    end
    if showMeasures
        %fileNames{end+1} = 'TDAS_autoEps=2.mat';
        %fileNames{end+1} = 'HDH.mat';
        %fileNames{end+1} = 'ROD_d=10_usePLS=0.mat';
        %fileNames{end+1} = 'NN_k=10.mat';
        
        %fileNames{end+1} = 'TM/HF_useCMN=0_S+T.mat';
        %fileNames{end+1} = 'TM/HF_useCMN=0_useSoftLoss=1_S+T.mat';
        %fileNames{end+1} = 'TM/HF_useCMN=1_useSoftLoss=1_S+T.mat';
        %fileNames{end+1} = 'TM/HF_useCMN=1_S+T.mat';
        fileNames{end+1} = 'TM/LLGC_useSoftLoss=1_S+T.mat';
        fileNames{end+1} = 'TM/NN_k=1_S+T.mat';
        
        %fileNames{end+1} = 'TM/LLGC_useSoftLoss=0_S+T.mat';
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
            if options.showRelativePerformance
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