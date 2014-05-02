classdef Configs < handle
    %CONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        configs        
    end
    properties(Constant)
        PostTMKey = 'postTransferMeasures';
        PreTMKey = 'preTransferMeasures';
        MethodClassesKey = 'methodClasses';
        TransferMethodClassKey = 'transferMethodClass';
    end
    
    methods
        function [obj] = Configs(configs)
            if isa(configs,'Configs')
                obj.configs = configs.configs;
            else
                obj.configs = configs;
            end
        end
        function [v] = getConfig(obj,key)
            if isa(obj.configs,'containers.Map')
                v = obj.configs(key);
            else
                v = obj.configs.key;
            end
        end
        function [b] = hasConfig(obj,key)
            if isa(obj.configs,'containers.Map')
                b = isKey(obj.configs,key);
            else
                b = isfield(obj.configs,key);
            end
        end        
        function [m] = getMethodClasses(obj)
            m = obj.getConfig(Configs.MethodClassesKey);
        end
        function [m] = getPostTransferMeasures(obj)
            m = obj.getConfig(Configs.PostTMKey);
        end
        function [b] = hasPostTransferMeasures(obj)            
            b = obj.hasConfig(Configs.PostTMKey) && ...
            ~isempty(obj.getPostTransferMeasures());
        end
        function [m] = getPreTransferMeasures(obj)
            m = obj.getConfig(Configs.PreTMKey);                
        end
        function [b] = hasPreTransferMeasures(obj)
            b = obj.hasConfig(Configs.PreTMKey) && ...
                ~isempty(obj.getPreTransferMeasures);;
        end
        
        function [m] = getTransferMethod(obj)
            m = obj.getConfig(Configs.TransferMethodClassKey);
        end
        function [b] = hasTransferMethod(obj)
            b = obj.hasConfig(Configs.TransferMethodClassKey);
        end
    end        
    
end

