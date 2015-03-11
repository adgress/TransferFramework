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
    d = vizConfigs.get('resultsDirectory');
    for i=1:length(labels)
        subplot(1,length(labels),i);
        if ProjectConfigs.data == Constants.TOMMASI_DATA
            vizConfigs.set('labelsToUse',labels{i});
            newResultsDir = [d '/' num2str(labels{i}) '/'];
            vizConfigs.set('resultsDirectory',newResultsDir);
        end
        [~,returnStruct] = visualizeResults(vizConfigs,f);            
    end
end