classdef ActiveMethod < Saveable
    %ACTIVEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ActiveMethod(configs)            
            obj = obj@Saveable(configs);
        end
        function n = getDisplayName(obj)
            n = obj.getPrefix();
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
        function [d] = getDirectory(obj)
            error('Do we save based on active method?');
        end
    end
    
    methods(Abstract)
        [queriedIdx,scores] = queryLabel(obj,input,results)   
    end  
    
end

