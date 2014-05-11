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
            experiment = obj.allExperiments{experimentIndex};                                    
                                    
            [train,test,validate] = obj.getSplit(splitIndex);            
            [numTrain,numPerClass] = obj.calculateSampling(experiment,test);
            
            [sampledTrain] = train.stratifiedSampleByLabels(numTrain);
            sources = obj.dataAndSplits.sourceDataSets;
            for i=1:length(sources)
                sources{i}.setSource;
            end
            sampledTrain.setTargetTrain();
            train.setTargetTrain();
            test.setTargetTest();
            validate.setTargetTrain();
            assert(numel(sources) == 1);
            
            m = struct();
            m.configs = savedData.configs;
                        
            [transferOutput,trainTestInput] = ...
                obj.performTransfer(sampledTrain,test,sources,validate,m,...
                experiment);            
                        
            assert(trainTestInput.train.hasTypes());
            assert(trainTestInput.test.isTarget());
            assert(trainTestInput.originalSourceData.isSource());
            
            repairMethod = obj.configs('repairMethod');
            metadata = {};
            results = {};
        end                       
        
        function [outputFileName] = getOutputFileName(obj)
            outputDir = [obj.configs('outputDir') '/' obj.configs('dataSet') '/REP/' ];
            if ~exist(outputDir,'dir')
                mkdir(outputDir);
            end
            transferClassName = obj.configs('transferMethodClass');
            repairClassName = obj.configs('repairMethod');
            transferPrefix = Transfer.GetPrefix(transferClassName,obj.configs);
            repairPrefix = RepairTransferExperimentConfigLoader.GetPrefix(repairClassName,obj.configs);
            outputFileName = [outputDir repairPrefix '-' transferPrefix '.mat'];
        end          
    end 
end

