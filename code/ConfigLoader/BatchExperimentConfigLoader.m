classdef BatchExperimentConfigLoader < ConfigLoader
    %BATCHEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = BatchExperimentConfigLoader(configsObj)          
            obj = obj@ConfigLoader(configsObj);
        end
        function [] = runExperiments(obj,multithread)
            mainConfigs = obj.configs.get('experimentConfigsClass').copy();            
            mainConfigs.set('transferMethodClass', obj.get('transferMethodClass'));
            if nargin >= 2
                mainConfigs.set('multithread',multithread);
            end
            
            if obj.has('makeSubDomains') && obj.get('makeSubDomains')
                dataAndSplits = load(obj.configs.get('experimentConfigsClass').getDataFileName());
                dataAndSplits = dataAndSplits.dataAndSplits;
                labels = unique(dataAndSplits.allData.Y);
                                                
                backgroundLabel = 257;                
                keepBackground = false;
                featuresToUse = 1;
                dataAndSplits.allData.keepFeatures(featuresToUse);
                
                %{
                numBackground = 100;
                numLabels = 4;
                labelProduct = Helpers.MakeCrossProduct(labels(1:numLabels),labels(1:numLabels));
                %}
                
                numBackground = 0;                
                numTarget = 2;
                numSource = 5;
                labelSet1 = labels(1:numTarget);
                labelSet2 = labels(numTarget+1:numTarget+numSource);
                targetDomains = Helpers.MakeCrossProductOrdered(labelSet1,labelSet1);
                sourceDomains = Helpers.MakeCrossProductNoDupe(labelSet2,labelSet2);
                labelProduct = Helpers.MakeCrossProduct(targetDomains,sourceDomains);
                
                for labelProductIdx=1:length(labelProduct)
                    currLabels = labelProduct{labelProductIdx};                    
                    targetLabel = currLabels(1);
                    sourceLabel = currLabels(2);
                    if isa(targetLabel,'cell')
                        targetLabel = targetLabel{1};
                        sourceLabel = sourceLabel{1};
                    end
                    if sum(sourceLabel == targetLabel) > 0
                        continue
                    end                    
                    dataAndSplitsCopy = struct();
                    dataAndSplitsCopy.allSplits = {};
                    dataAndSplitsCopy.configs = dataAndSplits.configs.copy();
                    for splitIdx=1:length(dataAndSplits.allSplits)
                        split = dataAndSplits.allSplits{splitIdx};
                        newSplit = struct();
                        targetDataCopy = dataAndSplits.allData.copy();
                        targetDataCopy.applyPermutation(split.permutation);
                        targetClassInds = targetDataCopy.hasLabel([targetLabel backgroundLabel]);
                        targetDataCopy.remove(~targetClassInds);  

                        backgroundIndsToRemove = find(targetDataCopy.hasLabel(backgroundLabel));
                        assert(length(backgroundIndsToRemove) >= numBackground);
                        backgroundIndsToRemove = backgroundIndsToRemove(numBackground+1:end);
                        targetDataCopy.remove(backgroundIndsToRemove);

                        sourceDataCopy = dataAndSplits.allData.copy();
                        sourceDataCopy.applyPermutation(split.permutation);
                        sourceClassInds = sourceDataCopy.hasLabel([sourceLabel backgroundLabel]);
                        sourceDataCopy.remove(~sourceClassInds);
                        for labelIdx=1:length(targetLabel)
                           sourceDataCopy.Y(sourceDataCopy.Y == sourceLabel(labelIdx)) = targetLabel(labelIdx); 
                        end                        

                        sourceBackgroundIndsToRemove = find(sourceDataCopy.hasLabel(backgroundLabel));

                        sourceDataCopy.remove(sourceBackgroundIndsToRemove(2*numBackground+1:end));
                        sourceDataCopy.remove(sourceBackgroundIndsToRemove(1:numBackground));
                        assert(sum(sourceDataCopy.hasLabel(backgroundLabel)) == numBackground);

                        newSplit.targetData = targetDataCopy;
                        newSplit.sourceData = sourceDataCopy;                            
                        newSplit.targetType = split.split(split.permutation);
                        newSplit.targetType = newSplit.targetType(targetClassInds);

                        backgroundShouldRemove = false(length(newSplit.targetType),1);
                        backgroundShouldRemove(backgroundIndsToRemove) = true;
                        newSplit.targetType(backgroundShouldRemove) = [];

                        dataAndSplitsCopy.allSplits{end+1} = newSplit;
                    end 
                    if keepBackground
                        mainConfigs.set('classesToKeep',backgroundLabel);
                    end
                    mainConfigs.set('dataAndSplits',dataAndSplitsCopy);
                    mainConfigs.set('sourceClass',sourceLabel);
                    mainConfigs.set('targetClass',targetLabel);
                    mainConfigs.set('dataSetName',[num2str(sourceLabel) '-to-' num2str(targetLabel)]);
                    runExperiment(mainConfigs);
                end
            else
                paramsToVary = obj.configs.get('paramsToVary');
                assert(length(paramsToVary) == 1);
                for i=1:numel(paramsToVary)
                    param = paramsToVary{i};
                    values = obj.configs.get(param);
                    for j=1:numel(values)
                        val = values{j};
                        mainConfigsCopy = mainConfigs.copy();
                        mainConfigsCopy.set(param,val);
                        valString = val;
                        if ~isa(valString,'char')
                            valString = num2str(valString);
                        end                        
                        dataAndSplits = load(mainConfigsCopy.getDataFileName());
                        dataAndSplits = dataAndSplits.dataAndSplits;
                        dataAndSplitsCopy = struct();
                        dataAndSplitsCopy.allSplits = {};
                        dataAndSplitsCopy.configs = dataAndSplits.configs.copy();
                        for splitIdx=1:length(dataAndSplits.allSplits)
                            split = dataAndSplits.allSplits{splitIdx};
                            newSplit = struct();
                            targetDataCopy = dataAndSplits.allData.copy();
                            targetDataCopy.applyPermutation(split.permutation);                            
                            newSplit.targetData = targetDataCopy;
                            newSplit.sourceData = dataAndSplits.sourceDataSets{1}.copy();
                            newSplit.targetType = split.split(split.permutation);
                            dataAndSplitsCopy.allSplits{end+1} = newSplit;
                        end
                        mainConfigsCopy.set('dataAndSplits',dataAndSplitsCopy);
                        runExperiment(mainConfigsCopy);
                    end
                end
            end
        end        
    end
    
end

