classdef BatchExperimentConfigLoader < ConfigLoader
    %BATCHEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = BatchExperimentConfigLoader(configsObj)          
            if ~exist('configs','var')
                configs = Configs();
            end            
            obj = obj@ConfigLoader(configsObj);
            if ~obj.has('configLoader')
                obj.set('configLoader',obj.configs.c.mainConfigs.c.configLoader);
                if isempty(obj.get('configLoader'))
                    display('No cofigLoader - making ExperimentConfigLoader');
                    obj.set('configLoader',ExperimentConfigLoader());
                end
            end
            if ~obj.has('paramsToVary')
                obj.set('paramsToVary',{});
            end
        end
        function [] = runExperiments(obj,multithread)
            pc = ProjectConfigs.Create();
            mainConfigs = obj.get('mainConfigs').copy();      
            if obj.has('transferMethodClass')
                mainConfigs.set('transferMethodClass', obj.get('transferMethodClass'));
            end
            mainConfigs.set('configLoader',obj.get('configLoader'));
            if nargin >= 2
                mainConfigs.set('multithread',multithread);
            end
            
            allParamsToVary = {};
            numRandomFeatures = pc.numRandomFeatures;
            paramsToVary = obj.get('paramsToVary');
            for paramIdx=1:length(paramsToVary)
                allParamsToVary{end+1} = obj.get(paramsToVary{paramIdx},{[]});
            end
            paramsToVary{end+1} = 'overrideConfigs';
            allParamsToVary{end+1} = obj.get('overrideConfigs');
            isParamEmpty = cellfun(@isempty,allParamsToVary);            
            paramsToVary = paramsToVary(~isParamEmpty);
            allParamsToVary = allParamsToVary(~isParamEmpty);
            allParams = Helpers.MakeCrossProduct(allParamsToVary{:});
            if isempty(allParams)
                allParams{1} = [];
            end
            for paramIdx=1:length(allParams)                    
                params = allParams{paramIdx};
                mainConfigsCopy = mainConfigs.copy();
                if ~isempty(params)
                    mainConfigsCopy.set(paramsToVary,params);  
                    mainConfigsCopy.addConfigs(params{end});
                end
                [dataAndSplits] = obj.loadData(mainConfigsCopy);                
                if numRandomFeatures > 0
                    %error('Add random features to source data?');
                    display(['Adding ' num2str(numRandomFeatures) ' random features']);
                    X = dataAndSplits.allData.X;
                    randomFeatures = rand(size(X,1),numRandomFeatures);
                    %randomFeatures = lognrnd(0,1,[size(X,1) numRandomFeatures]);
                    dataAndSplits.allData.X = [X randomFeatures];
                end
                if isempty(dataAndSplits.allData.instanceIDs)
                    dataAndSplits.allData.instanceIDs = zeros(length(dataAndSplits.allData.Y),1);                        
                end  
                sourceLearner = mainConfigsCopy.get('sourceLearner',[]);
                if ~isempty(sourceLearner) && ~pc.makeSubDomains
                    input = struct();                    
                    for idx=1:length(dataAndSplits.sourceDataSets)
                        d = dataAndSplits.sourceDataSets{idx};
                        d.setTargetTrain();
                        s = sourceLearner.copy();
                        s.set('measure',mainConfigsCopy.get('measure'));
                        input.train = d;
                        input.test = [];
                        s.runMethod(input);
                        dataAndSplits.sourceDataSets{idx}.savedFields.learner = ...
                            s;
                    end                    
                end
                if pc.makeSubDomains
                    assert(numRandomFeatures == 0);
                    assert(ProjectConfigs.useTransfer)
                    labelProduct = mainConfigsCopy.MakeLabelProduct();                    
                    if pc.addTargetDomain
                        labelProduct = obj.addTargetDomain(labelProduct);
                    end
                    [dataAndSplitsCopy] = obj.makeSubDomainsForMultisourceTransfer(...
                        dataAndSplits,labelProduct,pc);
                    [targetLabels,sourceLabels] = mainConfigsCopy.GetTargetSourceLabels();
                    mainConfigsCopy.set('numOverlap',pc.numOverlap);
                    mainConfigsCopy.set('addTargetDomain',pc.addTargetDomain);                                        
                    mainConfigsCopy.set('dataSetName',[num2str(sourceLabels) '-to-' num2str(targetLabels)]);             

                    mainConfigsCopy.set('targetLabels',targetLabels);
                    mainConfigsCopy.set('sourceLabels',sourceLabels);
                    
                    if ~isempty(sourceLearner)
                        input = struct();                              
                        sources = dataAndSplitsCopy.allSplits{1}.sourceData;
                        for idx=1:length(sources)
                            d = sources{idx};
                            d.setTargetTrain();
                            s = sourceLearner.copy();
                            s.configs = sourceLearner.configs.copy();
                            s.set('measure',mainConfigsCopy.get('measure'));
                            input.train = d;
                            input.test = [];
                            s.runMethod(input);
                            for sIdx=1:length(dataAndSplitsCopy.allSplits)
                                s2 = s.copy();
                                s2.configs = s.configs.copy();
                                dataAndSplitsCopy.allSplits{sIdx}.sourceData{idx}.savedFields.learner = ...
                                    s2;
                            end
                        end                    
                        
                    end
                    mainConfigsCopy.set('dataAndSplits',dataAndSplitsCopy);
                else
                    if isfield(dataAndSplits,'sourceNames') && ProjectConfigs.useTransfer
                        assert(numRandomFeatures == 0);
                        allSourceNames = dataAndSplits.sourceNames;
                        currSourceNames = mainConfigsCopy.c.sourceDataSetToUse;
                        targetName = dataAndSplits.allData.name;   
                        shouldUseSource = Helpers.IsMember(allSourceNames,currSourceNames) ...
                            & ~ismember(allSourceNames,targetName);                                         
                        if isempty(find(shouldUseSource))
                            display(['Can''t find source(s) - skipping' ]);
                            display(currSourceNames);
                            continue;
                        end
                        dataAndSplits.sourceDataSets = dataAndSplits.sourceDataSets(shouldUseSource);
                        dataAndSplits.sourceNames = dataAndSplits.sourceNames(shouldUseSource);
                        dataSetName = [[dataAndSplits.sourceNames{:}] '2' targetName];                        
                        for idx=1:length(dataAndSplits.sourceDataSets)
                            ids = idx*ones(size(dataAndSplits.sourceDataSets{idx}.Y));
                            dataAndSplits.sourceDataSets{idx}.instanceIDs = ids;
                        end
                    else
                        %dataSetName = dataAndSplits.allData.name;                        
                        dataSetName = '';
                        if ~strcmp(dataAndSplits.allData.name,'USPS')
                            dataSetName = dataAndSplits.allData.name;
                            if isempty(dataSetName)
                                acronyms = dataAndSplits.configs.get('dataSetAcronyms');
                                assert(length(acronyms) == 1);
                                dataSetName = acronyms{1};
                            end
                        end
                        l = mainConfigsCopy.get('labelsToUse',[]);
                        if ~isempty(l)
                            dataSetName = num2str(l);
                        end
                    end
                    mainConfigsCopy.set('dataSetName',dataSetName);
                    dataAndSplitsCopy = struct();
                    dataAndSplitsCopy.allSplits = {};
                    if isempty(dataAndSplits.configs)
                        dataAndSplits.configs = Configs();
                        dataAndSplits.configs.set('numSplits',length(dataAndSplits.allSplits));
                    end
                    dataAndSplitsCopy.configs = dataAndSplits.configs.copy();
                    labelsToUse = [];
                    if mainConfigsCopy.has('targetLabels')
                        labelsToUse = mainConfigsCopy.c.targetLabels;
                    end
                    l = [];
                    if mainConfigsCopy.has('labelsToUse')
                        l = mainConfigsCopy.get('labelsToUse');
                    end
                    if ~isempty(l)
                        assert(isempty(labelsToUse));
                        labelsToUse = l;
                    end
                    for splitIdx=1:length(dataAndSplits.allSplits)
                        split = dataAndSplits.allSplits{splitIdx};
                        newSplit = struct();
                        targetDataCopy = dataAndSplits.allData.copy();
                        targetDataCopy.applyPermutation(split.permutation);                        
                        newSplit.targetData = targetDataCopy;
                        if isfield(dataAndSplits, 'sourceDataSets')
                            newSplit.sourceData = Helpers.MapCellArray(@copy,dataAndSplits.sourceDataSets);
                            if mainConfigsCopy.has('sourceLabels') && ...
                                    ~isempty(mainConfigsCopy.get('sourceLabels'))
                                error('TODO');
                            end
                        end
                        display('Not applying permutation to split - is this correct?');
                        %newSplit.targetType = split.split(split.permutation);
                        newSplit.targetType = split.split;                     
                        if ~isempty(labelsToUse)
                            assert(size(targetDataCopy.Y,2) == 1);
                            m = obj.get('mainConfigs');
                            if mainConfigsCopy.has('classNoise') && mainConfigsCopy.get('classNoise') > 0                                
                                display('Fixing noisy labels');
                                toUse = Helpers.inDomain(targetDataCopy.trueY,labelsToUse);
                                I = Helpers.inDomain(targetDataCopy.Y,labelsToUse);
                                newY = Helpers.sampleDifferentInDomain(...
                                    targetDataCopy.trueY(~I & toUse),labelsToUse);
                                targetDataCopy.Y(~I & toUse) = newY;
                                %assert(isequal(labelsToUse(:),targetDataCopy.classes(:)));
                                %{
                                
                                assert(length(labelsToUse) == 2);
                                y1Inds = targetDataCopy.isNoisy & targetDataCopy.trueY == labelsToUse(1);
                                y2Inds = targetDataCopy.isNoisy & targetDataCopy.trueY == labelsToUse(2);
                                targetDataCopy.Y(y1Inds) = labelsToUse(2);
                                targetDataCopy.Y(y2Inds) = labelsToUse(1);
                                %}
                            end
                            targetIndsToUse = targetDataCopy.hasLabel(labelsToUse);
                            newSplit.targetData.keep(targetIndsToUse);
                            newSplit.targetType(~targetIndsToUse) = [];   
                            I = false(size(targetDataCopy.trueY));
                            %for l=labelsToUse(:)'
                            for labelIdx=1:length(labelsToUse)
                                l = labelsToUse(labelIdx);
                                J = targetDataCopy.trueY == l;
                                I = I | J;
                                if pc.remapLabels
                                    targetDataCopy.Y(J) = labelIdx;
                                    targetDataCopy.trueY(J) = labelIdx;
                                end
                            end
                            assert(all(I));
                        end
                        f = pc.preprocessDataFunc;
                        if ~isempty(f)
                            [newSplit.targetData,removed] = f(newSplit.targetData);
                            newSplit.targetType(removed) = [];
                        end
                        dataAndSplitsCopy.allSplits{end+1} = newSplit;
                    end
                end
                labelsToKeep = pc.labelsToKeep;
                if ~isempty(labelsToKeep)
                    for idx=1:length(dataAndSplitsCopy.allSplits)
                        dataAndSplitsCopy.allSplits{idx}.targetData.keepLabels(labelsToKeep);
                    end
                end
                mainConfigsCopy.set('dataAndSplits',dataAndSplitsCopy);

                runExperiment(mainConfigsCopy);
            end        
        end                        
        
        function [dataAndSplits] = loadData(obj,mainConfigs)
            dataAndSplits = load(mainConfigs.getDataFileName());
            dataAndSplits = dataAndSplits.dataAndSplits;
            if ~isfield(dataAndSplits,'configs') || isempty(dataAndSplits.configs)
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
        end
        function [labelProduct] = addTargetDomain(obj,labelProduct)
            t = labelProduct{1};
            t2 = labelProduct{1};
            t(2) = t(1);
            
            t2{2} = fliplr(t2{1});
            labelProduct = {t,t2,labelProduct{:}};
        end
        
        %This code is for making lots of subdomains and using them
        %together for multisource transfer
        function [dataAndSplitsCopy] = makeSubDomainsForMultisourceTransfer(obj,dataAndSplits,labelProduct,pc)
            dataAndSplitsCopy = struct();
            dataAndSplitsCopy.allSplits = {};
            dataAndSplitsCopy.configs = dataAndSplits.configs.copy();
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
                targetDataCopy.type = split.split;
                targetClassInds = targetDataCopy.hasLabel(targetLabel);
                targetDataCopy.remove(~targetClassInds);
                targetOverlap = pc.numOverlap;
                if ~pc.addTargetDomain
                    targetOverlap = 0;
                end
                assert(~isempty(targetOverlap));
                isOverlap = targetDataCopy.stratifiedSelection(targetOverlap);
                
                targetDataCopy.remove(isOverlap);                
                %targetDataCopy.Y(isOverlap) = -1;
                
                targetDataCopy.ID2Labels = containers.Map;
                targetDataCopy.ID2Labels(num2str(0)) = targetLabel;
                newSplit.targetData = targetDataCopy;
                newSplit.targetType = split.split;
                newSplit.targetType = newSplit.targetType(targetClassInds);
                newSplit.targetType(isOverlap) = [];
                newSplit.sourceData = {};                
                
                for labelProductIdx=1:length(labelProduct)
                    %{
                    if pc.useJustTargetNoSource
                        break;
                    end
                    %}
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
                    end
                    sourceDataCopy = dataAndSplits.allData.copy();
                    sourceDataCopy.applyPermutation(split.permutation);
                    sourceClassInds = sourceDataCopy.hasLabel(sourceLabel);
                    sourceDataCopy.remove(~sourceClassInds);
                    YNew = -1*ones(size(sourceDataCopy.Y));
                    for labelIdx=1:length(targetLabel)
                        YNew(sourceDataCopy.Y == sourceLabel(labelIdx)) = targetLabel(labelIdx);
                    end
                    sourceDataCopy.Y = YNew;
                    sourceDataCopy.trueY = YNew;
                    sourceDataCopy.instanceIDs(:) = labelProductIdx;
                    sourceDataCopy.ID2Labels = containers.Map();
                    sourceDataCopy.ID2Labels(num2str(labelProductIdx)) = sourceLabel;
                    if hasOverlap
                        sourceDataCopy.keep(isOverlap);
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
        end
    end
    
end

