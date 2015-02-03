function [] = runVisualization()
    setPaths;
    close all
    %vizConfigs = VisualizationConfigs();
    %vizConfigs.setTommasi();
    vizConfigs = ProjectConfigs.VisualizationConfigs();
    f = figure;
    %annotation('textbox', [0,0.15,0.1,0.1],'String', 'Source');
    subplotIndex = 0;
    sourceData = vizConfigs.get('sourceData');
    targetData = vizConfigs.get('targetData'); 
    showMeasureCorrelation = vizConfigs.get('vizMeasureCorrelation');
    if showMeasureCorrelation
        subplot(1,1,1);
        vizConfigs.set('showLegend',false);
    end
    returnStruct = {};
    
    for targetIdx=1:numel(targetData)
        dataSets = {};
        for sourceIdx=1:numel(sourceData)  
            if ~vizConfigs.c.vizMultiple
                subplotIndex = subplotIndex + 1;
            end
            currSource = sourceData{sourceIdx};
            currTarget = targetData{targetIdx};
            if isequal(currSource,currTarget) 
                if vizConfigs.get('datasetToViz') == Constants.CV_DATA
                    currSource = sourceData;
                    currSource(targetIdx) = [];
                    currSource = [currSource{:}];
                else
                    continue;
                end
            end
            delim = '2';
            if vizConfigs.get('datasetToViz') == Constants.TOMMASI_DATA
                delim = '-to-';
            end
            sourceStr = StringHelpers.ConvertToString(currSource);
            targetStr = StringHelpers.ConvertToString(currTarget);
            dataSet = [sourceStr delim targetStr];       
            if vizConfigs.c.vizMultiple
                dataSets{end+1} = dataSet;
            else
                vizConfigs.set('dataSet',{dataSet});
                if ~vizConfigs.get('showTable') && ...
                        ~showMeasureCorrelation
                    subplot(vizConfigs.get('numSubplotRows'),...
                        vizConfigs.get('numSubplotCols'),subplotIndex);                
                    title(['Target=' targetStr ',Source=' sourceStr]);
                end
                [~,returnStruct{end+1}] = visualizeResults(vizConfigs,f);
                if returnStruct{end}.numItemsInLegend > 0 && ...
                        ~showMeasureCorrelation
                    vizConfigs.set('showLegend',false);
                end
            end            
        end
        if vizConfigs.c.vizMultiple
            subplotIndex = subplotIndex + 1;
            vizConfigs.set('dataSet',dataSets);
            if ~vizConfigs.get('showTable')
                subplot(vizConfigs.get('numSubplotRows'),...
                    vizConfigs.get('numSubplotCols'),subplotIndex);                
                title(['Target=' targetStr]);
            end
            [~,returnStruct] = visualizeResults(vizConfigs,f);
            if returnStruct.numItemsInLegend > 0
                %vizConfigs.set('showLegend',false);
            end
        end
    end
    if showMeasureCorrelation
        relativeValues = vizConfigs.c.relativeValues;
        
        colors = colormap(hsv(length(relativeValues)));
        hold all;
        for relIdx=1:length(relativeValues)
            r = relativeValues{relIdx};
            vals1 = [];            
            vals2 = [];
            for sourceIdx=1:length(returnStruct)
                sourceResults = returnStruct{sourceIdx};               
                v1 = sourceResults.displayVals{r(1)};
                v2 = sourceResults.displayVals{r(2)};
                vals1(sourceIdx,:) = v1.means;
                vals2(sourceIdx,:) = v2.means;
            end
            corrVals = [];
            for sizeIdx=1:size(vals1,2)
                corrVals(sizeIdx) = corr(vals1(:,sizeIdx),vals2(:,sizeIdx));                
            end
            corrVals = vizConfigs.c.relativeScale(relIdx)*corrVals;
            plot(returnStruct{1}.sizes,corrVals,'color',colors(relIdx,:));
        end    
        legend(vizConfigs.c.relativeLegend);
        hold off;
    end
end