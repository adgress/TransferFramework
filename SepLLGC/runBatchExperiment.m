function [] = runBatchExperiment(multithread, dataset)
    setPaths;
        
    
    c = ProjectConfigs.Create();
    if ProjectConfigs.experimentSetting == ProjectConfigs.SEP_LLGC_EXPERIMENT
        labels = ProjectConfigs.labels;
        for i=1:length(labels)
            l = labels{i};
            batchConfigsObj = ProjectConfigs.BatchConfigs();    
            batchConfigsObj.c.mainConfigs.set('labelsToUse',l);
            obj = BatchExperimentConfigLoader(batchConfigsObj);
            if nargin < 1
                obj.runExperiments();
            else
                obj.runExperiments(multithread);    
            end
        end
    end
end

