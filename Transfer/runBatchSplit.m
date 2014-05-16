function [] = runBatchSplit(dataSet)
    if nargin < 1 || dataSet == Constants.CV_DATA
        o = BatchDataSplitterConfigLoader('config/split/batchSplitTransfer.cfg',...
            'config/split/splitCommon.cfg');
    else
        o = BatchDataSplitterConfigLoader('config/split/batchSplit20NG.cfg',...
            'config/split/splitCommon20NG.cfg');
    end
end

