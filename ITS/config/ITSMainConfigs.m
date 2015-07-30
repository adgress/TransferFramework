classdef ITSMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function [obj] = ITSMainConfigs()
            pc = ProjectConfigs.Create();
            obj = obj@MainConfigs();            
            obj.setITSData(pc.dataSetName);           
            
            obj.configsStruct.numLabeledPerClass=pc.numLabeledPerClass;
            learnerConfigs = obj.makeDefaultLearnerConfigs();                  
                        
            obj.configsStruct.learners=[];
            learnerConfigs.set('combineGraphFunc',pc.combineGraphFunc);
            learnerConfigs.set('evaluatePerfFunc',pc.evaluatePerfFunc);
            learnerConfigs.set('alpha',pc.alpha);
            learnerConfigs.set('sigma',pc.sigma);
            learnerConfigs.delete('sigmaScale');
            learnerConfigs.set('measure',pc.measure);
            useLLGC = 1;
            
            if pc.useStudentData
                if useLLGC
                    learnerConfigs.set('cvParameters',pc.llgcCVParams);
                    obj.setLLGCConfigs(learnerConfigs);
                else
                    learnerConfigs.set('cvParameters',pc.nwCVParams);
                    obj.setNW(learnerConfigs);                
                end                
            else               
                if useLLGC
                    learnerConfigs.set('makeRBF',false);
                    learnerConfigs.set('cvParameters',pc.llgcCVParams(1));
                    %learnerConfigs.set('makeRBF',true);
                    %learnerConfigs.set('cvParameters',pc.llgcCVParams);
                    obj.setLLGCConfigs(learnerConfigs);
                else
                    %obj.setITSRandom(learnerConfigs);                
                    %obj.setITSConstant(learnerConfigs);
                    
                    learnerConfigs.set('cvParameters',[]);
                    obj.setITSMethod(learnerConfigs);
                end
            end
            obj.configsStruct.measure=pc.measure;
            
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

