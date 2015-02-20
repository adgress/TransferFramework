classdef TransferMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Dependent)
        transferDirectory
    end
    
    methods
        function [obj] = TransferMainConfigs()
            obj = obj@MainConfigs();            
            obj.setCVData();
            obj.setNumLabeled();            
            
            learnerConfigs = obj.makeDefaultLearnerConfigs();                        
                        
            obj.configsStruct.preTransferMeasures=[];
            obj.configsStruct.postTransferMeasures={};
            obj.configsStruct.learners=[];
            
            obj.configsStruct.configLoader=TransferExperimentConfigLoader();  
            obj.setLearnerLLGC(learnerConfigs);            
                        
            obj.configsStruct.measure=Measure();
        end   
        
        function [] = setNumLabeled(obj)
            obj.configsStruct.numLabeledPerClass=2:3;
            obj.configsStruct.numSourcePerClass=15;
        end
        
        function [] = setNumSource(obj)
            obj.configsStruct.numLabeledPerClass=3;
            obj.configsStruct.numSourcePerClass=5:5:15;
        end
        
        function [] = setCVData_OLD(obj)
            noise = ProjectConfigs.sourceNoise;
            %obj.configsStruct.dataName = 'CV';
            obj.configsStruct.dataName='CV-small';
            if noise > 0
                obj.configsStruct.dataName= ['CV-small-' num2str(noise)];
            end
            obj.configsStruct.dataDir='Data';
            obj.configsStruct.resultsDir='results';
            obj.configsStruct.transferDir='Data/transferData';
            obj.configsStruct.outputDir='results';
            obj.configsStruct.dataSet='A2C';            
        end        
        
        function [] = setCTMeasureConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            obj.configsStruct.configLoader=MeasureExperimentConfigLoader();
            %obj.configsStruct.preTransferMeasures=LLGCTransferMeasure(learnerConfigs);
            %obj.configsStruct.postTransferMeasures=LLGCTransferMeasure(learnerConfigs);
            obj.configsStruct.learners=[];
            obj.configsStruct.preTransferMeasures=[];
            obj.configsStruct.postTransferMeasures=CTTransferMeasure(learnerConfigs);
            
            obj.configsStruct.measureLoss = FUMeasureLoss(obj);
            obj.configsStruct.measureLoss.set('justTarget',true);
        end
        
        function [] = setLLGCMeasureConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            obj.configsStruct.learners=[];
            obj.configsStruct.configLoader=MeasureExperimentConfigLoader();
            obj.configsStruct.preTransferMeasures=LLGCTransferMeasure(learnerConfigs);
            obj.configsStruct.postTransferMeasures=LLGCTransferMeasure(learnerConfigs);                        
            
            obj.configsStruct.measureLoss = MeasureLoss(obj);       
        end                             
        
        function [] = setNNConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            obj.configsStruct.configLoader=TransferExperimentConfigLoader();  
            nnObj = NearestNeighborMethod(learnerConfigs);
            obj.configsStruct.learners=nnObj;
        end
        
        function [s] = getDataFileName(obj)
            s = [getProjectDir() '/' obj.get('dataDir') '/' ...
                 '/' obj.get('dataName') '/' obj.get('dataSet') '.mat'];
        end
        
        function [v] = getResultsDirectory(obj)
            v = [getProjectDir() '/' obj.get('resultsDir') '/' ...
                 '/' obj.get('dataName') '/'];
        end
        function [v] = get.transferDirectory(obj)
            v = [obj.get('dataDir') '/' obj.get('transferDir') '/'];
        end        
    end
    
    methods(Static)
        
    end
    
end

