function [] = runVisualization()
    setPaths;
    close all    
    vizConfigs = ProjectConfigs.VisualizationConfigs();
    f = figure;
    subplotIndex = 0;
    plotConfigs = vizConfigs.c.plotConfigs;
    
    %dataSet = 'USPS-small';
    dataSet = 'COIL20';
    vizConfigs.set('dataSet',{dataSet});
    vizConfigs.set('prefix','results');
    title(dataSet);
    %for k=ProjectConfigs.k    
    numSubplots = length(ProjectConfigs.sigmaScale);
    for s=ProjectConfigs.sigmaScale
        subplotIndex = subplotIndex + 1;
        subplot(1,numSubplots,subplotIndex);                
        newPlotConfigs = cell(size(plotConfigs));
        for idx=1:length(plotConfigs)
            p = plotConfigs{idx}.copy();
            %p.set('resultFileName', sprintf(p.c.resultFileName,num2str(k)));
            p.set('resultFileName', sprintf(p.c.resultFileName,num2str(s)));
            newPlotConfigs{idx} = p;
        end
        vizConfigs.set('plotConfigs',newPlotConfigs);        
        [~,returnStruct] = visualizeResults(vizConfigs,f);            
        %vizConfigs.set('showLegend',false);
    end
    
end