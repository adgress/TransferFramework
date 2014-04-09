function [] = runBatchSplit()
    o = BatchDataSplitterConfigLoader('config/batch/batchSplitTransfer.cfg',...
        'config/split/splitCommon.cfg');
end

