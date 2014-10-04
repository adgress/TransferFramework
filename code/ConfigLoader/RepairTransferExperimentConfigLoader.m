classdef RepairTransferExperimentConfigLoader < TransferExperimentConfigLoader
    %TRANSFEREXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = RepairTransferExperimentConfigLoader(...
                configs,configsClass)
            obj = obj@TransferExperimentConfigLoader(configs,configsClass);
        end                
        
        function [results, metadata] = ...
                runExperiment(obj,experimentIndex,splitIndex,savedData)
            
            results = struct;
            results.repairResults = {};
            results.repairMetadata = {};
            results.labeledTargetScores = {};
            results.postTransferMeasureVal = {};
            results.transferMeasureMetadata = {};
            results.trainTestMetadata = {};
            results.perf = [];
            
            [sampledTrain,test,sources,validate,m,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex,savedData);
            [transferOutput,trainTestInput] = ...
                obj.performTransfer(sampledTrain,test,sources,validate,m,...
                experiment);                
            metadata = m;
            
            measureSavedData = struct();
            methodSavedData = struct();
            
            configsCopy = obj.configs;   
            configsCopy('useSourceForTransfer') = true;
            %measureObject = LLGCTransferMeasure(configsCopy);
            measureObj = TransferMeasure.ConstructObject(...
                obj.configs('repairTransferMeasure'),configsCopy);
            measureObj.configs('quiet') = 1;
            if obj.configs('saveINV')                
                [postTransferMeasureVal,~,...
                    results.transferMeasureMetadata{1},...
                    measureSavedData] = ...
                    measureObj.computeMeasure(...
                    transferOutput.tSource,...
                    transferOutput.tTarget,...
                    transferOutput.metadata,...
                    measureSavedData);
            else
                [postTransferMeasureVal,~,...
                    results.transferMeasureMetadata{1}] = ...
                    measureObj.computeMeasure(...
                    transferOutput.tSource,...
                    transferOutput.tTarget,...
                    transferOutput.metadata);
            end
            results.postTransferMeasureVal{1} = postTransferMeasureVal;
            measureSavedData.postTransferMeasureVal = results.postTransferMeasureVal{1};
            
            results.labeledTargetScores{1} = results.transferMeasureMetadata{1}.labeledTargetScores;            
            numIterations = obj.configs('numIterations');
                        
            repairObj = TransferRepair.ConstructObject(...
                obj.configs('repairMethod'),obj.configs);
            
            Helpers.RemoveKey(repairObj.configs,'sigma');
            Helpers.RemoveKey(obj.configs,'sigma');
            Helpers.RemoveKey(measureObj.configs,'sigma');
            
            results.repairMetadata{1} = struct();
            measureObject = Measure.ConstructObject('Measure',obj.configs);             
            obj.configs('quiet') = 1;
            for i=1:numIterations+1
                if i > 1                    
                    if obj.configs('fixSigma')
                        measureObj.configs('sigma') = results.transferMeasureMetadata{i-1}.sigma;
                        repairObj.configs('sigma') = results.trainTestMetadata{i-1}.sigma;
                    end                    
                    measureSavedData.experiment = experiment;
                    measureSavedData.methodSavedData = methodSavedData;
                    measureSavedData.o = obj;
                    [trainTestInput,results.repairMetadata{i}] = ...
                        repairObj.repairTransfer(...
                        trainTestInput,...
                        results.labeledTargetScores{i-1},...
                        measureSavedData);
                    sourceData = trainTestInput.train.getSourceData();
                    targetData = trainTestInput.train.getTargetData();
                    targetData = DataSet.Combine(targetData,...
                        trainTestInput.test);
                    targetData.removeTestLabels();
                    if obj.configs('saveINV')                        
                        [results.postTransferMeasureVal{i},~,...
                            results.transferMeasureMetadata{i},...
                            measureSavedData] = ...
                            measureObj.computeMeasure(sourceData,...
                            targetData,struct(),...
                            measureSavedData);
                    else
                        [results.postTransferMeasureVal{i},~,...
                            results.transferMeasureMetadata{i}] = ...
                            measureObj.computeMeasure(sourceData,...
                            targetData,struct());
                    end
                    results.labeledTargetScores{i} = results.transferMeasureMetadata{i}.labeledTargetScores;
                    measureSavedData.postTransferMeasureVal = results.postTransferMeasureVal{i};
                end
                if i > 1 && obj.configs('fixSigma');
                    obj.configs('sigma') = results.trainTestMetadata{i-1}.sigma;
                end
                if obj.configs('saveINV')
                    [repairResults,results.trainTestMetadata{i},methodSavedData]...
                        = obj.trainAndTest(trainTestInput,experiment,methodSavedData);
                else
                    [repairResults,results.trainTestMetadata{i}]...
                        = obj.trainAndTest(trainTestInput,experiment);
                end
                s = measureObject.evaluate(repairResults);
                results.perf(i) = s.testPerformance;
                if i > 1
                    Helpers.PrintNum('Method Perf Diff: ', results.perf(i) - results.perf(1));
                end
                results.repairResults{i} = repairResults;
            end
        end                               
    end 
end

