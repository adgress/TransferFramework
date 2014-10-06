classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();
            obj.configsStruct.dataSet={'W2D','A2C','A2D','A2W','C2A','C2D','C2W','D2A','D2C','D2W','W2A','W2C','A2A','C2C','D2D','W2W'};
            %obj.configsStruct.dataSet={'W2D','A2C','A2D','A2W','C2A','C2D','C2W','D2A','D2C','D2W','W2A','W2C'};
            %obj.configsStruct.dataSet={'A2C','A2D','A2W','C2A','C2D','C2W','D2A','D2C','D2W','W2A','W2C','W2D'};
            %obj.configsStruct.inputCommonFile='config/experiment/experimentCommon.cfg';
            obj.configsStruct.experimentConfigsClass=str2func('TransferMainConfigs');
            obj.configsStruct.paramsToVary={'dataSet'};
        end
        
        
    end
    
end

