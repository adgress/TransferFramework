function [] = runBatchExperiment(multithread, dataset)
    setPaths;
        
    
    c = ProjectConfigs.Create();
    if ProjectConfigs.experimentSetting == ProjectConfigs.SEP_LLGC_EXPERIMENT
        labels = ProjectConfigs.getLabels();
        for i=1:length(labels)
            l = labels{i};
            batchConfigsObj = ProjectConfigs.BatchConfigs();    
            batchConfigsObj.c.mainConfigs.set('targetLabels',l);
            obj = BatchExperimentConfigLoader(batchConfigsObj);
            if nargin < 1
                obj.runExperiments();
            else
                obj.runExperiments(multithread);    
            end
        end
    end
end

