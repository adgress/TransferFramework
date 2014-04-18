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
            experiment = obj.allExperiments{experimentIndex};
            
            [train,test,validate] = obj.getSplit(splitIndex);            
            [numTrain,numPerClass] = obj.calculateSampling(experiment,test);
            
            [sampledTrain] = train.stratifiedSampleByLabels(numTrain);
            sources = obj.dataAndSplits.sourceDataSets;
            assert(numel(sources) == 1);
            
            metadata = struct();
            metadata.configs = savedData.configs;
            metadata.metadata = savedData.metadata{experimentIndex,splitIndex};
                        
            %{
            if ~isempty(obj.configs('preTransferMeasure'))
                preTransferMeasure = str2func(obj.configs('preTransferMeasure'));
                measureObj = preTransferMeasure(obj.configs);
                target = DataSet('','','',[sampledTrain.X ; test.X],...
                    [sampledTrain.Y ; zeros(size(test.Y,1),1)]);
                m.preTransferMeasure = ...
                    measureObj.computeMeasure(sources{1},target,obj.configs);

                results.preTransferMeasureVal = m.preTransferMeasure;
                %results.trainPerformance = metadata.preTransferMeasure;
                %results.testPerformance = metadata.preTransferMeasure;
            end
            %}
            if ~isempty(obj.configs('postTransferMeasures'))                
                [transferOutput,~] = ...
                    obj.performTransfer(sampledTrain,test,sources,validate,metadata,...
                    experiment);
                results.postTransferMeasureVal = {};
                postTransferMeasures = obj.configs('postTransferMeasures');
                measureFunc = str2func(postTransferMeasures{1});
                measureObject = measureFunc(obj.configs);                                
                results.postTransferMeasureVal{1} = ...
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
            measurePrefix = measureObject.getResultFileName();
            
            transferMethodClass = obj.configs('transferMethodClass');
            methodPrefix = Transfer.GetPrefixForMethod(...
                transferMethodClass,obj.configs);
            outputFileName = [outputDir measurePrefix ...
                '_' methodPrefix '.mat'];
        end
    end
    
end

