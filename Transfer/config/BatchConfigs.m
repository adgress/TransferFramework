classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();                        
            obj.configsStruct.experimentConfigsClass=TransferMainConfigs();
            obj.configsStruct.paramsToVary={'dataSet','sourceDataSetToUse'};
            obj.configsStruct.transferMethodClassStrings = {'FuseTransfer','Transfer'};            
            obj.configsStruct.experimentConfigsClass.setNumLabeled();
            obj.setTransferData();
        end
        
        function [] = setTransferData(obj)
            obj.configsStruct.dataSet={'ACD2W','ACW2D','ADW2C','CDW2A'};
            obj.configsStruct.sourceDataSetToUse = {{'A'},{'C'},{'D'},{'W'}};
        end
        
        function [] = setNNConfigs(obj)
            obj.configsStruct.experimentConfigsClass.setNNConfigs();
        end
        
        function [] = setLLGCConfigs(obj)
            obj.configsStruct.experimentConfigsClass.setLLGCConfigs();
            obj.set('experimentConfigLoader', ...
                'TransferExperimentConfigLoader');  
            obj.c.experimentConfigsClass.set('numLabeledPerClass',ProjectConfigs.numLabeled);
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
        
        function [] = setMeasureConfigs(obj)
            obj.configsStruct.transferMethodClassStrings = {'FuseTransfer'};
            e = obj.c.experimentConfigsClass;
            e.configsStruct.experimentConfigLoader='MeasureExperimentConfigLoader';                          
            %learnerConfigs.set('strategy','None');
            e.setLLGCMeasureConfigs();
            %e.setCTMeasureConfigs();
            e.set('processMeasureResults',true);
            
            pc = ProjectConfigs.Create();
            m = LLGCTransferMeasure();
            m.set('quiet',1);
            m.set('sigmaScale',pc.sigmaScale);
            m.set('alpha',pc.alpha);
            m.set('useSourceForTransfer',true);
            
            %TODO: I think this is used for repair
            %e.set('measureObj',m);
            e.set('saveINV',false);
            e.set('fixSigma',false);
            e.set('numLabeledPerClass',ProjectConfigs.numLabeled);            
            
            obj.set('experimentConfigLoader', ...
                'MeasureExperimentConfigLoader');
        end
        
        function [] = setRepairConfigs(obj,sourceNoise)
            obj.configsStruct.transferMethodClassStrings = {'FuseTransfer'};
            e = obj.c.experimentConfigsClass;
            e.configsStruct.experimentConfigLoader='RepairTransferExperimentConfigLoader';                          
            %learnerConfigs.set('strategy','None');
            e.setLearnerLLGC();                                  
            
            pc = ProjectConfigs.Create();
            m = LLGCTransferMeasure();
            m.set('quiet',1);
            m.set('sigmaScale',pc.sigmaScale);
            m.set('alpha',pc.alpha);
            m.set('useSourceForTransfer',true);
            
            e.set('measureObj',m);
            e.set('saveINV',false);
            e.set('numIterations',3);
            e.set('fixSigma',false);
            e.set('numLabeledPerClass',3);
            e.set('sourceNoise',0);
            
            learnerConfigs = e.makeDefaultLearnerConfigs();
            learnerConfigs.set('percToRemove',.05);
            learnerConfigs.set('strategy','Exhaustive');
            e.configsStruct.repairMethod = TransferRepair(learnerConfigs);            
            e.configsStruct.repairMethod.set('repairTransferMeasure',...
                m);
            
            obj.set('experimentConfigLoader', ...
                'RepairTransferExperimentConfigLoader');
        end
    end
end

