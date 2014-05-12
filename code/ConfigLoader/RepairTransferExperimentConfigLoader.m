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
            
            results = struct;
            results.repairResults = {};
            results.repairMetadata = {};
            results.labeledTargetScores = {};
            results.trainTestInput = {};
            results.postTransferMeasureVal = {};
            
            [sampledTrain,test,sources,validate,m,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex,savedData);
            [results.transferOutput,results.trainTestInput{1}] = ...
                obj.performTransfer(sampledTrain,test,sources,validate,m,...
                experiment);                
            metadata = m;
            
            
            configsCopy = obj.configs;   
            configsCopy('useSourceForTransfer') = true;
            measureObject = LLGCTransferMeasure(configsCopy);
                               
            debugMode = 0;
            if ~debugMode || ~exist('targetScores.mat','file')
                [postTransferMeasureVal,targetScores] = ...
                    measureObject.computeMeasure(...
                    results.transferOutput.tSource,...
                    results.transferOutput.tTarget,...
                    results.transferOutput.metadata);
                if debugMode
                    save('targetScores','targetScores');
                    save('postTransferMeasureVal','postTransferMeasureVal');
                end
            else
                load targetScores
                load postTransferMeasureVal
            end
            results.labeledTargetScores{1} = targetScores;
            results.postTransferMeasureVal{1} = postTransferMeasureVal;
            numIterations = obj.configs('numIterations');
            percToRemove = obj.configs('percToRemove');
            
            experiment.methodClass = obj.configs('methodClass');
            repairObj = LLGCTransferRepair(obj.configs);
           
            for i=1:numIterations+1
                if i > 1
                    [results.trainTestInput{i}] = repairObj.repairTransfer(...
                        results.trainTestInput{i-1},...
                        results.labeledTargetScores{i-1});
                    sourceData = results.trainTestInput{i}.train.getSourceData();
                    targetData = results.trainTestInput{i}.train.getTargetData();
                    targetData = DataSet.Combine(targetData,...
                        results.trainTestInput{i}.test);
                    [results.postTransferMeasureVal{i},results.labeledTargetScores{i}] = ...
                        measureObject.computeMeasure(sourceData,...
                        targetData,struct());
                end
                if i > 1 || ~debugMode || ~exist('repairResults.mat','file')
                    repairResults = obj.trainAndTest(...
                        results.trainTestInput{i},experiment);         
                    if debugMode && i == 1
                        save('repairResults','repairResults');
                    end
                else
                    load repairResults
                end
                results.repairResults{i} = repairResults;
            end
        end                       
        
        function [outputFileName] = getOutputFileName(obj)
            outputDir = [obj.configs('outputDir') '/' obj.configs('dataSet')];
            if ~exist(outputDir,'dir')
                mkdir(outputDir);
            end
            transferClassName = obj.configs('transferMethodClass');
            repairClassName = obj.configs('repairMethod');
            transferPrefix = Transfer.GetPrefix(transferClassName,obj.configs);
            repairFileName = TransferRepair.GetResultFileName(repairClassName,obj.configs);
            outputFileName = [outputDir repairFileName '-' transferPrefix '.mat'];
        end          
    end 
end

