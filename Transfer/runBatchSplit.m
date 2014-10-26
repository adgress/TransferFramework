function [] = runBatchSplit(dataSet)
    if nargin < 1 || dataSet == Constants.CV_DATA
        configs = SplitConfigs();
        %configs.setTommasi();
        o = BatchDataSplitterConfigLoader(configs);
    else
        error('TODO');
        o = BatchDataSplitterConfigLoader('config/split/batchSplit20NG.cfg',...
            'config/split/splitCommon20NG.cfg');
    end
end

