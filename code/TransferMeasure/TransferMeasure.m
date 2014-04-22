classdef TransferMeasure < handle
    %TRANSFERMEASURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configs
    end
    
    methods
        function obj = TransferMeasure(configs)
            obj.configs = configs;
        end
        
        function [mVals,metadata] = computeMultisourceMeasure(obj,...
                sources,target,options)
            mVals = zeros(numel(sources),1);
            metadata = cell(numel(sources),1);
            for i=1:numel(sources)
                s = sources{i};
                [mVals(i),metadata{i}] = computeMeasure(s,target,options);
            end
        end  

        function [displayName] = getDisplayName(obj)
            displayName = obj.getResultFileName(',');
        end
        function [name] = getResultFileName(obj,delim)
             if nargin < 2
                delim = '_';                
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
            name = ['/TM/' name];
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {'transferMethodClass'};
        end
        function [] = displayMeasure(obj,val)
            display([obj.getPrefix() ': ' num2str(val)]); 
        end
    end
    methods(Static)
        function [name] = GetDisplayName(measureName,configs)
            measureFunc = str2func(measureName);
            measureObject = measureFunc(configs);
            name = measureObject.getDisplayName();
        end
    end
    methods(Abstract)
        [val,metadata] = computeMeasure(obj,source,target,options)
        [name] = getPrefix(obj)       
    end
    
end

