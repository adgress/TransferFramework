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
            pc = ProjectConfigs.Create();
            mainConfigs = obj.configs.get('experimentConfigsClass').copy();      
            if obj.has('transferMethodClass')
                mainConfigs.set('transferMethodClass', obj.get('transferMethodClass'));
            end
            mainConfigs.set('experimentConfigLoader',obj.get('experimentConfigLoader'));
            if nargin >= 2
                mainConfigs.set('multithread',multithread);
            end
            
            if obj.has('makeSubDomains') && obj.get('makeSubDomains')
                dataAndSplits = load(obj.configs.get('experimentConfigsClass').getDataFileName());
                dataAndSplits = dataAndSplits.dataAndSplits;
                if isempty(dataAndSplits.allData.trueY)
                    dataAndSplits.allData.trueY = dataAndSplits.allData.Y;
                end
                if isempty(dataAndSplits.allData.instanceIDs)
                    dataAndSplits.allData.instanceIDs = zeros(size(dataAndSplits.allData.Y));
                end
                featuresToUse = 1;
                dataAndSplits.allData.keepFeatures(featuresToUse);                
                              
                labelProduct = pc.MakeLabelProduct();
                t = labelProduct{1};
                t(2) = t(1);
                labelProduct = {t,labelProduct{:}};
                
                dataAndSplitsCopy = struct();
                dataAndSplitsCopy.allSplits = {};
                dataAndSplitsCopy.configs = dataAndSplits.configs.copy();      
                                                
                %This code is for making lots of subdomains and using them
                %together for multisource transfer                
                for splitIdx=1:length(dataAndSplits.allSplits)
                    split = dataAndSplits.allSplits{splitIdx};
                    newSplit = struct();                    
                    
                    labelProduct_1 = labelProduct{1};
                    targetLabel = labelProduct_1(1);
                    if isa(targetLabel,'cell')
                        targetLabel = targetLabel{1};
                    end
                    targetDataCopy = dataAndSplits.allData.copy();
                    targetDataCopy.applyPermutation(split.permutation);
                    targetClassInds = targetDataCopy.hasLabel(targetLabel);
                    targetDataCopy.remove(~targetClassInds);  
                    
                    newSplit.targetData = targetDataCopy;
                    newSplit.targetType = split.split;
                    newSplit.targetType = newSplit.targetType(targetClassInds); 
                    newSplit.sourceData = {};
                    
                    for labelProductIdx=1:length(labelProduct)
                        currLabels = labelProduct{labelProductIdx};                    
                        targetLabel_i = currLabels(1);
                        sourceLabel = currLabels(2);
                        if isa(targetLabel_i,'cell')
                            targetLabel_i = targetLabel_i{1};
                            sourceLabel = sourceLabel{1};
                        end
                        assert(all(targetLabel_i == targetLabel));
                        hasOverlap = sum(sourceLabel == targetLabel_i) > 0;
                        if hasOverlap
                            display(['Same label found: ' ...
                                num2str(sourceLabel) ', ' num2str(targetLabel_i)]);
                            %continue                            
                        end 
                        sourceDataCopy = dataAndSplits.allData.copy();                        
                        sourceDataCopy.applyPermutation(split.permutation);
                        sourceClassInds = sourceDataCopy.hasLabel(sourceLabel);
                        sourceDataCopy.remove(~sourceClassInds);
                        for labelIdx=1:length(targetLabel)
                            sourceDataCopy.Y(sourceDataCopy.Y == sourceLabel(labelIdx)) = targetLabel(labelIdx); 
                        end    
                        sourceDataCopy.instanceIDs(:) = labelProductIdx;                        
                        if hasOverlap
                            sourceDataCopy = sourceDataCopy.stratifiedSampleByLabels(pc.numOverlap);
                            sourceDataCopy.remove(sourceDataCopy.Y <= 0);
                        end
                        newSplit.sourceData{end+1} = sourceDataCopy;
                    end                    
                    display('Not applying permutation to split - is this correct?');
                    %newSplit.targetType = split.split(split.permutation);                                          
                    dataAndSplitsCopy.allSplits{end+1} = newSplit;
                end
                mainConfigs.set('dataAndSplits',dataAndSplitsCopy);
                mainConfigs.set('sourceClass',sourceLabel);
                mainConfigs.set('targetClass',targetLabel);
                mainConfigs.set('transferDataSetName',[num2str(sourceLabel) '-to-' num2str(targetLabel)]);
                mainConfigs.set('k',pc.k);
                mainConfigs.set('sigmaScale',pc.sigmaScale);
                mainConfigs.set('alpha',pc.alpha);
                runExperiment(mainConfigs);
                
                %{
                This code is for generating a bunch of target-source domain
                pairs
                
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
                        
                        targetClassInds = targetDataCopy.hasLabel(targetLabel);
                        targetDataCopy.remove(~targetClassInds);  

                        sourceDataCopy = dataAndSplits.allData.copy();
                        sourceDataCopy.applyPermutation(split.permutation);
                        sourceClassInds = sourceDataCopy.hasLabel(sourceLabel);
                        sourceDataCopy.remove(~sourceClassInds);
                        
                        
                        for labelIdx=1:length(targetLabel)
                           sourceDataCopy.Y(sourceDataCopy.Y == sourceLabel(labelIdx)) = targetLabel(labelIdx); 
                        end                        
                        

                        newSplit.targetData = targetDataCopy;
                        newSplit.sourceData = {sourceDataCopy};
                        display('Not applying permutation to split - is this correct?');
                        %newSplit.targetType = split.split(split.permutation);
                        newSplit.targetType = split.split;
                        newSplit.targetType = newSplit.targetType(targetClassInds);                       

                        dataAndSplitsCopy.allSplits{end+1} = newSplit;
                    end 
                    mainConfigs.set('dataAndSplits',dataAndSplitsCopy);
                    mainConfigs.set('sourceClass',sourceLabel);
                    mainConfigs.set('targetClass',targetLabel);
                    mainConfigs.set('transferDataSetName',[num2str(sourceLabel) '-to-' num2str(targetLabel)]);
                    runExperiment(mainConfigs);
                end
                %}
            else
                allParamsToVary = {};
                paramsToVary = obj.get('paramsToVary');
                for paramIdx=1:length(paramsToVary)
                    allParamsToVary{end+1} = obj.get(paramsToVary{paramIdx});
                end
                allParams = Helpers.MakeCrossProduct(allParamsToVary{:});
                for paramIdx=1:length(allParams)
                    params = allParams{paramIdx};
                    mainConfigsCopy = mainConfigs.copy();
                    mainConfigsCopy.set(paramsToVary,params);                    
                    dataAndSplits = load(mainConfigsCopy.getDataFileName());
                    dataAndSplits = dataAndSplits.dataAndSplits;
                    
                    if isfield(dataAndSplits,'sourceNames')
                        allSourceNames = dataAndSplits.sourceNames;
                        currSourceNames = mainConfigsCopy.c.sourceDataSetToUse;
                        targetName = dataAndSplits.allData.name;   
                        shouldUseSource = Helpers.IsMember(allSourceNames,currSourceNames) ...
                            & ~ismember(allSourceNames,targetName);                                         
                        if isempty(find(shouldUseSource))
                            continue;
                        end
                        dataAndSplits.sourceDataSets = dataAndSplits.sourceDataSets(shouldUseSource);
                        dataAndSplits.sourceNames = dataAndSplits.sourceNames(shouldUseSource);
                        transferDataSetName = [[dataAndSplits.sourceNames{:}] '2' targetName];
                        mainConfigsCopy.set('transferDataSetName',transferDataSetName);
                    end
                    dataAndSplitsCopy = struct();
                    dataAndSplitsCopy.allSplits = {};
                    dataAndSplitsCopy.configs = dataAndSplits.configs.copy();
                    for splitIdx=1:length(dataAndSplits.allSplits)
                        split = dataAndSplits.allSplits{splitIdx};
                        newSplit = struct();
                        targetDataCopy = dataAndSplits.allData.copy();
                        targetDataCopy.applyPermutation(split.permutation);                        
                        newSplit.targetData = targetDataCopy;
                        if isfield(dataAndSplitsCopy, 'sourceDataSets')
                            newSplit.sourceData = Helpers.MapCellArray(@copy,dataAndSplits.sourceDataSets);
                        end
                        display('Not applying permutation to split - is this correct?');
                        %newSplit.targetType = split.split(split.permutation);
                        newSplit.targetType = split.split;
                        dataAndSplitsCopy.allSplits{end+1} = newSplit;
                    end
                    mainConfigsCopy.set('dataAndSplits',dataAndSplitsCopy);
                    runExperiment(mainConfigsCopy);
                end
            end
        end        
    end
    
end

