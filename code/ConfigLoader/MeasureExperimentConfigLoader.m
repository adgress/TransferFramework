classdef MeasureExperimentConfigLoader < TransferExperimentConfigLoader
    %MEASUREEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = MeasureExperimentConfigLoader(configs)
            obj = obj@TransferExperimentConfigLoader(configs);               
        end 
        
        function [results] = ...
                runExperiment(obj,experimentIndex,splitIndex)                                    
            %error('What should we do with measureMetadata?');
            [sampledTrain,test,sources,validate,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex);
            measureMetadata = struct();            
            if ~isempty(obj.configs.get('preTransferMeasures'))                
                preTransferMeasures = obj.configs.get('preTransferMeasures');                
                measureObj = preTransferMeasures{1};           
                measureObj.configs.set('useSourceForTransfer',0);
                type = [DataSet.TargetTrainType(sampledTrain.size()) ;...
                    DataSet.TargetTestType(test.size())];
                target = DataSet('','','',[sampledTrain.X ; test.X],...
                    [sampledTrain.Y ; -1*ones(size(test.Y))],...
                    type);
                results.preTransferMeasureVal = {};
                results.preTransferPerLabelMeasures = {};
                [results.preTransferMeasureVal{1},...
                    results.preTransferPerLabelMeasures{1},...
                    measureMetadata.preMetadata] = ...
                    measureObj.computeMeasure(sources{1},...
                    target,obj.configs);
            end
            
            if ~isempty(obj.configs.get('postTransferMeasures'))                
                [transferOutput,~] = ...
                    obj.performTransfer(sampledTrain,test,sources,validate,...
                    experiment);                
                postTransferMeasures = obj.configs.get('postTransferMeasures');               
                measureObject = postTransferMeasures{1};
                measureObject.configs.set('useSourceForTransfer',1);
                results.postTransferMeasureVal = {};
                results.postTransferPerLabelMeasures = {};
                
                [results.postTransferMeasureVal{1},...
                    results.postTransferPerLabelMeasures{1},...
                    measureMetadata.postMetadata] = ...
                    measureObject.computeMeasure(transferOutput.tSource,...
                    transferOutput.tTarget,obj.configs);                                                
            end
            measureObj.configs.delete('useSourceForTransfer');
            results.trainingDataMetadata = obj.constructTrainingDataMetadata(sources,...
                sampledTrain,test,numPerClass);    
            results.measureMetadata = measureMetadata;            
        end       
    end
    
end

