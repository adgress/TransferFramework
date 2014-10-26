classdef StringHelpers
    %STRINGHELPERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function [split] = split_string(string,delim)
            split = {};
            while numel(string) > 0
                [split{end+1}, string] = strtok(string,delim);
            end
        end 
        
        function [s] = ConvertToString(v)
            if isa(v,'char')
                s = v;
            end
            if ~exist('s','var')
                try
                    s = num2str(v);
                catch unused
                end
            end
            if ~exist('s','var')
                s = v.getResultFileName('-',false);
            end
            assert(logical(exist('s','var')));
        end
        
        function [s] = RemoveSuffix(s,suffix)
            inds = strfind(s,suffix);
            if ~isempty(inds)
                s = s(1:inds(end)-1);
            end
        end
    end
    
end

