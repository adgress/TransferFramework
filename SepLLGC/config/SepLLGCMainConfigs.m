classdef SepLLGCMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Dependent)
        transferDirectory
    end
    
    methods
        function [obj] = SepLLGCMainConfigs()
            obj = obj@MainConfigs();            
            obj.setTommasiData();
            
            c = ProjectConfigs.Create();
            
            obj.configsStruct.numLabeledPerClass=c.numLabeledPerClass;
            learnerConfigs = obj.makeDefaultLearnerConfigs();                  
                        
            obj.configsStruct.learners=[];
            obj.setLLGCConfigs(learnerConfigs);
            
            obj.configsStruct.multithread=1;                  
            obj.configsStruct.rerunExperiments=0;
            
            obj.configsStruct.computeLossFunction=1;
            obj.configsStruct.processMeasureResults=0;
                        
            obj.configsStruct.measureClass='Measure';
            obj.configsStruct.dataDir='Data';
            %obj.configsStruct.labelsToUse=[10 15];
        end                           
        
        function [] = setTommasiData(obj)
            obj.set('dataName','tommasi_data');
            obj.set('resultsDir','results_tommasi');
            obj.set('dataSet','tommasi_split_data');            
            obj.delete('labelsToUse');
        end        
        
        function [] = setSepLLGCConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            %c = ProjectConfigs.Create();
            obj.configsStruct.experimentConfigLoader='ExperimentConfigLoader';  
            llgcObj = SepLLGCMethod(learnerConfigs);           	
            obj.configsStruct.learners=llgcObj;
        end
        
        
        function [] = setLLGCConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            obj.configsStruct.experimentConfigLoader='ExperimentConfigLoader';  
            llgcObj = LLGCMethod(learnerConfigs);
            obj.configsStruct.learners=llgcObj;
        end
        
        function [learnerConfigs] = makeDefaultLearnerConfigs(obj)
            learnerConfigs = LearnerConfigs();            
        end                  
    end        
    
end

