function [] = runVisualization()
    setPaths;
    close all    
    vizConfigs = ProjectConfigs.VisualizationConfigs();
    width = 600;
    height = 500;
    f = figure('position',[100 100 width height]);
    subplotIndex = 0;
    plotConfigs = vizConfigs.c.plotConfigs;
              
    a = vizConfigs.get('dataSet');
    if vizConfigs.has('title')
        title(vizConfigs.get('title'));
    else
        title(a{1});
    end
    c = ProjectConfigs.Create();
    %for k=ProjectConfigs.k    
    numSubplots = length(c.sigmaScale);
    for s=c.sigmaScale
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