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
            
            pc = ProjectConfigs.Create();
            
            obj.configsStruct.numLabeledPerClass=pc.numLabeledPerClass;
            learnerConfigs = obj.makeDefaultLearnerConfigs();                              
            learnerConfigs.set('cvReg',pc.reg);
            learnerConfigs.set('cvAlpha',pc.alpha);
            learnerConfigs.set('cvSigma',pc.sigma);
            
            obj.configsStruct.learners=[];
            %obj.setLLGCConfigs(learnerConfigs);            
            obj.setHypothesisTransferConfigs(learnerConfigs);
            
            obj.configsStruct.measure=Measure();
            %obj.set('targetLabels',[10 15]);
            %obj.set('sourceLabels',[23 25 26 30]);
            obj.set('targetLabels',[]);
            obj.set('sourceLabels',[]);
        end                                                     
        
        function [] = setHypothesisTransferConfigs(obj,learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            c = ProjectConfigs.Create();
            obj.configsStruct.configLoader=ExperimentConfigLoader();
            llgcObj = LLGCHypothesisTransfer(learnerConfigs);
           	llgcObj.set('unweighted',c.useUnweighted);
            llgcObj.set('oracle',c.useOracle);
            llgcObj.set('sort',c.useSort);
            llgcObj.set('justTarget',c.useJustTarget);
            llgcObj.set('dataSetWeights',c.useDataSetWeights);
            llgcObj.set('useOracleNoise',c.useOracleNoise);
            llgcObj.set('labelNoise',c.labelNoise);        
            llgcObj.set('justTargetNoSource',c.useJustTargetNoSource);
            llgcObj.set('robustLoss',c.useRobustLoss);
            llgcObj.set('measure',obj.get('measure'));
            llgcObj.set('noTransfer',c.noTransfer);
            obj.configsStruct.learners=llgcObj;
        end
        
        function [] = setLLGCWeightedConfigs(obj, learnerConfigs)
            warning('Where is this being called from?');
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            c = ProjectConfigs.Create();
            obj.configsStruct.configLoader=ExperimentConfigLoader();
            llgcObj = LLGCWeightedMethod(learnerConfigs);
           	llgcObj.set('unweighted',c.useUnweighted);
            llgcObj.set('oracle',c.useOracle);
            llgcObj.set('sort',c.useSort);
            llgcObj.set('justTarget',c.useJustTarget);
            llgcObj.set('dataSetWeights',c.useDataSetWeights);
            llgcObj.set('useOracleNoise',c.useOracleNoise);
            llgcObj.set('labelNoise',c.labelNoise);        
            llgcObj.set('justTargetNoSource',c.useJustTargetNoSource);
            llgcObj.set('robustLoss',c.useRobustLoss);
            obj.configsStruct.learners=llgcObj;
        end                                           
    end        
    
end

