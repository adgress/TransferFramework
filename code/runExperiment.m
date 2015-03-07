function [] = runExperiment(configs)    
    pc = ProjectConfigs.Create();
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
    if exist(outputFile,'file') && ~pc.rerunExperiments
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
    assert(configLoader.numExperiments == 1);
    for j=1:configLoader.numExperiments
        splitResults = cell(configLoader.numSplits,1);
        if multithread
            parfor i=1:configLoader.numSplits  
                display(sprintf('%d',i));
                t = makeTempFile(outputFile,i);
                if exist(t,'file')
                    
                    splitResults{i} = loadTempResults(t);
                    continue;
                end
                [splitResults{i}] = ...
                    configLoader.runExperiment(j,i);                               
                saveTempResults(t,splitResults{i});
            end            
        else
            for i=1:configLoader.numSplits                
                display(sprintf('%d',i));
                t = makeTempFile(outputFile,i);
                if exist(t,'file')
                    display('Found Temp results - loading...');
                    splitResults{i} = loadTempResults(t);                    
                    continue;
                end
                [splitResults{i}] = ...
                    configLoader.runExperiment(j,i);
                saveTempResults(t,splitResults{i});
            end
        end
        allResults.allResults{j}.splitResults = splitResults;
    end    

    allResults.mainConfigs = configs.copy();
    allResults.mainConfigs.delete('dataAndSplits');
    if pc.computeLossFunction
        measureObject = configLoader.get('measure');
        allResults.computeLossFunction(measureObject);
        allResults.aggregateResults(measureObject);
    end
    if pc.processMeasureResults
        allResults.aggregateMeasureResults();
    end
    allResults.saveResults(outputFile);
    for i=1:configLoader.numSplits
        t = makeTempFile(outputFile,i);
        delete(t);
    end
    toc
end

function [t] = makeTempFile(file,idx)
    [path,name,ext] = fileparts(file);
    t = [path '/TEMP/' num2str(idx) '_' name ext];
end

function [] = saveTempResults(file,tempResults)
    Helpers.MakeDirectoryForFile(file);
    save(file,'tempResults');
end

function [a] = loadTempResults(file)
    a = load(file);
    a = a.tempResults;
end