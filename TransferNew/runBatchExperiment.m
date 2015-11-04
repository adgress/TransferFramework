function [] = runBatchExperiment(multithread, dataset)
    setPaths;
        
    
    c = ProjectConfigs.Create();

    %fields = {[],'useOracle','useUnweighted','useJustTarget'};        
    fields = {[]};
    for i=1:length(fields)
        f = fields{i};
        if ~isempty(f)
            c.(f) = true;
        end
        batchConfigsObj = ProjectConfigs.BatchConfigs();    
        obj = BatchExperimentConfigLoader(batchConfigsObj);
        if nargin < 1
            obj.runExperiments();
        else
            obj.runExperiments(multithread);    
        end
        if ~isempty(f)
            c.(f) = false;
        end
    end
end

