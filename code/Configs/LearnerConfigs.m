classdef LearnerConfigs < Configs
    %CONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    properties(Constant)
    end
    
    properties(Dependent)
    end
    
    methods               
        function [obj] = LearnerConfigs()
            obj = obj@Configs();    
            obj.configsStruct.zscore=1;
            obj.configsStruct.useMeanSigma=0;            
            obj.configsStruct.k=1;            
            obj.configsStruct.zscore=1;
            obj.configsStruct.useECT=0;
            obj.configsStruct.fixSigma=1;
            obj.configsStruct.saveINV=1;
            obj.configsStruct.sourceLOOCV=0;
            obj.configsStruct.quiet=0;
            obj.configsStruct.useSoftLoss=0; 
            
            % Transfer Repair configs
            obj.configsStruct.percToRemove=.035;
            obj.configsStruct.numIterations=3;       
            
            obj.configsStruct.alpha = .9;
            obj.configsStruct.sigmaScale = .2;
        end        
    end        
end

