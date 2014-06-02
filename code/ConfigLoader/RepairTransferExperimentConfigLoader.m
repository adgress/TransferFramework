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
            results.postTransferMeasureVal = {};
            results.transferMeasureMetadata = {};
            results.traintTestMetadata = {};
            
            [sampledTrain,test,sources,validate,m,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex,savedData);
            [transferOutput,trainTestInput] = ...
                obj.performTransfer(sampledTrain,test,sources,validate,m,...
                experiment);                
            metadata = m;
            
            
            configsCopy = obj.configs;   
            configsCopy('useSourceForTransfer') = true;
            measureObject = LLGCTransferMeasure(configsCopy);
                               
            debugMode = 0;
            if ~debugMode || ~exist('targetScores.mat','file')
                [postTransferMeasureVal,targetScores,...
                    results.transferMeasureMetadata{1}] = ...
                    measureObject.computeMeasure(...
                    transferOutput.tSource,...
                    transferOutput.tTarget,...
                    transferOutput.metadata);
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
                        
            repairObj = LLGCTransferRepair(obj.configs);
            
            for i=1:numIterations+1
                if i > 1
                    [trainTestInput] = repairObj.repairTransfer(...
                        trainTestInput,...
                        results.labeledTargetScores{i-1});
                    sourceData = trainTestInput.train.getSourceData();
                    targetData = trainTestInput.train.getTargetData();
                    targetData = DataSet.Combine(targetData,...
                        trainTestInput.test);
                    [results.postTransferMeasureVal{i},results.labeledTargetScores{i},...
                        results.transferMeasureMetadata{i}] = ...
                        measureObject.computeMeasure(sourceData,...
                        targetData,struct());
                end
                if i > 1 || ~debugMode || ~exist('repairResults.mat','file')
                    [repairResults,results.traintTestMetadata{i}]...
                        = obj.trainAndTest(trainTestInput,experiment);         
                    if debugMode && i == 1
                        save('repairResults','repairResults');
                    end
                else
                    load repairResults
                end
                results.repairResults{i} = repairResults;
            end
        end                       
        %{
        function [outputFileName] = getOutputFileName(obj)
            s = getProjectConstants();            
            outputDir = [s.projectDir '/' obj.configs('outputDir')];
            if obj.configs('useMeanSigma')
                outputDir = [outputDir '-useMeanSigma/'];
                if ~exist(outputDir,'dir')
                    mkdir(outputDir);
                end
            else
                outputDir = [outputDir '/'];
            end
            outputDir = [outputDir obj.configs('dataSet') '/'];
            if ~exist(outputDir,'dir')
                mkdir(outputDir);
            end
            methodClasses = obj.configs('methodClasses');
            assert(length(methodClasses) == 1);
            methodClassName = methodClasses{1};
            
            transferClassName = obj.configs('transferMethodClass');
            repairClassName = obj.configs('repairMethod');
            methodPrefix = Method.GetPrefix(methodClassName,obj.configs);
            transferPrefix = Transfer.GetPrefix(transferClassName,obj.configs);
            repairFileName = TransferRepair.GetResultFileName(repairClassName,obj.configs);
            outputFileName = [outputDir repairFileName '-' methodPrefix '-' transferPrefix '.mat'];
        end      
        %}
    end 
end

