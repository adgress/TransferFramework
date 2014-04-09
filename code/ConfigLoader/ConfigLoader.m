classdef ConfigLoader < handle
    %CONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configs
        configFile
        commonConfigFile
    end
    
    methods
        function obj = ConfigLoader(configs,commonConfigFile)            
            obj.configFile = '';            
            obj.commonConfigFile = commonConfigFile;
            if isa(configs,'char')     
                obj.configFile = configs;                
                obj.loadConfigs();                
            else
                obj.configs = configs; 
            end
        end                
        function [configs] = loadConfigs(obj,configFile)
            obj.configs = containers.Map;
            if nargin >= 2
                obj.configFile = configFile;
            end
            if ~isempty(obj.commonConfigFile)
                obj.configs = ...
                    ConfigLoader.StaticLoadConfigs(obj.commonConfigFile);
            end
            configs = ConfigLoader.StaticLoadConfigs(obj.configFile);
            keys = configs.keys;
            for i=1:numel(configs.keys)
                key = keys{i};
                value = configs(key);
                obj.configs(key) = value;
            end
            
            configs = obj.configs;
        end
        function [str] = createConfigString(obj)
            str = '';
            error('TODO');            
        end
    end
    methods(Access=protected,Static)
        function [configs] = StaticLoadConfigs(fileName)
            fid = ConfigLoader.loadFile(fileName);
            configs = containers.Map;
            while ~feof(fid)
                x = fgetl(fid);
                if isempty(x) || x(1) == '#' || ...
                    (isa(x,'double') && x == -1)
                    continue;
                end
                C = textscan(x,'%s','delimiter','=');
                C = C{1};
                var = C{1};
                val = '';
                if length(C) > 1
                    val = C{2}; 
                end
                assert(~isempty(val))
                val = eval(val);
                configs(var) = val;
            end
            fclose(fid);
        end   
        function fid = loadFile(fileName)
            fid = fopen(fileName,'r');
            ConfigLoader.checkFile(fileName);
            if fid == -1
                error('Could not open config file');
            end
        end
        function fileExists = checkFile(fileName)
            if isempty(fileName)
                error('You need to enter a config file name');
            end
            fileExists = exist(fileName,'file');
            assert(fileExists > 0,[fileName ' doesn''t exist']);
        end 
        function [experiments] = StaticCreateAllExperiments(...
                paramKeys, keys,configs)
            e = struct();
            for i=1:numel(paramKeys)
                key = paramKeys{i};
                if ~isKey(configs,key)
                    continue;
                end
                e.(key) = configs(key);
            end
            
            allExps = {e};
            for i=1:numel(keys)
                key = keys{i};
                values = configs(key);
                newExperiments = {};
                for j=1:numel(values)
                    val = values(j);
                    for k=1:numel(allExps)
                        methodClasses = configs('methodClasses');
                        for l=1:numel(methodClasses)
                            e = allExps{k};                        
                            e.methodClass = methodClasses{l};
                            e.(key) = val;
                            newExperiments{end+1} = e;
                        end
                    end
                end
                allExps = newExperiments;
            end
            experiments= allExps;
        end
    end
    methods(Access=private)
        
    end        
    
end

