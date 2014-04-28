function [] = runBatchExperiment(multithread, dataset)
    setPaths;
    configFiles = {};
    runBaseline = 1;
    runAdvanced = 0;
    runMeasures = 1;
    %configFiles{end+1} = 'config/batch/batchMA.cfg';
    
    batchCommon = 'config/batch/batchCommon.cfg';
    if nargin >= 2 && dataset == Constants.NG_DATA
        batchCommon = 'config/batch/batchCommonNG.cfg';
    end
    if runAdvanced
        configFiles{end+1} = 'config/batch/batchSA.cfg';
        configFiles{end+1} = 'config/batch/batchGFK.cfg';
        %configFiles{end+1} = 'config/batch/batchDAML.cfg';
    end
    
    if runBaseline
        configFiles{end+1} = 'config/batch/batchFuse.cfg';
        configFiles{end+1} = 'config/batch/batchTransfer.cfg';
        %configFiles{end+1} = 'config/batch/batchSource.cfg';
    end
    
    if runMeasures
        %{
            configFiles{end+1} = 'config/measure/batchROD.cfg';
            configFiles{end+1} = 'config/measure/batchHDH.cfg';
            configFiles{end+1} = 'config/measure/batchTDAS.cfg';
        %}
        %configFiles{end+1} = 'config/measure/batchHF.cfg';
        configFiles{end+1} = 'config/measure/batchNN.cfg';
        configFiles{end+1} = 'config/measure/batchLLGC.cfg';        
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

