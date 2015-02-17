classdef ConfigLoader < Saveable
    %CONFIGLOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configFile
    end
    
    methods
        function obj = ConfigLoader(configsobj)
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@Saveable(configsobj);
            %obj.configFile = '';            
            %obj.configsClass = configsClass;
            if isa(configsobj,'char')     
                obj.configFile = configsobj;                
                obj.loadConfigs();                
            end
        end                
        function [] = loadConfigs(obj,configFile)
            obj.configs = containers.Map;
            if nargin >= 2
                obj.configFile = configFile;
            end
            obj.configs = obj.configsClass();
            configsMap = ConfigLoader.StaticLoadConfigs(Helpers.MakeProjectURL(obj.configFile));
            keys = configsMap.keys;
            for i=1:numel(configsMap.keys)
                key = keys{i};
                value = configsMap(key);
                obj.configs.set(key,value);
            end
        end
        function [str] = createConfigString(obj)
            str = '';
            error('TODO');            
        end
        
        function [prefix] = getPrefix(obj)
            error('TODO')
            prefix = '';
        end
        function [d] = getDirectory(obj)
            error('TODO')
            d = '';
        end
        function [nameParams] = getNameParams(obj)
            error('TODO')
            nameParams = '';            
        end
        
    end
    methods(Static)
       function [configs] = LoadConfigs(fileName)
            fid = ConfigLoader.loadFile(fileName);
            configs = Configs();
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
                    val = [C{2:end}];                    
                end
                assert(~isempty(val))
                val = eval(val);
                configs.set(var,val);
            end
            fclose(fid);
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
                    val = [C{2:end}];                    
                end
                assert(~isempty(val))
                val = eval(val);
                configs(var) = val;
            end
            fclose(fid);
        end   
        function fid = loadFile(fileName)            
            ConfigLoader.checkFile(fileName);
            fid = fopen(fileName,'r');            
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
            display('StaticCreateAllExperiments: Multiple paramKeys?');
            for i=1:numel(paramKeys)
                key = paramKeys{i};
                if ~configs.hasConfig(key)
                    continue;
                end
                e.(key) = configs.get(key);
            end
            allExps = {e};                        
            for i=1:numel(keys)
                key = keys{i};
                values = configs.get(key);
                newExperiments = {};
                for j=1:numel(values)
                    val = values(j);
                    for k=1:numel(allExps)
                        e = allExps{k};
                        e.(key) = val;
                        newExperiments{end+1} = e;
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

