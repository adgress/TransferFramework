classdef ExperimentConfigs < Configs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = ExperimentConfigs()
            obj = obj@Configs();
            obj.configsStruct.dataName = 'CV';
            %obj.configsStruct.dataName='CV-small';
            %obj.configsStruct.dataName='CV-norm=0;
            obj.configsStruct.dataDir='Data';
            obj.configsStruct.resultsDir='results';
            obj.configsStruct.transferDir='Data/transferData';
            obj.configsStruct.outputDir='results';
            obj.configsStruct.dataSet='A2C';
            
            obj.configsStruct.multithread=1;
            obj.configsStruct.numLabeledPerClass=[2 3 4 5];
            obj.configsStruct.rerunExperiments=0;
            
            obj.configsStruct.computeLossFunction=1;
            obj.configsStruct.processMeasureResults=1;
            obj.configsStruct.useCMN=0;
            obj.configsStruct.useSoftLoss=1;
            
            obj.configsStruct.preTransferMeasures={};
            obj.configsStruct.postTransferMeasures={};
            obj.configsStruct.methodClasses={'LLGCMethod'};
            %obj.configsStruct.methodClasses={'NearestNeighborMethod'};
            %obj.configsStruct.methodClasses={'HFMethod','LLGCMethod','NearestNeighborMethod'};
            %obj.configsStruct.methodClasses={'LLGCMethod','NearestNeighborMethod'};
            obj.configsStruct.experimentConfigLoader='ExperimentConfigLoader';
            obj.configsStruct.k=1;
            obj.configsStruct.measureClass='Measure';
            obj.configsStruct.zscore=1;
            obj.configsStruct.useMeanSigma=0;
            obj.configsStruct.useECT=0;
            obj.configsStruct.fixSigma=1;
            obj.configsStruct.saveINV=1;
            obj.configsStruct.sourceLOOCV=0;
            obj.configsStruct.quiet=0;
            
            % Transfer Repair configs
            obj.configsStruct.percToRemove=.035;
            obj.configsStruct.numIterations=3;
        end
    end
    
end

