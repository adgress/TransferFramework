classdef TransferMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = TransferMainConfigs()
            obj = obj@MainConfigs();
            %obj.configsStruct.dataName = 'CV';
            obj.configsStruct.dataName='CV-small';
            %obj.configsStruct.dataName='CV-norm=0;
            obj.configsStruct.dataDir='Data';
            obj.configsStruct.resultsDir='results';
            obj.configsStruct.transferDir='Data/transferData';
            obj.configsStruct.outputDir='results';
            obj.configsStruct.dataSet='A2C';
            
            obj.configsStruct.multithread=1;
            %obj.configsStruct.numLabeledPerClass=[2 3 4 5];
            obj.configsStruct.numLabeledPerClass=2:3;
            obj.configsStruct.rerunExperiments=0;
            
            obj.configsStruct.computeLossFunction=1;
            obj.configsStruct.processMeasureResults=1;
            obj.configsStruct.useSoftLoss=1;
            
            obj.configsStruct.preTransferMeasures={};
            obj.configsStruct.postTransferMeasures={};
            obj.configsStruct.measureClass='Measure';
            
            learnerConfigs = LearnerConfigs();
            learnerConfigs.configsStruct.useCMN=0;
            learnerConfigs.configsStruct.zscore=1;
            learnerConfigs.configsStruct.useMeanSigma=0;            
            learnerConfigs.configsStruct.k=1;            
            learnerConfigs.configsStruct.zscore=1;
            learnerConfigs.configsStruct.useECT=0;
            learnerConfigs.configsStruct.fixSigma=1;
            learnerConfigs.configsStruct.saveINV=1;
            learnerConfigs.configsStruct.sourceLOOCV=0;
            learnerConfigs.configsStruct.quiet=0;
            
            % Transfer Repair configs
            learnerConfigs.configsStruct.percToRemove=.035;
            learnerConfigs.configsStruct.numIterations=3;
            
            llgcObj = LLGCMethod(learnerConfigs);
            obj.configsStruct.learners={llgcObj};
            %obj.configsStruct.methodClasses={'LLGCMethod'};
            %obj.configsStruct.methodClasses={'NearestNeighborMethod'};
            %obj.configsStruct.methodClasses={'HFMethod','LLGCMethod','NearestNeighborMethod'};
            %obj.configsStruct.methodClasses={'LLGCMethod','NearestNeighborMethod'};
            obj.configsStruct.experimentConfigLoader='ExperimentConfigLoader';
            
        end
    end
    
end

