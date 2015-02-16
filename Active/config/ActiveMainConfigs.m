classdef ActiveMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Dependent)
        transferDirectory
    end
    
    methods
        function [obj] = ActiveMainConfigs()
            obj = obj@MainConfigs();            
            obj.setTommasiData();
            
            c = ProjectConfigs.Create();
            
            obj.configsStruct.numLabeledPerClass=c.numLabeledPerClass;
            
            learnerConfigs = obj.makeDefaultLearnerConfigs();                  
                        
            obj.configsStruct.learners=[];
            obj.configsStruct.learners=LLGCMethod(learnerConfigs);
            %obj.configsStruct.learners=HFMethod(learnerConfigs);
            
            %obj.configsStruct.activeMeasure = 
            
            obj.configsStruct.multithread=1;                  
            obj.configsStruct.rerunExperiments=0;
            
            obj.configsStruct.computeLossFunction=1;
            obj.configsStruct.processMeasureResults=0;
                        
            obj.configsStruct.measureClass='Measure';                        
            
            activeConfigs = Configs();            
            obj.configsStruct.activeMethodObj=RandomActiveMethod(activeConfigs);
            %obj.configsStruct.activeMethodObj=EntropyActiveMethod(activeConfigs);
            %obj.configsStruct.activeMethodObj=TargetEntropyActiveMethod(activeConfigs);
            %obj.configsStruct.activeMethodObj=VarianceMinimizationActiveMethod(activeConfigs);            
            
            learnerConfigs.set('useSoftLoss',true)
            obj.configsStruct.transferMeasure = LLGCTransferMeasure(learnerConfigs);
            
            obj.configsStruct.labelBudget = 40;
            obj.configsStruct.dataDir='Data';
            obj.configsStruct.labelsToUse = c.labelsToUse;
            
        end                           
        
        function [] = setTommasiData(obj)
            obj.set('dataName','tommasi_data');
            obj.set('resultsDir','results_tommasi');
            obj.set('dataSet','tommasi_split_data');            
            obj.configsStruct.numSourcePerClass=Inf;
        end
        
        function [] = setCVData(obj)
            obj.set('dataName','tommasi_data');
            obj.set('dataSet','tommasi_split_data');            
            obj.configsStruct.numSourcePerClass=Inf;
            
            obj.configsStruct.dataName='CV-small';            
            obj.configsStruct.dataDir='Data';
            obj.configsStruct.resultsDir='results';
            obj.configsStruct.transferDir='Data/transferData';
            obj.configsStruct.outputDir='results';            
            %obj.configsStruct.sourceDataSetToUse = {{'A'},{'C'},{'D'},{'W'}};
            %{
            obj.configsStruct.dataSet='ADW2C';
            obj.configsStruct.sourceDataSetToUse = {'A'};
            %}
            obj.configsStruct.dataSet='ACW2D';
            obj.configsStruct.sourceDataSetToUse = {'W'};
        end
        
        function [learnerConfigs] = makeDefaultLearnerConfigs(obj)
            learnerConfigs = LearnerConfigs();            
        end                  
    end        
    
end

