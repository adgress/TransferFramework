classdef LLGCTransferMeasure < TransferMeasure
    %SCTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LLGCTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [measureResults] = computeMeasure(obj,source,target,...
                options)            
            useHF = false;
            [measureResults] = ...
                obj.computeGraphMeasure(source,target,options,...
                useHF);            
        end
                
        function [name] = getPrefix(obj)
            name = 'LLGC';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'useSoftLoss','useMeanSigma'};
        end
    end    
end

