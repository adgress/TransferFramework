classdef ITSMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function [obj] = ITSMainConfigs()
            pc = ProjectConfigs.Create();
            obj = obj@MainConfigs();         
            obj.set('labelsToUse',pc.labelsToUse);
            
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
            
            %Don't use inverse method until matrix caching is figured out
            %learnerConfigs.set('useInv',1);
            learnerConfigs.set('useInv',0);
            learnerConfigs.set('inferSubset',0);
            learnerConfigs.set('zscore',0);
            if pc.useStudentData
                if pc.useLLGC
                    learnerConfigs.set('cvParameters',pc.llgcCVParams);                    
                    learnerConfigs.set('makeRBF',true);
                    obj.setLLGCConfigs(learnerConfigs);                    
                elseif pc.useMean
                    obj.setMeanConfigs(learnerConfigs);   
                elseif pc.useLogReg
                    error('update!');
                    obj.setLogisticRegressionConfigs(learnerConfigs);
                elseif pc.useLinReg
                    learnerConfigs.set('cvParameters',pc.linRegCVParams);
                    obj.setLinearRegressionConfigs(learnerConfigs);                    
                elseif pc.useAddMod
                    learnerConfigs.set('cvParameters',pc.addModCVParams);
                    learnerConfigs.set('sigmaVals',pc.sigmaVals);
                    obj.setAdditiveModel(learnerConfigs);                    
                else
                    learnerConfigs.set('cvParameters',pc.nwCVParams);
                    learnerConfigs.set('makeRBF',true);
                    learnerConfigs.set('classification',false);
                    obj.setNW(learnerConfigs);     
                    
                end                
            else               
                if pc.useLLGC
                    if pc.makeRBF
                        learnerConfigs.set('convertToSim',true);
                        learnerConfigs.set('makeRBF',true);
                        learnerConfigs.set('cvParameters',pc.llgcCVParams);
                    else                                                
                        learnerConfigs.set('makeRBF',false);
                        learnerConfigs.set('cvParameters',pc.llgcCVParams(1));
                    end                    
                    obj.setLLGCConfigs(learnerConfigs);
                else                                        
                    learnerConfigs.set('cvParameters',pc.nwCVParams);
                    learnerConfigs.set('convertToSim',true);
                    learnerConfigs.set('makeRBF',true);
                                        
                    obj.setITSMethod(learnerConfigs);
                    
                    %obj.setITSRandom(learnerConfigs);                    
                    %learnerConfigs.set('sigma',1);
                    %learnerConfigs.set('cvParameters',[]);
                    %obj.setITSConstant(learnerConfigs);                    
                end
            end
            obj.configsStruct.measure=pc.measure;
            if pc.QQEdgesExperiment
                obj.configsStruct.configLoader=QQEdgeExperimentConfigLoader();
            else
                obj.configsStruct.configLoader=ExperimentConfigLoader();
            end
            nameParams = {'source','target'};
            obj.c.learners.set('nameParams',nameParams);
            obj.c.learners.set('source',pc.sourceLabels);
            obj.c.learners.set('target',pc.targetLabels);
            if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE
                
                obj.configsStruct.activeMethodObj = ...
                    RandomActiveMethod(Configs());
                
                %{
                obj.configsStruct.activeMethodObj = ...
                    DistanceActiveMethod(Configs());
                %}
                %{
                obj.configsStruct.activeMethodObj = ...
                    VarianceEstimateActiveMethod(Configs());
                %}
                obj.set('activeIterations',pc.activeIterations);
                obj.set('numLabelsPerIteration',pc.numLabelsPerIteration);
                a = ActiveExperimentConfigLoader();
                m = ActiveLearningL2Measure();
                a.set('measure',m);
                obj.set('configLoader',a);
                obj.set('measure',m);
            end
        end    
        
        function [] = setITSData(obj,dataSet)
            pc = ProjectConfigs.Create();
            if ~exist('dataSet','var')
                dataSet = 'DS1';
            end
            obj.set('dataName','ITS');
            obj.set('resultsDir',['results_' dataSet]);
            %{
            if pc.QQEdgesExperiment
                obj.set('resultsDir',['results_' dataSet '-QQEdges=' num2str(pc.QQEdges)]);
            end
            %}
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

