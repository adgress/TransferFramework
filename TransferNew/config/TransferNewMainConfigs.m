classdef TransferNewMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Dependent)
        transferDirectory
    end
    
    methods
        function [obj] = TransferNewMainConfigs()
            obj = obj@MainConfigs();            
                        
            
            pc = ProjectConfigs.Create();
            
            obj.configsStruct.numLabeledPerClass=pc.numLabeledPerClass;
            learnerConfigs = obj.makeDefaultLearnerConfigs();                              
            learnerConfigs.set('cvReg',pc.reg);
            learnerConfigs.set('cvRegTransfer',pc.regTransfer);
            learnerConfigs.set('cvSigma',pc.sigma);
            
            obj.configsStruct.learners=[];
            %obj.setLLGCConfigs(learnerConfigs);          
            switch ProjectConfigs.experimentSetting
                case ProjectConfigs.SPARSITY_TRANFER_EXPERIMENT
                    obj.configsStruct.measure=L2Measure();
                    obj.setHypothesisTransferConfigs(learnerConfigs);
                case ProjectConfigs.INEQUALITY_TRANSFER_EXPERIMENT
                    obj.configsStruct.measure=L2Measure();
                    obj.setInequalityTransferConfigs(learnerConfigs);
                case ProjectConfigs.HYPOTHESIS_TRANSFER_EXPERIMENT
                    obj.configsStruct.measure=Measure();
                    obj.LLGCHypothesisTransferConfigs(learnerConfigs);
            end
            
            
            sourceLearner = NWMethod(learnerConfigs.copy());
            obj.set('sourceLearner',sourceLearner);
            %obj.set('targetLabels',[10 15]);
            %obj.set('sourceLabels',[23 25 26 30]);
            obj.set('targetLabels',[]);
            obj.set('sourceLabels',[]);
            
        end           
        function [] = LLGCHypothesisTransferConfigs(obj,learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            c = ProjectConfigs.Create();
            obj.configsStruct.configLoader=TransferExperimentConfigLoader();
            m = LLGCHypothesisTransfer(learnerConfigs);
            m.set('measure',obj.get('measure'));
            obj.configsStruct.learners=m;
        end
        function [] = setInequalityTransferConfigs(obj,learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            c = ProjectConfigs.Create();
            obj.configsStruct.configLoader=ExperimentConfigLoader();
            m = InequalityTransfer(learnerConfigs);
            m.set('measure',obj.get('measure'));
            obj.configsStruct.learners=m;
        end
        function [] = setHypothesisTransferConfigs(obj,learnerConfigs)
            if ~exist('learnerConfigs','var')
                learnerConfigs = obj.makeDefaultLearnerConfigs();
            end
            c = ProjectConfigs.Create();
            obj.configsStruct.configLoader=ExperimentConfigLoader();
            m = HypothesisTransfer(learnerConfigs);
            m.set('measure',obj.get('measure'));
            obj.configsStruct.learners=m;
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

