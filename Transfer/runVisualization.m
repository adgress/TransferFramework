function [] = runVisualization()
    setPaths;
    close all
    %vizConfigs = VisualizationConfigs();
    %vizConfigs.setTommasi();
    vizConfigs = ProjectConfigs.VisualizationConfigs();
    f = figure;
    %annotation('textbox', [0,0.15,0.1,0.1],'String', 'Source');
    subplotIndex = 1;
    sourceData = vizConfigs.get('sourceData');
    targetData = vizConfigs.get('targetData');
    for sourceIdx=1:numel(sourceData)
        for targetIdx=1:numel(targetData)
            if isequal(sourceIdx,targetIdx)
                continue;
            end
            delim = '2';
            if vizConfigs.get('datasetToViz') == Constants.TOMMASI_DATA
                delim = '-to-';
            end
            sourceStr = StringHelpers.ConvertToString(sourceData{sourceIdx});
            targetStr = StringHelpers.ConvertToString(targetData{targetIdx});
            dataSet = [sourceStr delim targetStr];                                                                        
            vizConfigs.set('dataSet',dataSet);
            if ~vizConfigs.get('showTable')
                subplot(vizConfigs.get('numSubplotRows'),...
                    vizConfigs.get('numSubplotCols'),subplotIndex);
                subplotIndex = subplotIndex + 1;
                title(['Target=' targetStr ',Source=' sourceStr]);
            end
            [~,returnStruct] = visualizeResults(vizConfigs,f);
            if returnStruct.numItemsInLegend > 0
                vizConfigs.set('showLegend',false);
            end
        end
    end
    
end