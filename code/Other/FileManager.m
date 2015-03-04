classdef FileManager < handle
    %FILEMANAGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cachedFiles
        fileNames
        maxSavedFiles = 3
    end
    
    methods
        function [obj] = FileManager()        
            obj.cachedFiles = containers.Map;
        end
        
        function [d] = load(obj,file)
            if ~isKey(obj.cachedFiles,file)                
                obj.fileNames{end+1} = file;
                if length(obj.cachedFiles.keys) >= obj.maxSavedFiles                    
                    remove(obj.cachedFiles,obj.fileNames{1});
                    obj.fileNames(1) = [];
                end
                obj.cachedFiles(file) = load(file);
            end            
            d = obj.cachedFiles(file);
        end
    end
    
end

