classdef TransferRepair < Saveable
    %TRANSFERREPAIR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
        
    methods
        function [obj] = TransferRepair(configs)
            obj = obj@Saveable(configs);
        end
        function [d] = getDirectory(obj)
            d = 'REP';
        end
    end
    methods(Abstract)
        [repairedTransferOutput] = repairTransfer(obj,input);
    end
    
end

