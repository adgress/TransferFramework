classdef Saveable < handle
    %SAVEABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %configs
    end
    
    methods
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
                     v = obj.configs(n);
                 else
                     v = '0';
                     display([n ' Missing: setting to 0']);
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
        function [name] = GetResultFileName(className,configs)
            classFunc = str2func(className);
            o = classFunc(configs);
            name = o.getRessultFileName(configs);
        end
        function [name] = GetDisplayName(className,configs)
            classFunc = str2func(className);
            o = classFunc(configs);
            name = o.getDisplayName();
        end
        function [name] = GetPrefix(className,configs)
            func = str2func(className);
            o = func();
            name = o.getPrefix();
        end
    end
    
end

