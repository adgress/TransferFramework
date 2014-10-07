classdef MeasureExperimentConfigLoader < TransferExperimentConfigLoader
    %MEASUREEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = MeasureExperimentConfigLoader(configs,configsClass)
            obj = obj@TransferExperimentConfigLoader(configs,configsClass);               
        end 
        
        function [results] = ...
                runExperiment(obj,experimentIndex,splitIndex,savedData)                                    
            error('What should we do with measureMetadata?');
            [sampledTrain,test,sources,validate,m,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex,savedData);
            measureMetadata = struct();
            configsCopy = obj.configs;
            if ~isempty(obj.configs('preTransferMeasures'))
                configsCopy('useSourceForTransfer') = 0;
                preTransferMeasures = obj.configs('preTransferMeasures');
                measureFunc = str2func(preTransferMeasures{1});                
                measureObj = measureFunc(configsCopy);
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
            
            if ~isempty(obj.configs('postTransferMeasures'))
                configsCopy('useSourceForTransfer') = 1;
                [transferOutput,~] = ...
                    obj.performTransfer(sampledTrain,test,sources,validate,measureMetadata,...
                    experiment);                
                postTransferMeasures = obj.configs('postTransferMeasures');
                measureFunc = str2func(postTransferMeasures{1});
                measureObject = measureFunc(configsCopy);                                
                results.postTransferMeasureVal = {};
                results.postTransferPerLabelMeasures = {};
                [results.postTransferMeasureVal{1},...
                    results.postTransferPerLabelMeasures{1},...
                    measureMetadata.postMetadata] = ...
                    measureObject.computeMeasure(transferOutput.tSource,...
                    transferOutput.tTarget,transferOutput.metadata);                                                
            end
            results.metadata = obj.constructResultsMetadata(sources,...
                sampledTrain,test,numPerClass);            
        end       
    end
    
end

