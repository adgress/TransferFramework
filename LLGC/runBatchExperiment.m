function [] = runBatchExperiment(multithread, dataset)
    setPaths;
        
    
    c = ProjectConfigs.Create();
    %classNoise = [0 .15 .25 .35 .55];
    if ProjectConfigs.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT
        %classNoise = [0 .05 .15 .25 .35];
        classNoise = [.35 .25 .0 .15];
        for i=classNoise(:)'
            c.classNoise = i;                        
            batchConfigsObj = ProjectConfigs.BatchConfigs();    
            batchConfigsObj.c.mainConfigs.set('classNoise',i);
            batchConfigsObj.c.mainConfigs.c.learners.set('classNoise',i);
            obj = BatchExperimentConfigLoader(batchConfigsObj);
            if nargin < 1
                obj.runExperiments();
            else
                obj.runExperiments(multithread);    
            end
        end
    else
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
end

