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
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
            a = obj.get('nameParams',{});
            for idx=1:length(a)
                s = a{idx};
                if obj.has(s)
                    nameParams{end+1} = s;
                end
            end
        end
        function [] = setParams(obj,params)
            for idx=1:length(params)
                k = params(idx).key;
                v = params(idx).value;
                obj.set(k,v);
            end
        end
        function [y] = train(obj,X,Y)
            error('Not implemented!');
        end
        function [y] = predict(obj,X)
            error('Not Implemented');
        end
    end
    methods(Abstract)
        [testResults,savedData] = ...
            trainAndTest(obj,input,savedData)   
        
        [testResults,savedData] = runMethod(obj,input,savedData)
        
    end        
end

