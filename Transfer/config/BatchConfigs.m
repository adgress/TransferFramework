classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();
            obj.configsStruct.dataSet={'W2D','A2C','A2D','A2W','C2A','C2D','C2W','D2A','D2C','D2W','W2A','W2C','A2A','C2C','D2D','W2W'};            
            obj.configsStruct.experimentConfigsClass=TransferMainConfigs();
            obj.configsStruct.paramsToVary={'dataSet'};
            obj.configsStruct.transferMethodClassStrings = {'FuseTransfer','Transfer'};
            obj.configsStruct.experimentConfigsClass.setLLGCConfigs();
            obj.configsStruct.experimentConfigsClass.setNumLabeled();
        end        
    end
    
    methods(Static)
        function [obj] = MeasurementConfigs()
            obj = BatchConfigs();
            obj.configsStruct.transferMethodClassStrings = {'FuseTransfer'};
            learnerConfigs = LearnerConfigs();
            obj.configsStruct.experimentConfigsClass.setMeasureConcifgs(learnerConfigs);
        end
    end
    
end

