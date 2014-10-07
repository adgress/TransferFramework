function [] = runExperiment(configFile,experimentConfigsClass,configs)    
          
    setPaths;    
    experimentConfigLoaderClass = str2func(configs.get('experimentConfigLoader'));
    experimentLoader = experimentConfigLoaderClass(configs);        
    learners = experimentLoader.configs.get('learners');
    for learnerItr = 1:length(learners)
        learner = learners{learnerItr};
        experimentLoader.configs.set('learner',learner);
        outputFile = experimentLoader.getOutputFileName();
        if exist(outputFile,'file') && ~configs.get('rerunExperiments')
            display(['Skipping: ' outputFile]);
            return;
        end
        
        multithread = experimentLoader.configs.get('multithread');
        if multithread
            %Fix for laptop
            distcomp.feature( 'LocalUseMpiexec', false );
            matlabpool close force local;
            matlabpool;
        end
        tic
                
        allResults = ResultsContainer(experimentLoader.numSplits,...
            experimentLoader.numExperiments);
        for j = 1:experimentLoader.numExperiments
            experimentLoader.allExperiments{j}.learner = learner;
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
            if multithread
                parfor i=1:experimentLoader.numSplits  
                    display(sprintf('%d',i));
                    [splitResults{i}] = ...
                        experimentLoader.runExperiment(j,i,...
                        savedData);
                end            
            else
                for i=1:experimentLoader.numSplits                
                    display(sprintf('%d',i));
                    [splitResults{i}] = ...
                        experimentLoader.runExperiment(j,i,...
                        savedData);
                end
            end
            allResults.allResults{j}.splitResults = splitResults;
        end
        toc
        savedData.configs = experimentLoader.configs;

        allResults.configs = configs;
        if experimentLoader.configs.get('computeLossFunction')
            measureClass = str2func(experimentLoader.configs.get('measureClass'));
            measureObject = measureClass(experimentLoader.configs);
            allResults.computeLossFunction(measureObject);
            allResults.aggregateResults(measureObject);
        end
        if isKey(experimentLoader.configs,'processMeasureResults') &&...
                experimentLoader.configs.get('processMeasureResults')
            allResults.aggregateMeasureResults();        
        end
        allResults.saveResults(outputFile);
    end
end