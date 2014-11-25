classdef LLGCMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Dependent)
        transferDirectory
    end
    
    methods
        function [obj] = LLGCMainConfigs()
            obj = obj@MainConfigs();            
            obj.setUSPS();
            %obj.configsStruct.numLabeledPerClass=2:2:8;
            obj.configsStruct.numLabeledPerClass=ProjectConfigs.numLabeledPerClass;
            learnerConfigs = obj.makeDefaultLearnerConfigs();                  
                        
            obj.configsStruct.learners=[];
            obj.setLLGCConfigs(learnerConfigs);
            %obj.setLLGCWeightedConfigs(learnerConfigs);
            
            obj.configsStruct.multithread=1;                  
            obj.configsStruct.rerunExperiments=0;
            
            obj.configsStruct.computeLossFunction=1;
            obj.configsStruct.processMeasureResults=0;
                        
            obj.configsStruct.measureClass='Measure';
        end           
        
        function [] = setUSPSSmall(obj)
            obj.setUSPS();
            obj.configsStruct.dataName='USPS-small';
        end
        
        function [] = setUSPS(obj)            
            obj.configsStruct.dataName='USPS';
            obj.configsStruct.dataDir='Data';
            obj.configsStruct.resultsDir='results';
            obj.configsStruct.outputDir='results';
            obj.configsStruct.dataSet='splits';
        end
        
        function [] = setCOIL20(obj)            
            obj.configsStruct.dataName='COIL20';
            obj.configsStruct.dataDir='Data';
            obj.configsStruct.resultsDir='results';
            obj.configsStruct.outputDir='results';
            obj.configsStruct.dataSet='splits';
        end
      
        
        function [] = setLLGCWeightedConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            obj.configsStruct.experimentConfigLoader='ExperimentConfigLoader';  
            llgcObj = LLGCWeightedMethod(learnerConfigs);
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
        
        function [s] = getDataFileName(obj)
            s = [getProjectDir() '/' obj.get('dataDir') '/' ...
                 '/' obj.get('dataName') '/' obj.get('dataSet') '.mat'];
        end
        
        function [v] = getResultsDirectory(obj)
            v = [getProjectDir() '/' obj.get('resultsDir') '/' ...
                 '/' obj.get('dataName') '/'];
        end      
    end
    
    methods(Static)
        
    end
    
end

