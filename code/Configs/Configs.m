classdef Configs < matlab.mixin.Copyable
    %CONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configsStruct  
    end
    properties(Constant)
        PostTMKey = 'postTransferMeasures';
        PreTMKey = 'preTransferMeasures';
        MethodClassesKey = 'methodClasses';
        TransferMethodClassKey = 'transferMethodClass';
    end
    
    properties(Dependent)
        dataDirectory
        resultsDirectory
        transferDirectory
        outputDirectory
    end
    
    methods               
        function [obj] = Configs()
            obj.configsStruct = struct();
        end
        function [] = addConfigs(obj, other)
            obj.configsStruct = Helpers.CombineStructs(obj.configsStruct,...
                other.configsStruct);
        end
        function display(obj)
            display(obj.configsStruct);
        end       
        function [v] = getConfig(obj,key)
            if isa(obj.configsStruct,'containers.Map')
                v = obj.configsStruct(key);
            else
                error('Why isn''t configs a map?');
                v = obj.configsStruct.key;               
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
        function [b] = hasConfig(obj,key)
            b = isfield(obj.configsStruct,key);
        end        
        function [b] = isKey(obj,key)
            b = obj.hasConfig(key);
        end
        
        function [v] = get.dataDirectory(obj)
            v = [obj.get('dataDir') '/' obj.get('dataName')];
        end
        function [v] = get.resultsDirectory(obj)
            v = [obj.get('dataDir') '/' obj.get('resultsDir') '/'];
        end
        function [v] = get.transferDirectory(obj)
            v = [obj.get('dataDir') '/' obj.get('transferDir')];
        end
        function [v] = get.outputDirectory(obj)
            v = [obj.get('dataDir') '/' obj.get('outputDir')];
        end
        
        
        
        
        function [m] = getMethodClasses(obj)
            m = obj.get(Configs.MethodClassesKey);
        end
        function [m] = getPostTransferMeasures(obj)
            m = obj.get(Configs.PostTMKey);
        end
        function [b] = hasPostTransferMeasures(obj)            
            b = obj.hasConfig(Configs.PostTMKey) && ...
            ~isempty(obj.getPostTransferMeasures());
        end
        function [m] = getPreTransferMeasures(obj)
            m = obj.get(Configs.PreTMKey);                
        end
        function [b] = hasPreTransferMeasures(obj)
            b = obj.hasConfig(Configs.PreTMKey) && ...
                ~isempty(obj.getPreTransferMeasures());;
        end
        
        function [m] = getTransferMethod(obj)
            m = obj.get(Configs.TransferMethodClassKey);
        end
        function [b] = hasTransferMethod(obj)
            b = obj.hasConfig(Configs.TransferMethodClassKey);
        end        
    end
    
    methods(Access = protected)
        function cpObj = copyElement(obj)
            cpObj = copyElement@matlab.mixin.Copyable(obj);
        end
    end
end

