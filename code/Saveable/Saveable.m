classdef Saveable < matlab.mixin.Copyable
    %SAVEABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configs
    end
    
    methods
        function obj = Saveable(configs)
            if nargin < 1
                obj.configs = [];
                return
            end
            if ismethod(configs,'copy')
                obj.configs = configs.copy();
            else
                obj.configs = [];
            end
        end
        function [] = set.configs(obj, newConfigs)
            obj.configs = newConfigs;
        end
        function [] = addConfigs(obj, newConfigs)
            if numel(obj.configs) == 0
                obj.configs = newConfigs.copy();
            else
                obj.configs.addConfigs(newConfigs);
            end
        end
        function [v] = get(obj,key,defaultValue)
            if exist('defaultValue','var')
                v = obj.configs.get(key,defaultValue);
            else
                v = obj.configs.get(key);
            end
        end
        function [] = set(obj,key,value)
            obj.configs.set(key,value);
        end
        function [b] = has(obj,key)
            b = obj.configs.has(key);
        end
        function [] = delete(obj,key)
            obj.configs.delete(key);
        end
        
        function [] = updateConfigs(obj, newConfigs)
        end
        function [] = updateConfigsWithKeys(obj, newConfigs, keys)
            obj.configs.addConfigsWithKeys(newConfigs,keys);
        end
        
        function [displayName] = getDisplayName(obj)
            displayName = obj.getResultFileName(',',false);
        end
        function [name] = getResultFileName(obj,delim,includeDirectory)
             if nargin < 2
                delim = '_';                
             end
             if nargin < 3
                 includeDirectory = true;
             end
             name = obj.getPrefix();
             params = obj.getNameParams();
             for i=1:numel(params)
                 n = params{i};
                 if isKey(obj.configs,n)
                     v = obj.configs.get(n);
                 else
                     display([n ' Missing, skipping']);
                     continue;
                     %v = '0';
                     %display([n ' Missing: setting to 0']);
                 end
                 if ~isa(v,'char')
                     v = num2str(v);
                 end
                 name = [name delim n '=' v];
             end
             if includeDirectory
                name = ['/' obj.getDirectory() '/' name];
             end
        end
    end
    
    methods(Abstract)
        [prefix] = getPrefix(obj);
        [d] = getDirectory(obj);
        [nameParams] = getNameParams(obj)
    end
    
    methods(Static)
        function [name] = GetResultFileName(className,configs,includeDir)
            classFunc = str2func(className);
            o = classFunc(configs);
            if nargin >= 3
                name = o.getResultFileName('_',includeDir);
            else
                name = o.getResultFileName('_',true);
            end
        end
        function [name] = GetDisplayName(className,configs)
            if ~isa(className,'char')
                assert(~isequal(className,''));
                className = class(className);
            end
            classFunc = str2func(className);
            o = classFunc(configs);
            name = o.getDisplayName();
        end
        function [name] = GetPrefix(className,configs)
            func = str2func(className);
            if nargin < 2     
                configs = containers.Map;
            end
            o = func(configs);
            name = o.getPrefix();
        end
        function [o] = ConstructObject(className,configs)
            func = str2func(className);
            o = func(configs);
        end
    end
    
end

