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
    if showBaselines
        fileNames{end+1} = 'CCA_numVecs=%d-kNN.mat';
        %{
        fileNames{end+1} = 'HP_useIdentity=0_centerData=0_numVecs=%d-kNN.mat';
        fileNames{end+1} = 'HP_useIdentity=1_centerData=0_numVecs=%d-kNN.mat';
        fileNames{end+1} = 'HP_useIdentity=0_centerData=1_numVecs=%d-kNN.mat';        
        fileNames{end+1} = 'HP_useIdentity=1_centerData=1_numVecs=%d-kNN.mat';        
        %}
        fileNames{end+1} = 'HP_useIdentity=0_centerData=2_numVecs=%d-kNN.mat';
        fileNames{end+1} = 'HP_useIdentity=1_centerData=2_numVecs=%d-kNN.mat';
        fileNames{end+1} = 'ML-kNN.mat';
        for i=1:length(fileNames)
            fileNames{i} = sprintf(fileNames{i},numVecs);
        end
        fileNames{end+1} = 'No-DR-Guess.mat';
    end
    showTrain = 0;
    f = figure;
    
    options = struct();
    options.baselineFiles = {};
    options.showRelativePerformance = 0;
    options.prefix = '';
    options.dataSet = 'pim';
    options.measure = 'Measure';
    options.measureConfigs = containers.Map;
    options.measureConfigs('k') = 5;
    
    options.numColors = length(fileNames);
    
    options.fileNames = fileNames;
    options.showLegend = showLegend;
    options.showTrain = showTrain;
    options.methodsToShow = methodsToShow;
    options.xAxisField = 'percTrain';
    options.xAxisDisplay = 'Percent Train';
    options.yAxisDisplay = 'Accuracy';
    options.axisToUse = axisToUse;
    
    visualizeResults(options,f);
end