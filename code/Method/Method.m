classdef Method < Saveable
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configs
    end
    methods
        function obj = Method(configs)            
            obj.configs = configs;
        end
        function n = getDisplayName(obj)
            n = obj.getPrefix();
        end
    end
    methods(Abstract)
        [testResults,metadata] = ...
            trainAndTest(obj,input)   
    end        
end

