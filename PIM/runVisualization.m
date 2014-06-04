function [] = runVisualization(dataset)
    setPaths;
    close all
    
    
    axisToUse = [0 1 0 .3];
    showLegend = 1;
    
    methodsToShow = containers.Map();
    methodsToShow('NearestNeighborMethod') = 1;
    methodsToShow('GuessMethod') = 1;
    
    fileNames = {};
    showBaselines = 1;
    
    numVecs=30;
    k=5;
    if showBaselines        
        %fileNames{end+1} = 'justKeptFeatures/CCA_numVecs=%d-kNN_k=%d_useKNNSim=0.mat';
        %fileNames{end+1} = 'justKeptFeatures/HP_useIdentity=0_centerData=0_numVecs=%d-kNN_k=%d_useKNNSim=0.mat';                
        %fileNames{end+1} = 'justKeptFeatures/HP_useIdentity=1_centerData=0_numVecs=%d-kNN_k=%d_useKNNSim=0.mat';        
        
        fileNames{end+1} = 'justKeptFeatures/CCA_numVecs=%d-kNN_k=%d.mat';
        fileNames{end+1} = 'justKeptFeatures/HP_useLocs=0_useIdentity=0_centerData=0_numVecs=%d-kNN_k=%d.mat';        
        %fileNames{end+1} = 'justKeptFeatures/HP_useLocs=0_useIdentity=1_centerData=0_numVecs=%d-kNN_k=%d.mat';        
        
        for i=1:length(fileNames)
            fileNames{i} = sprintf(fileNames{i},numVecs,k);
        end
        fileNames{end+1} = 'No-DR-Guess.mat';
    end
    showTrain = 0;    
    
    options = struct();
    options.baselineFiles = {};
    options.showRelativePerformance = 0;
    options.prefix = '';
    options.dataSet = 'pim';
    options.measure = 'Measure';
    options.measureConfigs = containers.Map;
    options.measureConfigs('k') = 1;
    
    options.numColors = length(fileNames);
    
    options.fileNames = fileNames;
    options.showLegend = showLegend;
    options.showTrain = showTrain;
    options.methodsToShow = methodsToShow;
    options.xAxisField = 'percTrain';
    options.xAxisDisplay = 'Percent Train';
    options.yAxisDisplay = 'Accuracy';
    options.axisToUse = axisToUse;
    
    f = figure;
    %visualizeResults(options,f);
    kVals = k;
    for i=1:length(kVals)
        k = kVals(i);
        options.measureConfigs('k') = k;
        subplot(length(kVals),1,i);
        visualizeResults(options,f);
        showLegend = false;
        options.showLegend = showLegend;
    end
end