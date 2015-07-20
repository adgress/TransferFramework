classdef StringHelpers
    %STRINGHELPERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function [split] = split_string(string,delim,removeDuplicates)
            if ~exist('removeDuplicates','var')
                removeDuplicates = true;
            end
            split = {};
            
            %This is to fix tab issues - I'm not sure if this is correct
            %for all input though
            delim = sprintf(delim);
            if removeDuplicates
                while numel(string) > 0
                    [split{end+1}, string] = strtok(string,delim);
                end
            else
                idx = strfind(string,delim);                    
                if isempty(idx)
                    split{end+1} = string;
                else
                    idx = [0 idx];
                    for i=1:length(idx)-1
                        split{i} = string(idx(i)+1:idx(i+1)-1);
                    end
                    split{end+1} = string(idx(end)+1:end);
                end
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

