function [] = runVisualization(dataset)
    setPaths;
    close all
            
    showLegend = 1;
    
    methodsToShow = containers.Map();    
    
    showBaselines = 1;
        
    showTrain = 0;
    showTest = 1;
    
    options = struct();
    options.baselineFiles = {};
    options.showRelativePerformance = 0;
    options.prefix = '';
    options.dataSet = 'pim';
    options.measure = 'Measure';
    options.measureConfigs = containers.Map;
    options.measureConfigs('k') = 1;        
        
    options.showLegend = showLegend;
    options.showTrain = showTrain;
    options.showTest = showTest;
    
    options.xAxisField = 'percTrain';    
    options.yAxisDisplay = 'Precision@k';    
    
    f = figure;
    %visualizeResults(options,f);
    kVals = [1 3 5 7];    
    numVecsExp = 0;
    tauExp = 0;
    clusterExp = 0;
    if tauExp
        kVals = 1;
    end
    if clusterExp
        kVals = [2 5 10];
    end
    for i=1:length(kVals)        
        k = kVals(i);
        if showBaselines
            fileNames = {};
            if numVecsExp                
                fileNames{end+1} = 'justKeptFeatures/numVecsExp/CCA-kNN_k=%d.mat';
                fileNames{end+1} = 'justKeptFeatures/numVecsExp/HP_useLocs=0_useIdentity=0_centerData=0-kNN_k=%d.mat';
                fileNames{end+1} = 'justKeptFeatures/numVecsExp/HP_useLocs=1_useIdentity=0_centerData=0-kNN_k=%d.mat';
                options.xAxisDisplay = 'Max Num Vecs';
                axisToUse = [0 35 0 .3];
                params = [k];
                methodsToShow('NearestNeighborMethod') = 1;
                methodsToShow('GuessMethod') = 1;   
            elseif tauExp
                numVecs = 30;
                fileNames{end+1} = 'justKeptFeatures/tauExp/CCA_numVecs=%d-tau.mat';
                fileNames{end+1} = 'justKeptFeatures/tauExp/HP_useLocs=0_useIdentity=0_centerData=0_numVecs=30-tau.mat';
                fileNames{end+1} = 'justKeptFeatures/tauExp/HP_useLocs=1_useIdentity=0_centerData=0_numVecs=30-tau.mat';
                options.xAxisDisplay = 'Tau';
                axisToUse = [0 1 0 1];
                params = [numVecs];
                methodsToShow('TauMethod') = 1;
                options.measure = 'TauMeasure';
                options.yAxisDisplay = 'Percent < Tau x Mean'; 
            elseif clusterExp
                numVecs = 30;
                numClusters = k;
                fileNames{end+1} = 'justKeptFeatures/cluster/CCA_numVecs=%d-KMeans_numClusters=%d.mat';
                fileNames{end+1} = 'justKeptFeatures/cluster/HP_useLocs=0_useIdentity=0_centerData=0_numVecs=%d-KMeans_numClusters=%d.mat';
                fileNames{end+1} = 'justKeptFeatures/cluster/HP_useLocs=1_useIdentity=0_centerData=0_numVecs=%d-KMeans_numClusters=%d.mat';
                options.xAxisDisplay = 'Percent Train';
                axisToUse = [0 1 0 1];
                params = [numVecs numClusters];
                methodsToShow('KMeansMethod') = 1;
                options.measure = 'RandIndexMeasure';
                options.yAxisDisplay = 'Rand Index'; 
            else
                numVecs = 30;
                fileNames{end+1} = 'justKeptFeatures/CCA_numVecs=%d-kNN_k=%d.mat';
                fileNames{end+1} = 'justKeptFeatures/HP_useLocs=0_useIdentity=0_centerData=0_numVecs=%d-kNN_k=%d.mat';
                fileNames{end+1} = 'justKeptFeatures/HP_useLocs=1_useIdentity=0_centerData=0_numVecs=%d-kNN_k=%d.mat';
                fileNames{end+1} = 'justKeptFeatures/No-DR-Guess.mat';
                options.xAxisDisplay = 'Percent Train';
                axisToUse = [0 1 0 .3];
                params = [numVecs k];
                methodsToShow('NearestNeighborMethod') = 1;
                methodsToShow('GuessMethod') = 1;
            end
            for j=1:length(fileNames)
                fileNames{j} = sprintf(fileNames{j},params);
            end
        end
        options.methodsToShow = methodsToShow;
        options.axisToUse = axisToUse;
        options.fileNames = fileNames;
        options.numColors = length(fileNames);
        if showTrain && showTest
            options.numColors = options.numColors*2;
        end
        options.measureConfigs('k') = k;
        subplot(1,length(kVals),i);
        visualizeResults(options,f);
        showLegend = false;
        options.showLegend = showLegend;
    end
end