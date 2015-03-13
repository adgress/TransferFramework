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
    housingDirs = {...
        ' (0 random features)',...
        ' (10 random features)',...
        ' (30 random features)',...
    };
    if ProjectConfigs.data == Constants.HOUSING_DATA
        labels = housingDirs;
    end
    d = vizConfigs.get('resultsDirectory');
    for i=1:length(labels)
        subplot(1,length(labels),i);
        if ProjectConfigs.data == Constants.TOMMASI_DATA
            vizConfigs.set('labelsToUse',labels{i});
            newResultsDir = [d '/' num2str(labels{i}) '/'];            
        elseif ProjectConfigs.data == Constants.HOUSING_DATA
            newResultsDir = [d  labels{i} '/'];
            title(housingDirs{i});
        end
        vizConfigs.set('resultsDirectory',newResultsDir);
        [~,returnStruct] = visualizeResults(vizConfigs,f);                    
    end
end