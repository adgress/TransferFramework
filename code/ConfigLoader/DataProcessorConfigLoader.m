classdef DataProcessorConfigLoader < ConfigLoader
    %DATAPROCESSOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rawData
        processedData
    end
    
    methods
        function obj = DataProcessorConfigLoader(configFile)
            error('TODO');
            obj = obj@ConfigLoader(configFile);    
            
        end
        function [] = processData(obj,overwrite)
            inputFile = obj.configs('inputFile');            
            outputFile = obj.configs('outputFile');
            if exists(outputFile,'file') && ~overwrite
                display('Returning - processed data already exists');
                return
            end
            obj.rawData = loadData(inputFile,configs);
            obj.processedData = StaticProcessData(obj.rawData,configs);
            saveData(obj.processedData,outputFile,configs);
        end
    end
    
    methods(Access=protected,Static)
        function [rawData] = loadData(file,configs)
            checkFile(file);
            rawData = load(file);
        end
        
        function [processedData] = StaticProcessData(rawData,configs)            
            processedData = struct();
            processedData.rawData = rawData;
            processedData.dataConfigs = configs;
        end
        
        function [] = saveData(processedData,saveFile,configs)
            save(saveFile,processedData);
        end
    end
    
end

