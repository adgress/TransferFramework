classdef TransferRepair < Saveable
    %TRANSFERREPAIR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [d] = getDirectory(obj)
            d = 'REP';
        end
    end
    methods(Abstract)
        [results] = repairTransfer(obj,input);
    end
    
end

