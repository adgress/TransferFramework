classdef ActiveMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Dependent)
        transferDirectory
        labelsToUse
    end        
    
    
    
    methods
        function [obj] = ActiveMainConfigs()
            obj = obj@MainConfigs();        
            useSeparableDistanceMatrix = true;
            obj.setTommasiData();
            
            pc = ProjectConfigs.Create();
            
            obj.configsStruct.numLabeledPerClass=pc.numLabeledPerClass;
            
            learnerConfigs = obj.makeDefaultLearnerConfigs();                  
            learnerConfigs.set('useSeparableDistanceMatrix',useSeparableDistanceMatrix);                        
            
            activeConfigs = Configs();            
            %obj.configsStruct.activeMethodObj=RandomActiveMethod(activeConfigs);
            %obj.configsStruct.activeMethodObj=EntropyActiveMethod(activeConfigs);
            obj.configsStruct.activeMethodObj=TargetEntropyActiveMethod(activeConfigs);
            %obj.configsStruct.activeMethodObj=VarianceMinimizationActiveMethod(activeConfigs);            
            
            transferMeasureConfigs = obj.makeDefaultLearnerConfigs();
            transferMeasureConfigs.set('useSeparableDistanceMatrix',useSeparableDistanceMatrix);
            
            %obj.configsStruct.learners=LLGCMethod(learnerConfigs);
            %obj.configsStruct.transferMeasure = LLGCTransferMeasure(transferMeasureConfigs);
            
            transferMeasureConfigs.set('learner',LogisticRegressionMethod(learnerConfigs));
            obj.set('transferMeasure',MethodTransferMeasure(transferMeasureConfigs));
            obj.set('learners',LogisticRegressionMethod(learnerConfigs));
            
            obj.configsStruct.labelBudget = 10;
            %obj.configsStruct.labelsToUse = pc.labelsToUse;            
            
            switch pc.data
                case Constants.CV_DATA
                case Constants.TOMMASI_DATA
                    obj.set('targetLabels',[10 15]);
                    obj.set('sourceLabels',[25 26]);
                case Constants.NG_DATA
                otherwise
                    error('Unknown data set');
            end
            
            obj.set('sigmaScale',.2);
            obj.set('k',inf);
            obj.set('alpha',.9);
        end                                           
        
        function [] = setCVData(obj)      
            setCVData@MainConfigs(obj);
            obj.configsStruct.numSourcePerClass=Inf;
            obj.configsStruct.dataSet='ADW2C';
            obj.configsStruct.sourceDataSetToUse = {'A'};
        end                    
        
        function [t,s] = GetTargetSourceLabels(obj)
            t = obj.get('targetLabels');
            s = obj.get('sourceLabels');
        end    
        function [labelProduct] = MakeLabelProduct(obj)
            [t,s] = obj.GetTargetSourceLabels();                        
            targetDomains = Helpers.MakeCrossProductOrdered(t,t);
            %sourceDomains = Helpers.MakeCrossProductNoDupe(sourceLabels,sourceLabels);
            sourceDomains = Helpers.MakeCrossProductOrdered(s,s);
            labelProduct = Helpers.MakeCrossProduct(targetDomains,sourceDomains);
        end
        function [v] = get.labelsToUse(obj)
            v = obj.get('targetLabels');
        end
    end        
    
end

