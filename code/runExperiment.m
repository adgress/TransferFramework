function [] = runExperiment(configs)    
          
    setPaths;    
    experimentConfigLoaderClass = str2func(configs.get('experimentConfigLoader'));
    experimentLoader = experimentConfigLoaderClass(configs);        
    learners = experimentLoader.configs.get('learners');
    
    %TODO: Figure out better way to do this loop
    learnerItr = 1;
    while true
        learner = [];
        if numel(learners) > 0
            learner = learners{learnerItr};
            experimentLoader.configs.set('learner',learner);
            learnerItr = learnerItr + 1;
        end        
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
        for j=1:experimentLoader.numExperiments
            splitResults = cell(experimentLoader.numSplits,1);
            if multithread
                parfor i=1:experimentLoader.numSplits  
                    display(sprintf('%d',i));
                    [splitResults{i}] = ...
                        experimentLoader.runExperiment(j,i);
                end            
            else
                for i=1:experimentLoader.numSplits                
                    display(sprintf('%d',i));
                    [splitResults{i}] = ...
                        experimentLoader.runExperiment(j,i);
                end
            end
            allResults.allResults{j}.splitResults = splitResults;
        end
        toc

        allResults.mainConfigs = configs;
        if experimentLoader.configs.get('computeLossFunction')
            measureClass = str2func(experimentLoader.configs.get('measureClass'));
            measureObject = measureClass(experimentLoader.configs);
            allResults.computeLossFunction(measureObject);
            allResults.aggregateResults(measureObject);
        end
        if experimentLoader.configs.has('processMeasureResults') &&...
                experimentLoader.configs.get('processMeasureResults')
            allResults.aggregateMeasureResults();
        end
        allResults.saveResults(outputFile);
        %TODO: Figure out better way to do this loop
        if numel(learners) == 0 || numel(learners) < learnerItr
            break;
        end           
    end
end