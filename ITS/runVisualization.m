function [] = runVisualization()
    setPaths;
    close all    
    vizConfigs = ProjectConfigs.VisualizationConfigs();
    width = 1000;    
    height = 600;    
                
    f = figure('position',[100 100 width height]);                                  
        
    visualizeResults(vizConfigs,f);
        
end