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
            obj.configsStruct.activeMethodObj=EntropyAllActiveMethod(activeConfigs);
            %obj.configsStruct.activeMethodObj=TargetEntropyActiveMethod(activeConfigs);
            %obj.configsStruct.activeMethodObj=VarianceMinimizationActiveMethod(activeConfigs);            
            
            transferMeasureConfigs = obj.makeDefaultLearnerConfigs();
            transferMeasureConfigs.set('useSeparableDistanceMatrix',useSeparableDistanceMatrix);                                                                      
            
            obj.set('learners',LogisticRegressionMethod(learnerConfigs));
            transferMeasureConfigs.set('learner',LogisticRegressionMethod(learnerConfigs));
            %{
            alpha = [.1 1 10];
            learnerConfigs.set('alpha',alpha);
            obj.configsStruct.learners=LLGCMethod(learnerConfigs);
            transferMeasureConfigs.set('learner',LLGCMethod(learnerConfigs));
            obj.set('alpha',alpha);
            %}
            obj.set('transferMeasure',MethodTransferMeasure(transferMeasureConfigs));
            
            
            obj.configsStruct.activeIterations = ProjectConfigs.activeIterations;
            obj.configsStruct.labelsPerIteration = ProjectConfigs.labelsPerIteration;
            %obj.configsStruct.labelsToUse = pc.labelsToUse;            
            
            switch pc.data
                case Constants.CV_DATA
                case Constants.TOMMASI_DATA
                    if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE_TRANSFER
                        obj.set('targetLabels',[10 15]);
                        obj.set('sourceLabels',[25 26]);
                    end
                case Constants.NG_DATA
                case Constants.HOUSING_DATA
                case Constants.YEAST_BINARY_DATA
                case Constants.USPS_DATA
                otherwise
                    error('Unknown data set');
            end
            
            obj.set('sigmaScale',.2);
            obj.set('k',inf);            
        end                                           
        
        function [] = setCVData(obj)      
            setCVData@MainConfigs(obj);
            obj.configsStruct.numSourcePerClass=Inf;
            obj.configsStruct.dataSet='ADW2C';
            obj.configsStruct.sourceDataSetToUse = {'A'};
        end   
        
        function [] = setHousingBinaryData(obj)      
            setHousingBinaryData@MainConfigs(obj);
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
        
        function [] = setNGData(obj)
            setNGData@MainConfigs(obj);                        
            %obj.set('dataSet','CR2CR3CR4ST1ST2ST3ST42CR1');
            %obj.set('dataSet','CR1CR3CR4ST1ST2ST3ST42CR2');
            %obj.set('dataSet','CR1CR2CR4ST1ST2ST3ST42CR3');
            obj.set('dataSet','CR1CR2CR3ST1ST2ST3ST42CR4');
            %obj.set('sourceDataSetToUse',{'ST4'});
        end
        
    end        
    
end

