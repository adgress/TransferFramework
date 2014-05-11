classdef LLGCTransferRepair < TransferRepair       
    properties
        configs
    end
    
    methods
        function obj = LLGCTransferRepair(configs)
            obj.configs = configs;
        end        
        function [prefix] = getPrefix(obj)
            prefix = 'LLGC';
        end        
        function [nameParams] = getNameParams(obj)
            nameParams = {'numPerIteration','numIterations'}
        end
    end
    
    
end

