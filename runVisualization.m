function [] = runVisualization(showTrain,showLegend,fileNames,measureFiles)
    close all
    setPaths;
    showPostTransferMeasure = 1;
    showRelativePerformance = 1;
    showCorrelations = 0;
    measuresToShow = containers.Map();
    measuresToShow('NNTransferMeasure') = 1;
    methodsToShow = containers.Map();
    methodsToShow('NearestNeighborMethod') = 1;
    %methodsToShow('HFMethod') = 1;
    if nargin < 1
        showTrain = false;
    end
    if nargin < 2
        showLegend = true;
    end    
    if nargin < 3
        showBaselines = 1;
        showAdvanced10 = 0;
        showAdvanced20 = 1;
        showMeasures = 0;
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
            fileNames{end+1} = 'NN_k=10.mat';
        end
        
        sourceData = {'A','C','D','W'};
        targetData = {'A','C','D','W'};
        %{
        for i=1:numel(fileNames)
            file = ['results/' dataSet '/' fileNames{i}];
            fileNames{i} = file;
        end
        %}
    end
    if nargin < 4
        measureFiles = {};
        %measureFiles{end+1} = 'HDH.mat';
        %measureFiles{end+1} = 'TDAS_autoEps=1.mat';
        %measureFiles{end+1} = 'TDAS_autoEps=2.mat';
        %measureFiles{end+1} = 'ROD_d=10_usePLS=0.mat';
        for i=1:numel(measureFiles)
            file = [pwd 'results/' dataSet '/' measureFiles{i}];
            measureFiles{i} = file;
        end
    end
    f = figure;    
    for i=1:numel(sourceData)
        for j=1:numel(targetData)
            if i == j
                continue;
            end
            dataSet = [sourceData{i} '2' targetData{j}];
            
            options = struct();
            options.fileNames = fileNames;
            options.measureFiles = measureFiles;
            options.showLegend = showLegend;
            options.showTrain = showTrain;
            options.dataSet = dataSet;            
            options.showPostTransferMeasure = showPostTransferMeasure;
            options.showRelativePerformance = showRelativePerformance;
            options.measuresToShow = measuresToShow;
            options.methodsToShow = methodsToShow;
            options.subPlotField = 'C';
            options.xAxisField = 'targetLabelsPerClass';
            options.xAxisDisplay = 'Target Labels Per Class';
            options.yAxisDisplay = 'Accuracy';        
            
            
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