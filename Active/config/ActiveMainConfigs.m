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
                                    
            obj.configsStruct.learners=LLGCMethod(learnerConfigs);                                               
            
            activeConfigs = Configs();            
            obj.configsStruct.activeMethodObj=RandomActiveMethod(activeConfigs);
            %obj.configsStruct.activeMethodObj=EntropyActiveMethod(activeConfigs);
            %obj.configsStruct.activeMethodObj=TargetEntropyActiveMethod(activeConfigs);
            %obj.configsStruct.activeMethodObj=VarianceMinimizationActiveMethod(activeConfigs);            
            
            learnerConfigs.set('useSoftLoss',true)
            obj.configsStruct.transferMeasure = LLGCTransferMeasure(learnerConfigs);
            
            obj.configsStruct.labelBudget = 40;            
            obj.configsStruct.labelsToUse = c.labelsToUse;
            
        end                                           
        
        function [] = setCVData(obj)      
            setCVData@MainConfigs(obj);
            obj.configsStruct.numSourcePerClass=Inf;
            %obj.configsStruct.sourceDataSetToUse = {{'A'},{'C'},{'D'},{'W'}};
            %{
            obj.configsStruct.dataSet='ADW2C';
            obj.configsStruct.sourceDataSetToUse = {'A'};
            %}
            obj.configsStruct.dataSet='ACW2D';
            obj.configsStruct.sourceDataSetToUse = {'W'};
        end                                
    end        
    
end

