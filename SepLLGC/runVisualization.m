function [] = runVisualization()
    setPaths;
    close all    
    vizConfigs = ProjectConfigs.VisualizationConfigs();
    width = 600;
    height = 500;

    f = figure('position',[100 100 width height]);
              
    a = vizConfigs.get('dataSet');
    if vizConfigs.has('title')
        title(vizConfigs.get('title'));
    else
        title(a{1});
    end
    labels = ProjectConfigs.getLabels();
    randomFeaturesDirs = {...
        ' (0 random features)',...
        ' (10 random features)',...
        ' (30 random features)',...
    };
    isRandomFeatureDataSet = ProjectConfigs.data == Constants.HOUSING_DATA || ...
            ProjectConfigs.data == Constants.YEAST_BINARY_DATA;
    if isRandomFeatureDataSet
        labels = randomFeaturesDirs;
    end
    d = vizConfigs.get('resultsDirectory');
    for i=1:length(labels)
        subplot(1,length(labels),i);
        if isRandomFeatureDataSet
            newResultsDir = [d  labels{i} '/'];
            title(randomFeaturesDirs{i});
        else
            vizConfigs.set('labelsToUse',labels{i});
            newResultsDir = [d '/' num2str(labels{i}) '/'];                    
        end
        vizConfigs.set('resultsDirectory',newResultsDir);
        [~,returnStruct] = visualizeResults(vizConfigs,f);                    
    end
end