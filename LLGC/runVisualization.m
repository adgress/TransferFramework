function [] = runVisualization()
    setPaths;
    close all    
    vizConfigs = ProjectConfigs.VisualizationConfigs();
    width = 600;
    height = 500;
    if ProjectConfigs.vizWeights
        width = 1700;
        height = 450;
        vizConfigs.set('showLegend',false);        
    end
    legendLocation = 'southeast';
    fontSize = 20;
    legendFontSize = 12;
    lineWidth = 2;
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
    if c.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER && ...
            ProjectConfigs.vizWeights
        sizes = 5:5:25;
        vizConfigs.set('plotConfigs',plotConfigs);        
        for i=1:length(sizes)
            vizConfigs.set('showXAxisLabel',false);
            vizConfigs.set('showYAxisLabel',false);
            if i == 1
                vizConfigs.set('showYAxisLabel',true);
            end
            if i == 3
                vizConfigs.set('showXAxisLabel',true);
            end
            subplot(1,length(sizes),i);
            vizConfigs.set('sizeToUse',sizes(i));
            [~,~] = visualizeResults(vizConfigs,f);  
        end
    else                
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
    set(findall(gcf,'type','text'),'FontSize',fontSize);
    legendHandle = findobj(gcf,'Type','axes','Tag','legend');
    set(legendHandle,'FontSize',legendFontSize);
    set(legendHandle,'Location',legendLocation);
    lines = findobj(gca,'Type','line');
    if ~ProjectConfigs.vizWeights
        set(lines,'LineWidth',lineWidth);
    end
    fileName = 'LLGC/figures/';
    if ProjectConfigs.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT
        t = vizConfigs.get('title');
        if ProjectConfigs.vizNoisyAcc
            t = ['weights' num2str(ProjectConfigs.CLASS_NOISE)];
        end        
    elseif ProjectConfigs.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER
        t = num2str(ProjectConfigs.trainLabels);
        t(3) = '-';
        if ProjectConfigs.vizWeights
            t = [t 'weights'];
        end
    end
    if exist('t','var')
        t = strrep(t,':', '');
        t = strrep(t,' ','');
        t = strrep(t,'.','');
        fileName = [fileName t];
        saveas(f,[fileName '.fig'],'fig');
        print('-dpng',[fileName '.png']);
    end
end