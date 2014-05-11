classdef RepairTransferExperimentConfigLoader < TransferExperimentConfigLoader
    %TRANSFEREXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = RepairTransferExperimentConfigLoader(...
                configs,commonConfigFile)
            obj = obj@TransferExperimentConfigLoader(configs,commonConfigFile);
        end                
        
        function [results, metadata] = ...
                runExperiment(obj,experimentIndex,splitIndex,savedData)                      
            [sampledTrain,test,sources,validate,m,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex)                        
            [transferOutput,trainTestInput] = ...
                obj.performTransfer(sampledTrain,test,sources,validate,m,...
                experiment);    
            
            repairMethod = obj.configs('repairMethod');
            metadata = {};
            results = {};
        end                       
        
        function [outputFileName] = getOutputFileName(obj)
            outputDir = [obj.configs('outputDir') '/' obj.configs('dataSet')];
            if ~exist(outputDir,'dir')
                mkdir(outputDir);
            end
            transferClassName = obj.configs('transferMethodClass');
            repairClassName = obj.configs('repairMethod');
            transferPrefix = Transfer.GetResultsFileName(transferClassName,obj.configs);
            repairPrefix = RepairTransferExperimentConfigLoader. ...
                GetResultsFileName(repairClassName,obj.configs);
            outputFileName = [outputDir repairPrefix '-' transferPrefix '.mat'];
        end          
    end 
end

