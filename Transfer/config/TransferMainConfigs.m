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
            obj.setLLGCConfigs(learnerConfigs);
            
            obj.configsStruct.multithread=1;                  
            obj.configsStruct.rerunExperiments=1;
            
            obj.configsStruct.computeLossFunction=1;
            obj.configsStruct.processMeasureResults=0;
                        
            obj.configsStruct.measureClass='Measure';
        end   
        
        function [] = setNumLabeled(obj)
            obj.configsStruct.numLabeledPerClass=2:3;
            obj.configsStruct.numSourcePerClass=15;
        end
        
        function [] = setNumSource(obj)
            obj.configsStruct.numLabeledPerClass=3;
            obj.configsStruct.numSourcePerClass=5:5:15;
        end
        
        function [] = setCVData(obj)
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
        
        function [] = setTommasiData(obj)
            obj.set('dataName','tommasi_data');
            obj.set('resultsDir','results_tommasi');
            obj.set('dataSet','tommasi_split_data');            
            obj.configsStruct.numLabeledPerClass=2:2:8;
            obj.configsStruct.numSourcePerClass=Inf;
            obj.delete('labelsToUse');
        end
        
        function [] = setCTMeasureConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            obj.configsStruct.experimentConfigLoader='MeasureExperimentConfigLoader';
            %obj.configsStruct.preTransferMeasures=LLGCTransferMeasure(learnerConfigs);
            %obj.configsStruct.postTransferMeasures=LLGCTransferMeasure(learnerConfigs);
            obj.configsStruct.learners=[];
            obj.configsStruct.preTransferMeasures=[];
            obj.configsStruct.postTransferMeasures=CTTransferMeasure(learnerConfigs);
        end
        
        function [] = setLLGCMeasureConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            obj.configsStruct.learners=[];
            obj.configsStruct.experimentConfigLoader='MeasureExperimentConfigLoader';
            obj.configsStruct.preTransferMeasures=LLGCTransferMeasure(learnerConfigs);
            obj.configsStruct.postTransferMeasures=LLGCTransferMeasure(learnerConfigs);                        
        end        
        
        function [] = setLLGCConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            obj.configsStruct.experimentConfigLoader='TransferExperimentConfigLoader';  
            obj.setLearnerLLGC(learnerConfigs);
        end
        
        function [] = setLearnerLLGC(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            llgcObj = LLGCMethod(learnerConfigs);
            obj.configsStruct.learners=llgcObj;
        end
        
        function [] = setNNConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            obj.configsStruct.experimentConfigLoader='TransferExperimentConfigLoader';  
            nnObj = NearestNeighborMethod(learnerConfigs);
            obj.configsStruct.learners=nnObj;
        end
        
        function [learnerConfigs] = makeDefaultLearnerConfigs(obj)
            learnerConfigs = LearnerConfigs();            
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

