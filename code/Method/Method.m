classdef Method < handle
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    methods
        function obj = Method()            
        end
    end
    methods(Abstract)
        [testResults,metadata] = ...
            trainAndTest(obj,input)   
    end    
    methods(Abstract,Static)
        name = getMethodName(configs)
    end
    methods(Static)
        function name = getMethodNameForMethod(methodClass,configs)
            name = eval([methodClass '.getMethodName(configs);']);
        end
    end
end

