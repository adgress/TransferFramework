classdef TransferMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Dependent)
        transferDirectory
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
            obj.configsStruct.numLabeledPerClass=[2 3 4 5];
            %obj.configsStruct.numLabeledPerClass=2:3;
            obj.configsStruct.rerunExperiments=1;
            
            obj.configsStruct.computeLossFunction=1;
            obj.configsStruct.processMeasureResults=0;
                        
            obj.configsStruct.measureClass='Measure';
            
            learnerConfigs = LearnerConfigs();
            %learnerConfigs.configsStruct.trainSize=[.1 .2 .3 .4 .5 .6 .7 .8 .9 1];
            learnerConfigs.configsStruct.zscore=1;
            learnerConfigs.configsStruct.useMeanSigma=0;            
            learnerConfigs.configsStruct.k=1;            
            learnerConfigs.configsStruct.zscore=1;
            learnerConfigs.configsStruct.useECT=0;
            learnerConfigs.configsStruct.fixSigma=1;
            learnerConfigs.configsStruct.saveINV=1;
            learnerConfigs.configsStruct.sourceLOOCV=0;
            learnerConfigs.configsStruct.quiet=0;
            learnerConfigs.configsStruct.useSoftLoss=0;
            
            % Transfer Repair configs
            learnerConfigs.configsStruct.percToRemove=.035;
            learnerConfigs.configsStruct.numIterations=3;                        
            
            %obj.configsStruct.methodClasses={'LLGCMethod'};
            %obj.configsStruct.methodClasses={'NearestNeighborMethod'};
            %obj.configsStruct.methodClasses={'HFMethod','LLGCMethod','NearestNeighborMethod'};
            %obj.configsStruct.methodClasses={'LLGCMethod','NearestNeighborMethod'};
            obj.configsStruct.experimentConfigLoader='TransferExperimentConfigLoader';  
            obj.configsStruct.preTransferMeasures=[];
            obj.configsStruct.postTransferMeasures={};
            obj.configsStruct.learners={};
            
            runMeasures = 1;
            
            if runMeasures
                obj.configsStruct.experimentConfigLoader='MeasureExperimentConfigLoader';
                obj.configsStruct.preTransferMeasures=LLGCTransferMeasure(learnerConfigs);
                obj.configsStruct.postTransferMeasures=LLGCTransferMeasure(learnerConfigs);
                obj.configsStruct.learners={};
                
                
                obj.configsStruct.preTransferMeasures=[];
                obj.configsStruct.postTransferMeasures=CTTransferMeasure(learnerConfigs);
                
            else
                llgcObj = LLGCMethod(learnerConfigs);
                obj.configsStruct.learners={llgcObj};
            end
        end
        
        function [v] = getResultsDirectory(obj)
            v = [getProjectDir() '/' obj.get('resultsDir') '/' ...
                 '/' obj.get('dataName') '/'];
        end
        function [v] = get.transferDirectory(obj)
            v = [obj.get('dataDir') '/' obj.get('transferDir') '/'];
        end
        
    end
    
end

