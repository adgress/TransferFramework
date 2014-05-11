classdef Method < Saveable
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
end

