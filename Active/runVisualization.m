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
    domainsToViz = ProjectConfigs.tommasiDomainsToViz;
    if ProjectConfigs.data == Constants.CV_DATA
        domainsToViz = ProjectConfigs.cvDomainsToViz;
    end
    [d] = ProjectConfigs.getResultsDirectory();
    if ~isempty(domainsToViz) && ProjectConfigs.useDomainsToViz
        for i=1:length(domainsToViz)
            subplot(1,length(domainsToViz),i);
            newResultsDir = [d '/' domainsToViz{i} '/'];
            vizConfigs.set('resultsDirectory',newResultsDir);
            title(domainsToViz{i});
            [~,returnStruct] = visualizeResults(vizConfigs,f);
        end
    else
        [~,returnStruct] = visualizeResults(vizConfigs,f);            
    end    
end