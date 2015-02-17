function [] = runExperiment(configs)    
          
    setPaths;    
    configLoader = configs.get('configLoader');
    configLoader.setNewConfigs(configs);
    %configLoader.configs = configs;
    learners = configLoader.configs.get('learners');
    
    learner = [];
    if numel(learners) > 0
        learner = learners;
        configLoader.configs.set('learner',learner);
    end        
    if ~isempty(learner)
        learner.updateConfigs(configs);
    end
    outputFile = configLoader.getOutputFileName();
    if exist(outputFile,'file') && ~configs.get('rerunExperiments')
        display(['Skipping: ' outputFile]);
        return;
    end

    multithread = configLoader.configs.get('multithread');
    if multithread
        %Fix for laptop
        distcomp.feature( 'LocalUseMpiexec', false );
        matlabpool close force local;
        matlabpool;
    end
    tic

    allResults = ResultsContainer(configLoader.numSplits,...
        configLoader.numExperiments);    
    for j = 1:configLoader.numExperiments
        configLoader.allExperiments{j}.learner = learner;
        allResults.allResults{j}.experiment = ...
            configLoader.allExperiments{j};                   
    end
    for j=1:configLoader.numExperiments
        splitResults = cell(configLoader.numSplits,1);
        if multithread
            parfor i=1:configLoader.numSplits  
                display(sprintf('%d',i));
                [splitResults{i}] = ...
                    configLoader.runExperiment(j,i);               
            end            
        else
            for i=1:configLoader.numSplits                
                display(sprintf('%d',i));
                [splitResults{i}] = ...
                    configLoader.runExperiment(j,i);
            end
        end
        allResults.allResults{j}.splitResults = splitResults;
    end
    toc

    allResults.mainConfigs = configs.copy();
    allResults.mainConfigs.delete('dataAndSplits');
    if configLoader.configs.get('computeLossFunction')
        measureObject = configLoader.get('measure');
        allResults.computeLossFunction(measureObject);
        allResults.aggregateResults(measureObject);
    end
    if configLoader.has('processMeasureResults') &&...
            configLoader.get('processMeasureResults')
        allResults.aggregateMeasureResults();
    end
    allResults.saveResults(outputFile);
end