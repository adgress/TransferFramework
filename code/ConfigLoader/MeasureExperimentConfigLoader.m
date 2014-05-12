classdef MeasureExperimentConfigLoader < TransferExperimentConfigLoader
    %MEASUREEXPERIMENTCONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = MeasureExperimentConfigLoader(configs,commonConfigFile)
            obj = obj@TransferExperimentConfigLoader(configs,commonConfigFile);               
        end 
        
        function [results, metadata] = ...
                runExperiment(obj,experimentIndex,splitIndex,savedData)                                    
            
            [sampledTrain,test,sources,validate,m,experiment,numPerClass] = ...
                prepareDataForTransfer(obj,experimentIndex,splitIndex,savedData);
            metadata = m;
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
                    results.preTransferPerLabelMeasures{1}] = ...
                    measureObj.computeMeasure(sources{1},...
                    target,obj.configs);
            end
            
            if ~isempty(obj.configs('postTransferMeasures'))
                configsCopy('useSourceForTransfer') = 1;
                [transferOutput,~] = ...
                    obj.performTransfer(sampledTrain,test,sources,validate,metadata,...
                    experiment);                
                postTransferMeasures = obj.configs('postTransferMeasures');
                measureFunc = str2func(postTransferMeasures{1});
                measureObject = measureFunc(configsCopy);                                
                results.postTransferMeasureVal = {};
                results.postTransferPerLabelMeasures = {};
                [results.postTransferMeasureVal{1},...
                    results.postTransferPerLabelMeasures{1}] = ...
                    measureObject.computeMeasure(transferOutput.tSource,...
                    transferOutput.tTarget,transferOutput.metadata);                                                
            end
            results.metadata = obj.constructResultsMetadata(sources,...
                sampledTrain,test,numPerClass);            
        end
        function [outputFileName] = getOutputFileName(obj)
            outputDir = [obj.configs('outputDir') '/' obj.configs('dataSet') '/'];
            if ~exist(outputDir,'dir')
                mkdir(outputDir);
            end
            measures = obj.configs('postTransferMeasures');
            measureClass = str2func(measures{1});
            measureObject = measureClass(obj.configs);
            measureFileName = measureObject.getResultFileName();
            
            transferMethodClass = obj.configs('transferMethodClass');
            methodPrefix = Transfer.GetPrefix(...
                transferMethodClass,obj.configs);
            outputFileName = [outputDir measureFileName ...
                '_' methodPrefix '.mat'];
        end
    end
    
end

