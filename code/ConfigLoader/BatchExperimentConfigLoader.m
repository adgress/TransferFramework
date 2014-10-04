classdef BatchExperimentConfigLoader < ConfigLoader
    %BATCHEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = BatchExperimentConfigLoader(configsFile,configClass)          
            obj = obj@ConfigLoader(configsFile,configClass);
        end
        function [] = runExperiments(obj,multithread)
            inputFile = obj.configs.get('inputFile');
            batchCommonFile = obj.configs.get('batchCommonFile');
            batchCommonConfigs = ConfigLoader.LoadConfigs(...
                Helpers.MakeProjectURL(batchCommonFile));            
            obj.configs.addConfigs(batchCommonConfigs);
            %inputCommonFile = obj.configs.get('inputCommonFile');
            experimentConfigsClass = obj.configs.get('experimentConfigsClass');
            if isa(experimentConfigsClass,'char')
                experimentConfigsClass = str2func(experimentConfigsClass);
            end
            paramsToVary = obj.configs.get('paramsToVary');
            
            experimentLoader = ExperimentConfigLoader.CreateConfigLoader(...
                inputFile,experimentConfigsClass);
            
            assert(numel(paramsToVary) == 1);
            baseConfigs = experimentLoader.configs;
            if nargin >= 2
                baseConfigs.set('multithread',multithread);
            end
            for i=1:numel(paramsToVary)
                param = paramsToVary{i};
                values = obj.configs.get(param);
                for j=1:numel(values)
                    val = values{j};
                    configCopy = baseConfigs.copy();
                    configCopy.set(param,val);
                    valString = val;
                    if ~isa(valString,'char')
                        valString = num2str(valString);
                    end
                    %{
                    outputFileName = [outputFilePrefix '_' param ...
                        '=' valString '.mat'];
                    outputFileName
                    configCopy('outputFile') = outputFileName;
                    %}                    
                    runExperiment('','',configCopy);
                end
            end
        end
    end
    
end

