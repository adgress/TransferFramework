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
            
            if pc.makeSubDomains
                dataAndSplits = load(obj.configs.get('experimentConfigsClass').getDataFileName());
                dataAndSplits = dataAndSplits.dataAndSplits;
                if isempty(dataAndSplits.configs)
                    dataAndSplits.configs = Configs();
                    dataAndSplits.configs.set('numSplits',length(dataAndSplits.allSplits));
                end
                if isempty(dataAndSplits.allData.trueY)
                    dataAndSplits.allData.trueY = dataAndSplits.allData.Y;
                end
                %Note: I think instance IDs should always be set to 0
                %if isempty(dataAndSplits.allData.instanceIDs)
                    dataAndSplits.allData.instanceIDs = zeros(size(dataAndSplits.allData.Y));
                %end
                featuresToUse = 1;
                dataAndSplits.allData.keepFeatures(featuresToUse);                
                                                                
                labelProduct = pc.MakeLabelProduct();
                
                multiSourceTransfer = pc.multiSourceTransfer;
                if multiSourceTransfer
                    if pc.addTargetDomain
                        t = labelProduct{1};
                        t2 = labelProduct{1};
                        t(2) = t(1);                    

                        t2{2} = fliplr(t2{1});
                        labelProduct = {t,t2,labelProduct{:}};
                    end
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
                        targetOverlap = pc.numOverlap;
                        if ~pc.addTargetDomain
                            targetOverlap = 0;
                        end
                        isOverlap = targetDataCopy.stratifiedSelection(targetOverlap);                    
                        %targetDataCopy.remove(isOverlap);
                        targetDataCopy.Y(isOverlap) = -1;
                        targetDataCopy.ID2Labels = containers.Map;
                        targetDataCopy.ID2Labels(num2str(0)) = targetLabel;
                        newSplit.targetData = targetDataCopy;
                        newSplit.targetType = split.split;
                        newSplit.targetType = newSplit.targetType(targetClassInds); 
                        newSplit.sourceData = {};

                        sourceLabel = [];

                        for labelProductIdx=1:length(labelProduct)
                            if pc.justTargetNoSource
                                break;
                            end 
                            currLabels = labelProduct{labelProductIdx};                    
                            targetLabel_i = currLabels(1);
                            sourceLabel = currLabels(2);
                            if isa(targetLabel_i,'cell')
                                targetLabel_i = targetLabel_i{1};
                                sourceLabel = sourceLabel{1};
                            end
                            assert(all(targetLabel_i == targetLabel));
                            hasOverlap = ~isempty(intersect(sourceLabel,targetLabel_i));
                            if hasOverlap
                                display(['Same label found: ' ...
                                    num2str(sourceLabel) ', ' num2str(targetLabel_i)]);
                                %continue                            
                            end 
                            sourceDataCopy = dataAndSplits.allData.copy();                        
                            sourceDataCopy.applyPermutation(split.permutation);
                            sourceClassInds = sourceDataCopy.hasLabel(sourceLabel);
                            sourceDataCopy.remove(~sourceClassInds);
                            YNew = -1*ones(size(sourceDataCopy.Y));
                            for labelIdx=1:length(targetLabel)
                                %sourceDataCopy.Y(sourceDataCopy.Y == sourceLabel(labelIdx)) = targetLabel(labelIdx); 
                                YNew(sourceDataCopy.Y == sourceLabel(labelIdx)) = targetLabel(labelIdx);
                            end    
                            sourceDataCopy.Y = YNew;
                            sourceDataCopy.instanceIDs(:) = labelProductIdx; 
                            sourceDataCopy.ID2Labels = containers.Map();
                            sourceDataCopy.ID2Labels(num2str(labelProductIdx)) = sourceLabel;
                            if hasOverlap
                                sourceDataCopy.keep(isOverlap);
                                %sourceDataCopy = sourceDataCopy.stratifiedSampleByLabels(pc.numOverlap);
                                %sourceDataCopy.remove(sourceDataCopy.Y <= 0);
                            elseif pc.maxSourceSize < length(sourceDataCopy.Y);                                
                                sourceDataCopy = sourceDataCopy.stratifiedSampleByLabels(pc.maxSourceSize);
                                sourceDataCopy.remove(sourceDataCopy.Y <= 0);
                            end
                            sourceDataCopy.setSource();
                            newSplit.sourceData{end+1} = sourceDataCopy;

                        end                    
                        display('Not applying permutation to split - is this correct?');
                        %newSplit.targetType = split.split(split.permutation);                                          
                        dataAndSplitsCopy.allSplits{end+1} = newSplit;
                    end
                    [targetLabels,sourceLabels] = pc.GetTargetSourceLabels();
                    mainConfigs.set('numOverlap',pc.numOverlap);
                    mainConfigs.set('addTargetDomain',pc.addTargetDomain);
                    mainConfigs.set('targetLabels',targetLabels);
                    mainConfigs.set('sourceLabels',sourceLabels);
                    mainConfigs.set('dataAndSplits',dataAndSplitsCopy);
                    mainConfigs.set('sourceClass',sourceLabel);
                    mainConfigs.set('targetClass',targetLabel);
                    mainConfigs.set('transferDataSetName',[num2str(sourceLabels) '-to-' num2str(targetLabels)]);
                    mainConfigs.set('k',pc.k);
                    mainConfigs.set('sigmaScale',pc.sigmaScale);
                    mainConfigs.set('alpha',pc.alpha);
                    runExperiment(mainConfigs);
                else
                %{
                This code is for generating a bunch of target-source domain
                pairs
                %}
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
                end
            else
                numRandomFeatures = 0;
                if isfield(pc,'numRandomFeatures')
                    numRandomFeatures = pc.numRandomFeatures;
                end                
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
                    if numRandomFeatures > 0
                        display(['Adding ' num2str(numRandomFeatures) ' random features']);
                        X = dataAndSplits.allData.X;
                        dataAndSplits.allData.X = [X rand(size(X,1),numRandomFeatures)];
                    end
                    if isempty(dataAndSplits.allData.instanceIDs)
                        dataAndSplits.allData.instanceIDs = zeros(length(dataAndSplits.allData.Y),1);                        
                    end
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
                    if isempty(dataAndSplits.configs)
                        dataAndSplits.configs = Configs();
                        dataAndSplits.configs.set('numSplits',length(dataAndSplits.allSplits));
                    end
                    dataAndSplitsCopy.configs = dataAndSplits.configs.copy();
                    labelsToUse = [];
                    if mainConfigsCopy.has('labelsToUse')
                        labelsToUse = mainConfigsCopy.c.labelsToUse;
                    end
                    for splitIdx=1:length(dataAndSplits.allSplits)
                        split = dataAndSplits.allSplits{splitIdx};
                        newSplit = struct();
                        targetDataCopy = dataAndSplits.allData.copy();
                        targetDataCopy.applyPermutation(split.permutation);                        
                        newSplit.targetData = targetDataCopy;
                        if isfield(dataAndSplits, 'sourceDataSets')
                            newSplit.sourceData = Helpers.MapCellArray(@copy,dataAndSplits.sourceDataSets);
                            if ~isempty(labelsToUse)
                                error('TODO');
                            end
                        end
                        display('Not applying permutation to split - is this correct?');
                        %newSplit.targetType = split.split(split.permutation);
                        newSplit.targetType = split.split;                     
                        if ~isempty(labelsToUse)
                            targetIndsToUse = targetDataCopy.hasLabel(labelsToUse);
                            newSplit.targetData.keep(targetIndsToUse);
                            newSplit.targetType(~targetIndsToUse) = [];
                        end
                        
                        dataAndSplitsCopy.allSplits{end+1} = newSplit;
                    end
                    mainConfigsCopy.set('dataAndSplits',dataAndSplitsCopy);
                    runExperiment(mainConfigsCopy);
                end
            end
        end        
    end
    
end

