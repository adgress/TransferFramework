classdef LLGCTransferMeasure < TransferMeasure
    %SCTRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LLGCTransferMeasure(configs)
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@TransferMeasure(configs);
        end
        
        function [measureResults,savedData] = computeMeasure(obj,source,target,...
                options,savedData)            
            if ~exist('savedData','var')
                savedData = struct();
            end
            useHF = false;            
            [measureResults,savedData] = ...
                obj.computeGraphMeasure(source,target,options,...
                useHF,savedData);            
        end
                
        function [name] = getPrefix(obj)
            name = 'LLGC';
        end      
    end    
end

