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
    end        
    
end

