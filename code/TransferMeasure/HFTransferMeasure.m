classdef HFTransferMeasure < TransferMeasure
    %SCTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = HFTransferMeasure(configs)
            obj = obj@TransferMeasure(configs);
        end
        
        function [measureResults] = computeMeasure(obj,source,target,...
                options)            
            useHF = true;
            [measureResults] = ...
                obj.computeGraphMeasure(source,target,options,...
                useHF);            
        end
        
        function [name] = getPrefix(obj)
            name = 'HF';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'useSoftLoss','useMeanSigma'};
        end
    end   
end

