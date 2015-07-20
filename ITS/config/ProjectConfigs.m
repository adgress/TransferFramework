classdef ProjectConfigs < ProjectConfigsBase
    %PROJECTCONFIGSBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods(Static, Access=private)
        function [c] = CreateSingleton()
            c = ProjectConfigs();
        end       
    end
    
    methods(Static)

        function [c] = Create()
            %c = ProjectConfigs.instance;
            c = ProjectConfigs.CreateSingleton();
        end
        function [c] = SplitConfigs()
            pc = ProjectConfigs.Create();
            c = SplitConfigs();
            c.setITS();
        end
    end
    methods(Access = private)
        function [c] = ProjectConfigs()            
        end
    end
    
end

