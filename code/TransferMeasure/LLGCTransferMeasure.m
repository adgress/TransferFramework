classdef LLGCTransferMeasure < TransferMeasure
    %SCTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LLGCTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [val,perLabelMeasures,metadata] = computeMeasure(obj,source,target,...
                options)            
            metadata = {};                                                
            useHF = false;
            [score,percCorrect,Ypred,Yactual,perLabelMeasures,val] = ...
                computeGraphMeasure(obj,source,target,options,...
                useHF);            
        end                    
        
        function [name] = getPrefix(obj)
            name = 'LLGC';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'useSoftLoss'};
        end
    end    
end

