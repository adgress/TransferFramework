function [] = runBatchExperiment(multithread, dataset)
    setPaths;
        
    if nargin >= 2 && dataset == Constants.NG_DATA
        error('Create Newsgroup batch configs class!');
    end    
    batchConfigsObj = BatchConfigs();
    batchConfigsObj.setTommasiData();
    batchConfigsObj.setMeasureConfigs();
    transferMethodClassStrings = batchConfigsObj.get('transferMethodClassStrings');
    for i=1:numel(transferMethodClassStrings)
        transferMethodClass = str2func(transferMethodClassStrings{i});
        batchConfigsObj.set('transferMethodClass', transferMethodClass());
        batchConfigsObj.set('experimentConfigLoader', ...
            'TransferExperimentConfigLoader');
        obj = BatchExperimentConfigLoader(batchConfigsObj);
        if nargin < 1
            obj.runExperiments();
        else
            obj.runExperiments(multithread);    
        end
    end
end

