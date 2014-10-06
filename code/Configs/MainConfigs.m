classdef MainConfigs < Configs
    %CONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    properties(Constant)
    end
    
    properties(Dependent)
        dataDirectory
        resultsDirectory
        transferDirectory
    end
    
    methods               
        function [obj] = MainConfigs()
            obj = obj@Configs();
        end        
        function [v] = get.dataDirectory(obj)
            v = [obj.get('dataDir') '/' obj.get('dataName')];
        end
        function [v] = get.resultsDirectory(obj)
            v = [getProjectDir() '/' obj.get('resultsDir') '/' ...
                 '/' obj.get('dataName') '/'];
        end
        function [v] = get.transferDirectory(obj)
            v = [obj.get('dataDir') '/' obj.get('transferDir')];
        end
    end        
end

