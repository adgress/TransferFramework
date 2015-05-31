function [] = runVisualization()
    setPaths;
    close all    
    vizConfigs = ProjectConfigs.VisualizationConfigs();
    width = 1000;    
    height = 300;
    margins = [.05 .15 .05];
    if length(ProjectConfigs.noisesToViz) > 4
        width = 1300;
        margins(1) = margins(1) .* .6;
    end
    c = ProjectConfigs.Create();
    noisyExp = c.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT;
    dataSet = c.dataSet;
    if noisyExp
        vizConfigs.set('axisToUse',[0 1 .5 1]);        
        if dataSet == Constants.NG_DATA && ProjectConfigs.vizNoisyAcc
            vizConfigs.set('axisToUse',[0 1 0 1]);
        end
    else
        if ProjectConfigs.vizWeights
            vizConfigs.set('axisToUse',[0 1 0 1]);
        elseif dataSet == Constants.NG_DATA
            vizConfigs.set('axisToUse',[0 45 .2 1]);
        else
            vizConfigs.set('axisToUse',[0 25 0 1]);
        end
    end
    if ProjectConfigs.vizWeights
        width = 1200;
        height = 250;
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
    
    justFirstLegend = false;
    justFirstYLabel = false;    
    paperSettings = true; 
    textAxes = gca;
    set(textAxes,'Position',[0 0 1 1],'Visible','off');
    if paperSettings
        justFirstLegend = true;
        justFirstYLabel = true;      
        if ~noisyExp && ~ProjectConfigs.vizWeights
            vizConfigs.set('autoAdjustXAxis',false);
        end
    end
        
    if c.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER && ...
            ProjectConfigs.vizWeights        
        vizConfigs.set('plotConfigs',plotConfigs);        
        if dataSet == Constants.NG_DATA
            XTickLabels = {'Target','S1','S2'};
            sizes = [5 10 20 30 40];
        elseif dataSet == Constants.TOMMASI_DATA
            XTickLabels = {'T','IS' ,'S1','S2',...
                'S3','S4','S5','S6','S7'};
            sizes = [5 10 15 20];
        end
        figureHandles = tight_subplot(1,length(sizes),margins(1),...
            margins(2),margins(3));
        for i=1:length(sizes)
            vizConfigs.set('showXAxisLabel',false);
            vizConfigs.set('showYAxisLabel',false);
            if i == 1
                vizConfigs.set('showYAxisLabel',true);
            end
            %{
            if i == 3
                vizConfigs.set('showXAxisLabel',true);
            end
            %}
            %subplot(1,length(sizes),i);
            currAxes = figureHandles(i);
            axes(currAxes);
            %set(currAxes,'XTickLabelMode','auto');
            %set(currAxes,'XTickLabelMode','manual');
            title([num2str(sizes(i)) ' Target Labels Per Class']);
            set(currAxes,'XTick', 1:length(XTickLabels));
            set(currAxes,'XTickLabel', XTickLabels);
            set(currAxes,'YTickLabelMode','auto');
            vizConfigs.set('sizeToUse',sizes(i));
            [~,~] = visualizeResults(vizConfigs,f);  
        end
        axes(textAxes);
        text(.5,.05,vizConfigs.get('xAxisDisplay'),'HorizontalAlignment','center');
    else                
        %for k=ProjectConfigs.k    
        itrArray = c.sigmaScale;        
        
        if noisyExp
            itrArray = ProjectConfigs.noisesToViz;
        else
            if dataSet == Constants.NG_DATA
                itrArray = {'ST2ST32CR1','ST2ST32CR2','ST2ST32CR3','ST2ST32CR4'};
                titles = {'CR1','CR2','CR3','CR4'};            
            elseif dataSet == Constants.TOMMASI_DATA
                itrArray = {[10 15], [10 23], [23 25]};                
                titles = {};
            end
        end
        
        figureHandles = tight_subplot(1,length(itrArray),margins(1),...
            margins(2),margins(3));
        %for s=itrArray(:)'
        for subplotIndex=1:length(itrArray);
            %subplotIndex = subplotIndex + 1;
            currAxes = figureHandles(subplotIndex);
            axes(currAxes);
            set(currAxes,'XTickLabelMode','auto');
            set(currAxes,'YTickLabelMode','auto');
            if noisyExp
                newPlotConfigs = cell(size(plotConfigs));
                for idx=1:length(plotConfigs)
                    p = plotConfigs{idx}.copy();                
                    if noisyExp
                        s = itrArray(subplotIndex);
                        p.set('resultFileName', sprintf(p.c.resultFileName,num2str(s)));
                    else
                        %p.set('resultFileName', sprintf(p.c.resultFileName,num2str(s)));
                    end
                    newPlotConfigs{idx} = p;
                end
                vizConfigs.set('plotConfigs',newPlotConfigs);            
            end
            if ~noisyExp && dataSet == Constants.TOMMASI_DATA
                newVizConfigs = ProjectConfigs.VisualizationConfigs(itrArray{subplotIndex}); 
                vizConfigs.set('title',newVizConfigs.get('title'));
                vizConfigs.set('resultsDirectory',newVizConfigs.get('resultsDirectory'));
                vizConfigs.set('plotConfigs',newVizConfigs.get('plotConfigs'));
                titles{subplotIndex} = newVizConfigs.get('title');
            end            
            if noisyExp
                title(['Noise: ' num2str(s)]);
            else
                if dataSet == Constants.NG_DATA
                    s = itrArray{subplotIndex};
                    newDir = ['results_ng/20news-bydate/splitData/' s ];
                    vizConfigs.set('resultsDirectory',newDir);
                end
                title(titles{subplotIndex});
            end
            if subplotIndex > 1
                vizConfigs.set('showYAxisLabel', ~justFirstYLabel);
                vizConfigs.set('showLegend', ~justFirstLegend);
            end
            [~,returnStruct] = visualizeResults(vizConfigs,currAxes);
        end
        %{
        if c.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT
            numSubplots = length(ProjectConfigs.noisesToViz);
            for s=ProjectConfigs.noisesToViz(:)'
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
                title(['Class Noise: ' num2str(s)]);
                [~,returnStruct] = visualizeResults(vizConfigs,f);
                %vizConfigs.set('showLegend',false);
            end
        else
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
        %}
    end
    %{
    set(findall(gcf,'type','text'),'FontSize',fontSize);
    legendHandle = findobj(gcf,'Type','axes','Tag','legend');
    set(legendHandle,'FontSize',legendFontSize);
    set(legendHandle,'Location',legendLocation);
    lines = findobj(gca,'Type','line');
    if ~ProjectConfigs.vizWeights
        set(lines,'LineWidth',lineWidth);
    end
    %}
    %{
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
    %}
end