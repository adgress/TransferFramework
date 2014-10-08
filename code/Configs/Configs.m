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
        %{
        function value = subsref(obj,s)
            isKey = strcmp(s(1).type, '()');
            if isKey && ~strcmp(s(1).subs,'configsStruct')
                value = obj.configsStruct.(s(1).subs);                
            else
                value = builtin('subsref', obj, s);     
            end
        end
        function obj = subsasgn(obj, s, value)
            isKey = strcmp(s(1).type, '()');
            if isKey && ~strcmp(s(1).subs,'configsStruct')
                obj.configsStruct.(s(1).subs) = value;
                %builtin('subsasgn', obj.configs, s, value);
            else
                builtin('subsasgn', obj, s, value);
            end
        end
        %}
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
    end
    
    methods(Access = protected)
        function cpObj = copyElement(obj)
            cpObj = copyElement@matlab.mixin.Copyable(obj);
        end
    end
end

