clear;
%{
o = DataSplitterConfigLoader('config/splitAmazon.cfg','config/splitCommon.cfg');
o.splitData();
%}
%{
e = ExperimentConfigLoader('config/testExperiment.cfg',...
    'config/experimentCommon.cfg');
%}

runExperiment('config/testExperiment.cfg','config/experimentCommon.cfg');