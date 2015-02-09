function [] = runBatchSplit()
    configs = ProjectConfigs.SplitConfigs();
    o = BatchDataSplitterConfigLoader(configs);
end

