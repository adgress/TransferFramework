classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();
            %obj.configsStruct.dataSet={'W2D','A2C','A2D','A2W','C2A','C2D','C2W','D2A','D2C','D2W','W2A','W2C'};            
            obj.configsStruct.dataSet={'ACD2W','ACW2D','ADW2C','CDW2A'};
            obj.configsStruct.sourceDataSetToUse = {{'A'},{'C'},{'D'},{'W'},{'A','C','D','W'}};
            %obj.configsStruct.sourceDataSetToUse = {{'A','C','D','W'}};
            obj.configsStruct.experimentConfigsClass=TransferMainConfigs();
            obj.configsStruct.paramsToVary={'dataSet','sourceDataSetToUse'};
            obj.configsStruct.transferMethodClassStrings = {'FuseTransfer','Transfer'};            
            obj.configsStruct.experimentConfigsClass.setNumLabeled();
        end
        
        function [] = setNNConfigs(obj)
            obj.configsStruct.experimentConfigsClass.setNNConfigs();
        end
        
        function [] = setLLGCConfigs(obj)
            obj.configsStruct.experimentConfigsClass.setLLGCConfigs();
        end
        
        function [] = setTommasiData(obj)
            obj.set('dataSet','tommasi_split_data');
            obj.get('experimentConfigsClass').setTommasiData();
            obj.configsStruct.paramsToVary={};
            obj.set('makeSubDomains',true);
        end
        
        function [] = setCTMeasureConfigs(obj)
            obj.configsStruct.transferMethodClassStrings = {'FuseTransfer'};
            obj.configsStruct.experimentConfigsClass.setCTMeasureConfigs();
        end
        
        function [] = setLLGCMeasureConfigs(obj)
            obj.configsStruct.transferMethodClassStrings = {'FuseTransfer'};
            obj.configsStruct.experimentConfigsClass.setLLGCMeasureConfigs();
        end
    end
end

