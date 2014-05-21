function [] = runVisualization(dataset)
    setPaths;
    close all
    
    
    axisToUse = [0 1 0 1];                        
    showLegend = 1;    
        
    methodsToShow = containers.Map();
    methodsToShow('NearestNeighborMethod') = 1;
    methodsToShow('GuessMethod') = 1;
        
    fileNames = {};
    
    showBaselines = 1;    
    
    
    if showBaselines
        fileNames{end+1} = 'CCA-kNN.mat';
        fileNames{end+1} = 'HP-kNN.mat';
        fileNames{end+1} = 'No-DR-Guess.mat';
    end        
    showTrain = 0;
    f = figure;    
    
    options = struct(); 
    options.baselineFiles = {};
    options.showRelativePerformance = 0;
    options.prefix = '';
    options.dataSet = 'pim';
    
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