function [] = getAccuracyForFieldValues()
    directories = {};

    fileName = 'Random_S+T_LLGC-sigmaScale=0.2-alpha=0.9.mat';
    field = 'transferDifference';
    field = 'negativeTransferPrediction';
    
    dataSet = Constants.TOMMASI_DATA;
    dataSet = Constants.CV_DATA;
    if dataSet == Constants.TOMMASI_DATA
        directories = [directories createTommasiDirs()];
        %index = 7;
        index = 1;
    else
        directories = [directories createCVDirs()];
        %index = 21;
        index = 1;
    end
    
    directories = concatenate(getProjectDir(),directories);
    measure = Measure();
    for dirIdx=1:length(directories)
        r = load([directories{dirIdx} '/' fileName]);
        allResults = r.results;
        allResults.computeLossFunction(measure);
        allResults.aggregateResults(measure);
        
        results = allResults.allResults{1};
        aggregatedResults = results.aggregatedResults;
        allValues = aggregatedResults.(field);
        values = allValues(:,index);
        m = mean(values);
        v = var(values);
        display(directories{dirIdx});
        display([field ': ' num2str(m) ' +/- ' num2str(v)]);
    end
end

function [cvDirs] = createCVDirs()
    cvPrefix = 'results/CV-small/';
    cvDirs = {};   
    cvDirs{end+1} = 'A2C';
    cvDirs{end+1} = 'D2W';
    cvDirs{end+1} = 'W2D';    
    cvDirs = concatenate(cvPrefix,cvDirs);
end

function [tommasiDirs] = createTommasiDirs()
    tommasiPrefix = 'results_tommasi/tommasi_data/';
    tommasiDirs = {};    
    tommasiDirs{end+1} = '25  26-to-10  15';
    tommasiDirs{end+1} = '30  41-to-10  15';
    tommasiDirs = concatenate(tommasiPrefix,tommasiDirs);
end

function [dirs] = concatenate(prefix,suffix)
    dirs = {};
    if ~iscell(prefix)
        prefix = {prefix};
    end
    if ~iscell(suffix)
        suffix = {suffix};
    end
    for prefixIdx=1:length(prefix)
        for suffixIdx=1:length(suffix)
            dirs{end+1} = [prefix{prefixIdx} '/' suffix{suffixIdx} '/'];
        end
    end
end

