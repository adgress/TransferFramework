function [] = runBatchExperiment(multithread, dataset)
    setPaths;
        
    
    c = ProjectConfigs.Create();              
    batchConfigsObj = ProjectConfigs.BatchConfigs();    
    obj = BatchExperimentConfigLoader(batchConfigsObj);
    if nargin < 1
        obj.runExperiments();
    else
        obj.runExperiments(multithread);    
    end       
end

