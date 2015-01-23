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
        
        function [] = setCOIL20(obj,classNoise)            
            obj.configsStruct.dataName='COIL20';
            obj.configsStruct.dataDir='Data';
            obj.configsStruct.resultsDir='results';
            obj.configsStruct.outputDir='results';
            obj.configsStruct.dataSet='splits';
            if classNoise > 0
                obj.configsStruct.dataSet = [obj.configsStruct.dataSet ...
                    '-classNoise=' num2str(classNoise)];
            end
        end
      
        function [] = setTommasiData(obj)
            obj.set('dataName','tommasi_data');
            obj.set('resultsDir','results_tommasi');
            obj.set('dataSet','tommasi_split_data');            
            obj.configsStruct.numSourcePerClass=Inf;
            obj.delete('labelsToUse');
        end
        
        
        function [] = setLLGCWeightedConfigs(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            c = ProjectConfigs.Create();
            obj.configsStruct.experimentConfigLoader='ExperimentConfigLoader';  
            llgcObj = LLGCWeightedMethod(learnerConfigs);
           	llgcObj.set('unweighted',c.useUnweighted);
            llgcObj.set('oracle',c.useOracle);
            llgcObj.set('sort',c.useSort);
            llgcObj.set('justTarget',c.useJustTarget);
            llgcObj.set('dataSetWeights',c.useDataSetWeights);
            llgcObj.set('useOracleNoise',c.useOracleNoise);
            llgcObj.set('classNoise',c.classNoise);        
            llgcObj.set('justTargetNoSource',c.useJustTargetNoSource);
            llgcObj.set('robustLoss',c.useRobustLoss);
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

