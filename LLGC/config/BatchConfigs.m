classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();
            c = ProjectConfigs.Create();
            %obj.configsStruct.paramsToVary={'sigmaScale','k','alpha','sigma'};
            obj.configsStruct.paramsToVary={};
            obj.configsStruct.sigma = num2cell(c.sigma);
            obj.configsStruct.sigmaScale = num2cell(c.sigmaScale);
            obj.configsStruct.k = num2cell(c.k);
            obj.configsStruct.alpha = num2cell(c.alpha);
            obj.configsStruct.mainConfigs=LLGCMainConfigs();
            obj.configsStruct.overrideConfigs = {Configs()};
            switch c.dataSet
                case Constants.TOMMASI_DATA
                    obj.set('overrideConfigs',BatchConfigs.makeTommasiOverrideConfigs());
                case Constants.COIL20_DATA
                case Constants.HOUSING_DATA
                case Constants.NG_DATA
                    obj.set('overrideConfigs',BatchConfigs.makeNGOverrideConfigs());
                otherwise
                    
                    error('unknown data set');
            end
        end                
    end
    methods(Static)
        function [configs] = makeTommasiOverrideConfigs()
            %obj.set('targetLabels',[10 15]);
            %obj.set('sourceLabels',[23 25 26 30]);
            if ProjectConfigs.experimentSetting == ...
                    ProjectConfigs.NOISY_EXPERIMENT
                configs = {};
                c = Configs();
                c.set('labelsToUse',ProjectConfigs.noisyTommasiLabels);
                c.set('targetLabels',[]);
                c.set('sourceLabels',[]);
                configs{1} = c;
            else
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
                    if ProjectConfigs.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT
                        break;
                    end
                end
            end
        end
        
        function [configs] = makeNGOverrideConfigs()
            configs = {};      

            if ProjectConfigs.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER
                
                dataSets = { ...
                    'CR2CR3CR4ST1ST2ST3ST42CR1',...
                    'CR1CR3CR4ST1ST2ST3ST42CR2',...
                    'CR1CR2CR4ST1ST2ST3ST42CR3',...
                    'CR1CR2CR3ST1ST2ST3ST42CR4'
                };
                %sourceDataSetToUse = {'CR4','ST2'};
                %sourceDataSetToUse = {'CR2'};
               
                %dataSets = {'CR2CR3CR4ST1ST2ST3ST42CR1'};
                sourceDataSetToUse = {'ST2', 'ST3'};
                for idx=1:length(dataSets)
                    c = Configs();
                    c.set('dataSet',dataSets{idx});
                    c.set('sourceDataSetToUse',sourceDataSetToUse);
                    configs{end+1} = c;
                end
            else
                sourceDataSetToUse = {'CR2','CR3','CR4','ST1','ST2','ST3','ST4'};
                dataSet = 'CR2CR3CR4ST1ST2ST3ST42CR1';
                for idx=1:length(sourceDataSetToUse)
                    c = Configs();
                    c.set('sourceDataSetToUse',sourceDataSetToUse{idx});
                    c.set('dataSet',dataSet);
                    configs{end+1} = c;
                end
            end
        end
        
        
    end
end

