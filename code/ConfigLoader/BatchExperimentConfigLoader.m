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
                for sourceLabel=labels'
                    for targetLabel=labels'
                        if sourceLabel == targetLabel
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
                            sourceDataCopy = dataAndSplits.allData.copy();
                            sourceDataCopy.applyPermutation(split.permutation);
                            sourceClassInds = sourceDataCopy.hasLabel(sourceLabel);
                            sourceDataCopy.remove(~sourceClassInds);
                            newSplit.targetData = targetDataCopy;
                            newSplit.sourceData = sourceDataCopy;                            
                            newSplit.targetType = split.split(split.permutation);
                            newSplit.targetType = newSplit.targetType(targetClassInds);
                            dataAndSplitsCopy.allSplits{end+1} = newSplit;
                        end                     
                        mainConfigs.set('dataAndSplits',dataAndSplitsCopy);
                        runExperiment(mainConfigs);
                    end
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

