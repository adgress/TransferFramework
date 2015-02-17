classdef MeasureExperimentConfigLoader < TransferExperimentConfigLoader
    %MEASUREEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = MeasureExperimentConfigLoader(configs)
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@TransferExperimentConfigLoader(configs);               
        end 
        function [resultsStruct] = runTransferMeasureExperiment(obj, ...
                measureObj, target, source, measureKey)                           
            resultsStruct = struct();            
            [measureResults] = ...
                measureObj.computeMeasure(source,target,obj.configs);
            val = measureResults.percCorrect;
            if measureObj.configs.get('useSoftLoss') 
                val = measureResults.score;
            end
            resultsStruct.transferMeasureVal = val;
            resultsStruct.transferPerLabelMeasures = ...
                measureResults.perLabelMeasures;
            resultsStruct.measureMetadata = measureResults.measureMetadata;
            resultsStruct.measureResults = measureResults;
        end
        function [results] = ...
                runExperiment(obj,experimentIndex,splitIndex)                                    
            %error('What should we do with measureMetadata?');
            [sampledTrain,test,sources,validate,experiment,numPerClass] = ...
                obj.prepareDataForTransfer(experimentIndex,splitIndex);
            results = struct();
            preTransferMeasureKey = 'preTransferMeasures';
            if ~isempty(obj.configs.get(preTransferMeasureKey))                  
                type = [DataSet.TargetTrainType(sampledTrain.size()) ;...
                    DataSet.TargetTestType(test.size())];
                target = DataSet('','','',[sampledTrain.X ; test.X],...
                    [sampledTrain.Y ; -1*ones(size(test.Y))],...
                    type);
                target.trueY = target.Y;
                measureObj = obj.get(preTransferMeasureKey);
                measureObj.set('useSourceForTransfer',0);
                [results.preTransferResults] = runTransferMeasureExperiment(obj, ...
                    measureObj,target, sources);      
                measureObj.delete('useSourceForTransfer');
            end
            postTransferMeasureKey = 'postTransferMeasures';
            if ~isempty(obj.configs.get(postTransferMeasureKey))
                [transferOutput,~] = ...
                    obj.performTransfer(sampledTrain,test,sources,validate,...
                    experiment); 
                measureObj = obj.get(postTransferMeasureKey);
                measureObj.set('useSourceForTransfer',1);
                [results.postTransferResults] = runTransferMeasureExperiment(obj, ...
                    measureObj, transferOutput.tTarget, transferOutput.tSource);  
                measureObj.delete('useSourceForTransfer');
            end
            results.trainingDataMetadata = obj.constructTrainingDataMetadata(sources,...
                sampledTrain,test,numPerClass);    
            %results.measureMetadata = measureMetadata;
        end       
    end
    
end

