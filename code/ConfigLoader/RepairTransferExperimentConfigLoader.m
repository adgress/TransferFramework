classdef RepairTransferExperimentConfigLoader < TransferExperimentConfigLoader
    %TRANSFEREXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = RepairTransferExperimentConfigLoader(configs)
            obj = obj@TransferExperimentConfigLoader(configs);
        end                
        
        function [results] = ...
                runExperiment(obj,experimentIndex,splitIndex,savedData)
            
            results = RepairResults;
            results.learnerStats.repairAccuracy = [];
            
            repairObj = obj.get('repairMethod');
            
            %{
            error('What should we do with m?');
            [sampledTrain,test,sources,validate,m,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex,savedData);
            [transferOutput,trainTestInput] = ...
                obj.performTransfer(sampledTrain,test,sources,validate,m,...
                experiment);                
            %}
            [sampledTrain,test,sources,validate,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex);
            [transferOutput,trainTestInput] = ...
                obj.performTransfer(sampledTrain,test,sources,validate,...
                experiment);
            measureSavedData = struct();
            methodSavedData = struct();
            %{
            configsCopy = obj.configs;   
            configsCopy.set('useSourceForTransfer',true);
            %}
            transferMeasureObj = obj.get('measureObj');
            %measureObj = LLGCTransferMeasure(configsCopy);
            %{
            measureObj = TransferMeasure.ConstructObject(...
                obj.get('repairTransferMeasure'),configsCopy);
            %}
            %{
            obj.set('saveINV',false);
            measureObj.set('quiet',1);
            measureObj.set('sigmaScale',.2);
            measureObj.set('alpha',.9);
            %}
            if obj.get('saveINV')  
                error('TODO: fixed input, output');
                [postTransferMeasureResults,~,...
                    results.transferMeasureMetadata{1},...
                    measureSavedData] = ...
                    transferMeasureObj.computeMeasure(...
                    transferOutput.tSource,...
                    transferOutput.tTarget,...
                    transferOutput.metadata,...
                    measureSavedData);
            else
                %{
                [postTransferMeasureVal,~,...
                    results.transferMeasureMetadata{1}] = ...
                    measureObj.computeMeasure(...
                    transferOutput.tSource,...
                    transferOutput.tTarget,...
                    transferOutput.metadata);
                %}
                [results.postTransferMeasureResults{1}] = ...
                    transferMeasureObj.computeMeasure(...
                    transferOutput.tSource,...
                    transferOutput.tTarget,...
                    repairObj.configs);
            end
            measureSavedData.postTransferMeasureVal = results.postTransferMeasureResults{1};
            
            %results.labeledTargetScores{1} = results.transferMeasureMetadata{1}.labeledTargetScores;
            results.labeledTargetScores{1} = results.postTransferMeasureResults{1}.labeledTargetScores;
            numIterations = obj.get('numIterations');
                        
            
            
            Helpers.RemoveKey(repairObj.configs,'sigma');
            Helpers.RemoveKey(obj.configs,'sigma');
            Helpers.RemoveKey(transferMeasureObj.configs,'sigma');
            
            results.repairMetadata{1} = struct();
            measureObject = Measure.ConstructObject('Measure',obj.configs);             
            obj.set('quiet',1);            
            for i=1:numIterations+1
                if i > 1                    
                    if obj.get('fixSigma')
                        transferMeasureObj.configs('sigma') = results.transferMeasureMetadata{i-1}.sigma;
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
                    if obj.get('saveINV')   
                        error('Update input output');
                        [results.postTransferMeasureVal{i},~,...
                            results.transferMeasureMetadata{i},...
                            measureSavedData] = ...
                            transferMeasureObj.computeMeasure(sourceData,...
                            targetData,struct(),...
                            measureSavedData);
                    else
                        [results.postTransferMeasureResults{i}] = ...
                            transferMeasureObj.computeMeasure(...
                            {sourceData},...
                            targetData,...
                            repairObj.configs);
                        %{
                        [results.postTransferMeasureVal{i},~,...
                            results.transferMeasureMetadata{i}] = ...
                            transferMeasureObj.computeMeasure(sourceData,...
                            targetData,struct());
                        %}
                    end
                    results.labeledTargetScores{i} = ...
                        results.postTransferMeasureResults{i}.labeledTargetScores;
                    %results.labeledTargetScores{i} = results.transferMeasureMetadata{i}.labeledTargetScores;
                    %measureSavedData.postTransferMeasureVal = results.postTransferMeasureVal{i};
                end
                if i > 1 && obj.get('fixSigma');
                    obj.set('sigma',results.trainTestMetadata{i-1}.sigma);
                end
                trainTestInput.learner = obj.get('learners');
                if obj.get('saveINV')
                    %{
                    [repairResults,results.trainTestMetadata{i},methodSavedData]...
                        = obj.trainAndTest(trainTestInput,experiment,methodSavedData);
                    %}
                    [repairResults,methodSavedData]...
                        = obj.trainAndTest(trainTestInput,experiment,methodSavedData);
                else
                    %{
                    [repairResults,results.trainTestMetadata{i}]...
                        = obj.trainAndTest(trainTestInput,experiment);
                    %}
                    [repairResults,~]...
                        = obj.trainAndTest(trainTestInput,experiment);
                end
                s = measureObject.evaluate(repairResults);
                results.learnerStats.repairAccuracy(i) = s.learnerStats.testResults;
                if i > 1
                    diff = results.learnerStats.repairAccuracy(i) - ...
                        results.learnerStats.repairAccuracy(i-1);
                    Helpers.PrintNum('Method Perf Diff: ', diff);
                end
                results.repairResults{i} = repairResults;
            end
        end                             
    end 
end

