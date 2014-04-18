function [] = runExperiment(configFile,commonConfigFile,configs)    
    tic    
    setPaths;
    if nargin < 2
        commonConfigFile = 'config/experiment/experimentCommon.cfg';
    end
    if nargin < 1
        %configFile = 'config/testExperiment.cfg';
        %configFile = 'config/experiment/transferA2C.cfg';
        %configFile = 'config/experiment/sourceA2C.cfg';
        %configFile = 'config/experiment/fuseA2C.cfg';
        %configFile = 'config/experiment/maA2C.cfg';
        %configFile = 'config/experiment/gfkA2C.cfg';
        configFile = 'config/experiment/saA2C.cfg';
    end
    
    %TODO: Make static factor method to fix this hackiness
    
    if nargin < 3
        experimentLoader = ExperimentConfigLoader.CreateConfigLoader(...
            configFile,commonConfigFile);
    else
        experimentConfigClass = str2func(configs('experimentConfigLoader'));
        experimentLoader = experimentConfigClass(configs,'');
    end   
    
    
    multithread = experimentLoader.configs('multithread');    
    if multithread
        %Fix for laptop
        distcomp.feature( 'LocalUseMpiexec', false );
        if matlabpool('size') > 0
            matlabpool close force local;
        end
        matlabpool;
    end
    
    experimentLoader.getOutputFileName();
    allResults = ResultsContainer(experimentLoader.numSplits,...
        experimentLoader.allExperiments);
    for i=1:numel(allResults)
        allResults.allResults{i} = Results(allResults.numSplits);
    end
    for j = 1:experimentLoader.numExperiments
        allResults.allResults{j}.experiment = ...
            experimentLoader.allExperiments{j};
    end
    [savedData] = experimentLoader.loadSavedData();
    if isempty(fields(savedData))
        savedData.metadata = cell(experimentLoader.numExperiments, ...
            experimentLoader.numSplits);
        savedData.configs = containers.Map;
        for i=1:numel(savedData.metadata)
            savedData.metadata{i} = struct();
        end
    else
        display('Loaded saved data');
    end
    for j=1:experimentLoader.numExperiments
        splitResults = cell(experimentLoader.numSplits,1);
        splitMetadata = cell(experimentLoader.numSplits,1);        
        if multithread
            parfor i=1:experimentLoader.numSplits  
                display(sprintf('%d',i));
                %{
                [splitResults{i},splitMetadata{i}] = ...
                    experimentLoader.runExperiment(j,i,...
                    savedData);
                %}
                [splitResults{i},~] = ...
                    experimentLoader.runExperiment(j,i,...
                    savedData);
            end            
        else
            for i=1:experimentLoader.numSplits                
                display(sprintf('%d',i));
                %{
                [splitResults{i},splitMetadata{i}] = ...
                    experimentLoader.runExperiment(j,i,...
                    savedData);
                %}
                [splitResults{i},~] = ...
                    experimentLoader.runExperiment(j,i,...
                    savedData);
            end
        end
        savedData.metadata(j,:) = splitMetadata';
        allResults.allResults{j}.splitResults = splitResults;
        saveMetadata = 0;
        if saveMetadata
            display('Saving result metadata');  
            allResults.allResults{j}.splitMetadata = splitMetadata;
        else        
            display('Not saving result metadata');  
        end
    end
    savedData.configs = experimentLoader.configs;
    shouldSaveData = 0;
    if ~shouldSaveData
        display('Not Saving Data');
    else
        experimentLoader.saveData(savedData);
    end
    measureClass = str2func(experimentLoader.configs('measureClass'));
    measureObject = measureClass();
    allResults.configs = experimentLoader.configs;
    if experimentLoader.configs('processResults')
        allResults.processResults(measureObject);
        allResults.aggregateResults(measureObject);
        %{
    else
        for i=1:numel(allResults.allResults)
            allResults.allResults{i}.splitMeasures = ...
                allResults.allResults{i}.splitResults;
        end        
        %}
    end
    allResults.aggregateMeasureResults();
    
    outputFile = experimentLoader.getOutputFileName();
    allResults.saveResults(outputFile);
    toc
end