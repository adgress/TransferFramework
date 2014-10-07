classdef Method < Saveable
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    methods
        function obj = Method(configs)            
            obj = obj@Saveable(configs);
        end
        function n = getDisplayName(obj)
            n = obj.getPrefix();
        end
    end
    methods(Abstract)
        [testResults,savedData] = ...
            trainAndTest(obj,input,savedData)   
    end        
end

