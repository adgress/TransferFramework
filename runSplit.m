function [] = runSplit()
    setPaths;
    %o = DataSplitterConfigLoader('config/splitAmazon.cfg','config/splitCommon.cfg');
    o = DataSplitterConfigLoader('config/split/splitTransferA2C.cfg',...
        'config/split/splitCommon.cfg');
    o.splitData();
    o.saveSplit();
    clear;
end