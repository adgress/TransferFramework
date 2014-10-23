classdef Configs < matlab.mixin.Copyable
    %CONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configsStruct  
    end
    properties(Constant)
    end
    
    properties(Dependent)
    end
    
    methods               
        function [obj] = Configs()
            obj.configsStruct = struct();
        end
        function [] = addConfigs(obj, other)
            newConfigs = other;
            if isa(other, 'Configs')
                newConfigs = other.configsStruct;
            end
            obj.configsStruct = Helpers.CombineStructs(obj.configsStruct,...
                newConfigs);
        end
        function display(obj)
            display(class(obj));
            display(obj.configsStruct);
        end       
        function [v] = getConfig(obj,key)
            if isa(obj.configsStruct,'containers.Map')
                error('Why is configs a map?');
            else                
                v = obj.get(key);           
            end
        end
        function [v] = get(obj,key)
            v = obj.configsStruct.(key);
        end
        function [] = set(obj,key,value)
            obj.configsStruct.(key) = value;
        end
        function [b] = has(obj,key)
            b = obj.hasConfig(key);
        end
        function [b] = hasConfig(obj,key)
            b = isfield(obj.configsStruct,key);
        end        
        function [b] = isKey(obj,key)
            b = obj.hasConfig(key);
        end
        function [] = delete(obj,key)
            obj.configsStruct = rmfield(obj.configsStruct,key);
        end
        
        function [b] = hasNonempty(obj,key)
            b = obj.has(key) && ~isempty(obj.get(key));
        end
        function [b] = hasMoreThanOne(obj,key)
            b = obj.has(key) && length(obj.get(key)) > 1;
        end               
    end
    
    methods(Access = protected)
        function cpObj = copyElement(obj)
            cpObj = copyElement@matlab.mixin.Copyable(obj);
        end
    end
end

