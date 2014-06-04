function [] = runBatchExperiment(multithread)
    setPaths;
    %cvx_setup;
    configFiles = {};
    runBaseline = 1;        
    
    batchCommon = 'config/batch/batchCommon.cfg';    
    
    if runBaseline
        %configFiles{end+1} = 'config/batch/batchGuess.cfg';
        configFiles{end+1} = 'config/batch/batchCCA.cfg';
        configFiles{end+1} = 'config/batch/batchHP.cfg';
        configFiles{end+1} = 'config/batch/batchHPlocs.cfg';
        %configFiles{end+1} = 'config/batch/batchML.cfg';
    end
    
    for i=1:numel(configFiles)
        obj = BatchExperimentConfigLoader(configFiles{i},batchCommon);
        if nargin < 1
            obj.runExperiments();
        else
            obj.runExperiments(multithread);    
        end
    end    
end

