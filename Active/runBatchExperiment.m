function [] = runBatchExperiment(multithread, dataset)
    setPaths;                
    
    dataSets = {ProjectConfigs.data};
    if dataSets{1} == Constants.ALL_DATA
        dataSets = {Constants.NG_DATA,Constants.HOUSING_DATA,...
            Constants.YEAST_BINARY_DATA,Constants.USPS_DATA};
    end
    for idx=1:length(dataSets)
        batchConfigsObj = ProjectConfigs.BatchConfigs(dataSets{idx});    
        obj = BatchExperimentConfigLoader(batchConfigsObj);
        if nargin < 1
            obj.runExperiments();
        else
            obj.runExperiments(multithread);    
        end    
    end
end

