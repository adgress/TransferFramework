function [] = runVisualization()
    setPaths;
    close all    
    vizConfigs = ProjectConfigs.VisualizationConfigs();
    vizConfigs.set('measure',L2Measure());
    width = 1000;    
    height = 300;
    margins = [.05 .15 .05];

    f = figure('position',[100 100 width height]);
    plotConfigs = vizConfigs.c.plotConfigs;

    if vizConfigs.has('title')
        title(vizConfigs.get('title'));
    else
        title(a{1});
    end
        
    textAxes = gca;
    set(textAxes,'Position',[0 0 1 1],'Visible','off');                
    itrArray = {[]};
    figureHandles = tight_subplot(1,length(itrArray),margins(1),...
        margins(2),margins(3));
    for subplotIndex=1:length(itrArray);
        %subplotIndex = subplotIndex + 1;
        currAxes = figureHandles(subplotIndex);
        axes(currAxes);
        set(currAxes,'XTickLabelMode','auto');
        set(currAxes,'YTickLabelMode','auto');  
        vizConfigs.set('autoAdjustXAxis',1);      
        vizConfigs.set('autoAdjustYAxis',0);
        vizConfigs.set('axisToUse',[0 1 0 1]);
        [~,returnStruct] = visualizeResults(vizConfigs,currAxes);
    end
     
end