function [] = runExperiment(configs)    
    pc = ProjectConfigs.Create();
    setPaths;    
    configLoader = configs.get('configLoader');    
    %configs.addConfigs(configLoader.configs);
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
        [~,name] = system('hostname');
        name(end) = [];
        if isequal(name,'Aubrey-Laptop')
            matlabpool local 2;
        else
           matlabpool; 
        end        
    end
    tic

    allResults = ResultsContainer(configLoader.numSplits,...
        configLoader.numExperiments);        
    for expIdx = 1:configLoader.numExperiments
        configLoader.allExperiments{expIdx}.learner = learner;
        allResults.allResults{expIdx}.experiment = ...
            configLoader.allExperiments{expIdx};                   
    end
    %assert(configLoader.numExperiments == 1);
    %shouldSaveTempResults = configLoader.numExperiments == 1;
    for expIdx=1:configLoader.numExperiments
        splitResults = cell(configLoader.numSplits,1);
        t = makeTempFile(outputFile,expIdx);
        if exist(t,'file')
            display('Found Temp results - loading...');
            splitResults = loadTempResults(t);
            allResults.allResults{expIdx}.splitResults = splitResults;
            continue;
        end
        if multithread
            parfor splitIdx=1:configLoader.numSplits  
                display(sprintf('%d',splitIdx));
                t = makeTempFile(outputFile,expIdx,splitIdx);
                if exist(t,'file')
                    display('Found Temp results - loading...');
                    splitResults{splitIdx} = loadTempResults(t);
                    continue;
                end
                [splitResults{splitIdx}] = ...
                    configLoader.runExperiment(expIdx,splitIdx);
                saveTempResults(t,splitResults{splitIdx});
            end            
        else
            for splitIdx=1:configLoader.numSplits                
                display(sprintf('%d',splitIdx));
                t = makeTempFile(outputFile,splitIdx,expIdx);
                if exist(t,'file')
                    display('Found Temp results - loading...');
                    splitResults{splitIdx} = loadTempResults(t);                    
                    continue;
                end
                [splitResults{splitIdx}] = ...
                    configLoader.runExperiment(expIdx,splitIdx);
                saveTempResults(t,splitResults{splitIdx});
            end
        end
        t = makeTempFile(outputFile,expIdx);
        saveTempResults(t,splitResults);
        allResults.allResults{expIdx}.splitResults = splitResults;
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
    for splitIdx=1:configLoader.numSplits
        t = makeTempFile(outputFile,splitIdx);
        delete(t);
    end
    toc
end

function [t] = makeTempFile(file,expIdx,splitIdx)
    [path,name,ext] = fileparts(file);
    t = [path '/TEMP/' num2str(expIdx) '_'];
    if exist('splitIdx','var')
        t = [t num2str(splitIdx) '_'];
    end
    t = [t name ext];
    %t = [path '/TEMP/' num2str(idx) '_' name ext];
end

function [] = saveTempResults(file,tempResults)
    Helpers.MakeDirectoryForFile(file);
    save(file,'tempResults');
end

function [a] = loadTempResults(file)
    a = load(file);
    a = a.tempResults;
end