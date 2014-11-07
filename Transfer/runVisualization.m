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
    vizMultiple = true;
    for targetIdx=1:numel(targetData)
        dataSets = {};
        for sourceIdx=1:numel(sourceData)   
            if ~vizMultiple
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
            if vizMultiple
                dataSets{end+1} = dataSet;
            else
                vizConfigs.set('dataSet',{dataSet});
                if ~vizConfigs.get('showTable')
                    subplot(vizConfigs.get('numSubplotRows'),...
                        vizConfigs.get('numSubplotCols'),subplotIndex);                
                    title(['Target=' targetStr ',Source=' sourceStr]);
                end
                [~,returnStruct] = visualizeResults(vizConfigs,f);
                if returnStruct.numItemsInLegend > 0
                    vizConfigs.set('showLegend',false);
                end
            end            
        end
        if vizMultiple
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
    
end