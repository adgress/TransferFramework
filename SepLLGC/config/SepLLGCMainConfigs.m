classdef SepLLGCMainConfigs < MainConfigs
    %EXPERIMENTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Dependent)
        transferDirectory
    end
    
    methods
        function [obj] = SepLLGCMainConfigs()
            obj = obj@MainConfigs();            
            obj.setTommasiData();
            
            c = ProjectConfigs.Create();
            
            obj.configsStruct.numLabeledPerClass=c.numLabeledPerClass;
            learnerConfigs = obj.makeDefaultLearnerConfigs();                  
                        
            obj.configsStruct.learners=[];
            obj.setLLGCConfigs(learnerConfigs);            
                        
            obj.configsStruct.measure=Measure();
            obj.configsStruct.dataDir='Data';
            %obj.configsStruct.labelsToUse=[10 15];
        end                           
        
        function [] = setHousingBinaryData(obj)
            obj.set('dataName','housingBinary');
            obj.set('resultsDir','results_housing');
            obj.set('dataSet','housing_split_data');            
            obj.delete('labelsToUse');
        end     
        
        function [] = setYeastBinaryData(obj)
            obj.set('dataName','yeastBinary');
            obj.set('resultsDir','results_yeast');
            obj.set('dataSet','yeastBinary_split_data');            
            obj.delete('labelsToUse');
        end
    end        
    
end

