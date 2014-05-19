function [] = runBatchSplit()   
%{
    o = BatchDataSplitterConfigLoader('config/split/batchSplitPIM.cfg',...
        'config/split/splitCommon.cfg');
%}
    o = DataSplitterConfigLoader('config/split/pim.cfg',...
        'config/split/splitCommon.cfg');
    o.splitData();
    o.saveSplit();
end

