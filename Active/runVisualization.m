function [] = runVisualization()
    setPaths;
    close all    
    vizConfigs = ProjectConfigs.VisualizationConfigs();
    width = 1800;
    height = 500;

    f = figure('position',[100 100 width height]);
              
    a = vizConfigs.get('dataSet');
    if vizConfigs.has('title')
        title(vizConfigs.get('title'));
    else
        title(a{1});
    end
    switch ProjectConfigs.data
        case Constants.CV_DATA
            domainsToViz = ProjectConfigs.cvDomainsToViz;
        case Constants.TOMMASI_DATA
            domainsToViz = ProjectConfigs.tommasiDomainsToViz;
        case Constants.NG_DATA
            domainsToViz = ProjectConfigs.ngDomainsToViz;            
        case Constants.HOUSING_DATA
        case Constants.YEAST_BINARY_DATA
        case Constants.USPS_DATA
        otherwise
            error('unknown data set');
    end
    if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE
        domainsToViz = {};
        switch ProjectConfigs.data
            case Constants.NG_DATA
                domainsToViz = {'CR1','CR2','CR3','CR4'};
            case Constants.TOMMASI_DATA
                domainsToViz = {'10  15','10  23','23  25'};
            case Constants.HOUSING_DATA                
            case Constants.YEAST_BINARY_DATA
            case Constants.USPS_DATA
                domainsToViz = {'3  8','1  7'};
                
            otherwise
                error('unknown data set');
        end
        
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