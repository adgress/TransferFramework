classdef ITSMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function [obj] = ITSMainConfigs()
            pc = ProjectConfigs.Create();
            obj = obj@MainConfigs();            
            obj.setITSData(pc.dataSetName);
            
            c = ProjectConfigs.Create();
            
            obj.configsStruct.numLabeledPerClass=c.numLabeledPerClass;
            learnerConfigs = obj.makeDefaultLearnerConfigs();                  
                        
            obj.configsStruct.learners=[];
            learnerConfigs.set('combineGraphFunc',pc.combineGraphFunc);
            learnerConfigs.set('evaluatePerfFunc',pc.evaluatePerfFunc);
            learnerConfigs.set('alpha',pc.alpha);
            learnerConfigs.set('sigma',pc.sigma);
            obj.setLLGCConfigs(learnerConfigs);
            %obj.setITSRandom(learnerConfigs);
            %obj.setITSMethod(learnerConfigs);
            %obj.setITSConstant(learnerConfigs);
                        
            obj.configsStruct.measure=c.measure;
            obj.configsStruct.configLoader=ExperimentConfigLoader();
        end    
        function [] = setITSData(obj,dataSet)
            if ~exist('dataSet','var')
                dataSet = 'DS1';
            end
            obj.set('dataName','ITS');
            obj.set('resultsDir',['results_' dataSet]);
            obj.set('dataSet',[dataSet '_split_data']);
        end
        function [] = setITSMethod(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end            
            methodObj = ITSMethod(learnerConfigs);
            obj.configsStruct.learners=methodObj;
        end
        function [] = setITSConstant(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            methodObj = ITSConstantMethod(learnerConfigs);
            obj.configsStruct.learners=methodObj;
        end
        function [] = setITSRandom(obj, learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            methodObj = ITSRandomMethod(learnerConfigs);
            obj.configsStruct.learners=methodObj;
        end
    end        
    
end

