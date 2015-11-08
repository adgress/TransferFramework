function [] = runVisualization()
    setPaths;
    close all    
    vizConfigs = ProjectConfigs.VisualizationConfigs();
    %vizConfigs.set('measure',Measure());
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
    itrArray{1} = '23  25  26  30-to-10  15-numOverlap=30';
    itrArray{2} = '15  25  26  30-to-10  23-numOverlap=30';
    itrArray{3} = '10  15  26  30-to-23  25-numOverlap=30';
    
    figureHandles = tight_subplot(1,length(itrArray),margins(1),...
        margins(2),margins(3));
    s = vizConfigs.get('resultsDirectory');
    for subplotIndex=1:length(itrArray);
        %subplotIndex = subplotIndex + 1;
        currAxes = figureHandles(subplotIndex);
        axes(currAxes);
        set(currAxes,'XTickLabelMode','auto');
        set(currAxes,'YTickLabelMode','auto');  
        vizConfigs.set('autoAdjustXAxis',1);      
        vizConfigs.set('autoAdjustYAxis',0);
        vizConfigs.set('axisToUse',[0 1 0 1]);
        
        s2 = [s '/' itrArray{subplotIndex} '/'];
        vizConfigs.set('resultsDirectory',s2);
        [~,returnStruct] = visualizeResults(vizConfigs,currAxes);
    end
     
end