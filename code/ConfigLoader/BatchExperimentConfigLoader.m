classdef BatchExperimentConfigLoader < ConfigLoader
    %BATCHEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = BatchExperimentConfigLoader(configs,commonConfigFile)          
            obj = obj@ConfigLoader(configs,commonConfigFile);                        
        end
        function [] = runExperiments(obj,multithread)
            inputFile = obj.configs('inputFile');
            inputCommonFile = obj.configs('inputCommonFile');
            %outputFilePrefix = obj.configs('outputFilePrefix');
            paramsToVary = obj.configs('paramsToVary');
            
            experimentLoader = ExperimentConfigLoader.CreateConfigLoader(...
                inputFile,inputCommonFile);
            
            assert(numel(paramsToVary) == 1);
            baseConfigs = experimentLoader.configs;
            if nargin >= 2
                baseConfigs('multithread') = multithread;
            end
            for i=1:numel(paramsToVary)
                param = paramsToVary{i};
                values = obj.configs(param);
                for j=1:numel(values)
                    val = values{j};
                    configCopy = baseConfigs;
                    configCopy(param) = val;
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

