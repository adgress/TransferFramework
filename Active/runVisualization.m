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
    resultsDirectoryPrefix = 'results_tommasi/tommasi_data/';
    domainsToViz = ProjectConfigs.tommasiDomainsToViz;
    if ProjectConfigs.data == Constants.CV_DATA
        resultsDirectoryPrefix = 'results/CV-small/';
        domainsToViz = ProjectConfigs.cvDomainsToViz;
    end
    
    if ~isempty(domainsToViz)
        for i=1:length(domainsToViz)
            subplot(1,length(domainsToViz),i);
            newResultsDir = [resultsDirectoryPrefix '/' domainsToViz{i} '/'];
            vizConfigs.set('resultsDirectory',newResultsDir);
            title(domainsToViz{i});
            [~,returnStruct] = visualizeResults(vizConfigs,f);
        end
    else
        [~,returnStruct] = visualizeResults(vizConfigs,f);            
    end    
end