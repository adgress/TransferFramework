classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();
            c = ProjectConfigs.Create();
            obj.configsStruct.paramsToVary={'sigmaScale','k','alpha'};
            obj.configsStruct.sigmaScale = num2cell(c.sigmaScale);
            obj.configsStruct.k = num2cell(c.k);
            obj.configsStruct.alpha = num2cell(c.alpha);
            obj.configsStruct.mainConfigs=LLGCMainConfigs();
            obj.configsStruct.overrideConfigs = {Configs()};
            switch c.dataSet
                case Constants.TOMMASI_DATA
                    obj.set('overrideConfigs',BatchConfigs.makeTommasiOverrideConfigs());
                otherwise
                    error('unknown data set');
            end
        end                
    end
    methods(Static)
        function [configs] = makeTommasiOverrideConfigs()
            %obj.set('targetLabels',[10 15]);
            %obj.set('sourceLabels',[23 25 26 30]);
            targetLabels = {[10 15], [10 23], [23 25]};
            sourceLabels = {
                [23 25 26 30], ...
                [15 25 26 30], ...
                [10 15 26 30]
            };
        
            configs = {};
            for idx=1:length(targetLabels)
                c = Configs();
                c.set('targetLabels',targetLabels{idx});
                c.set('sourceLabels',sourceLabels{idx});
                configs{idx} = c;
            end
        end
    end
end

