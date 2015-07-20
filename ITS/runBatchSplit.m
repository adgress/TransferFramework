function [] = runBatchSplit(dataSet)
    configs = ProjectConfigs.SplitConfigs();
    o = BatchDataSplitterConfigLoader(configs);
end

