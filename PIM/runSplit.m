function [] = runSplit()
    setPaths;
    o = DataSplitterConfigLoader('config/split/pim.cfg',...
        'config/split/splitCommon.cfg');
    o.splitData();
    o.saveSplit();
    clear;
end