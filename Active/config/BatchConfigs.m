classdef BatchConfigs < Configs
    %BATCHCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = BatchConfigs()
            obj = obj@Configs();
            pc = ProjectConfigs.Create();
            obj.configsStruct.paramsToVary = {};
            %{
            obj.configsStruct.paramsToVary={'sigmaScale','k','alpha'};
            obj.configsStruct.sigmaScale = num2cell(pc.sigmaScale);
            obj.configsStruct.k = num2cell(pc.k);
            obj.configsStruct.alpha = num2cell(pc.alpha);
            %}
            obj.configsStruct.mainConfigs=ActiveMainConfigs();              
            
            overrideConfigs = {Configs()};
            if ProjectConfigs.useOverrideConfigs
                switch pc.dataSet
                    case Constants.CV_DATA
                        overrideConfigs = BatchConfigs.makeCVOverrideConfigs();
                    case Constants.TOMMASI_DATA
                        overrideConfigs = BatchConfigs.makeTommasiOverrideConfigs();
                    case Constants.NG_DATA
                        overrideConfigs = BatchConfigs.makeNGOverrideConfigs();
                    otherwise
                        error('Unknown data set');
                end
                activeConfigs = Configs();
                activeMethods = {
                    EntropyActiveMethod(activeConfigs), ...
                    TargetEntropyActiveMethod(activeConfigs),...
                    SumEntropyActiveMethod(activeConfigs),...
                };
                newOverrideConfigs = {};
                for i=1:length(overrideConfigs)
                    c = overrideConfigs{i};
                    for j=1:length(activeMethods)
                        cCopy = c.copy();
                        cCopy.set('activeMethodObj',activeMethods{j}.copy);
                        newOverrideConfigs{end+1} = cCopy;
                    end
                end
                overrideConfigs = newOverrideConfigs;
            end            
            obj.set('overrideConfigs',overrideConfigs);
        end           
    end
    methods(Static)
        function [configs] = makeCVOverrideConfigs()
            configs = {};
            
            dataSet = {};
            dataSet{end+1} = 'ADW2C';
            dataSet{end+1} = 'ACW2D';
            dataSet{end+1} = 'ACD2W';
            
            sourceDataSetToUse = {};
            sourceDataSetToUse{end+1} = 'A';
            sourceDataSetToUse{end+1} = 'W';
            sourceDataSetToUse{end+1} = 'D';
            
            for idx=1:length(dataSet)
                c = Configs();
                c.set('dataSet',dataSet{idx});
                c.set('sourceDataSetToUse',sourceDataSetToUse{idx});
                configs{end+1} = c;
            end
        end
        
        function [configs] = makeTommasiOverrideConfigs()
            configs = {};            
            
            targetLabelSets = {};
            targetLabelSets{end+1} = [10 15];
            targetLabelSets{end+1} = [10 15];
            targetLabelSets{end+1} = [105 145];
            targetLabelSets{end+1} = [105 57];
            
            sourceLabelSets = {};
            sourceLabelSets{end+1} = [30 41];
            sourceLabelSets{end+1} = [25 26];
            sourceLabelSets{end+1} = [250 252];
            sourceLabelSets{end+1} = [250 124];
            
            for idx=1:length(targetLabelSets)
                c = Configs();
                c.set('targetLabels',targetLabelSets{idx});
                c.set('sourceLabels',sourceLabelSets{idx});
                configs{end+1} = c;
            end
        end
        
        function [configs] = makeNGOverrideConfigs()
            configs = {};      
            %{
            sourceDataSetToUse = {'CR2','CR3','CR4'};
            dataSet = 'CR2CR3CR42CR1';
            for idx=1:length(sourceDataSetToUse)
                c = Configs();
                c.set('sourceDataSetToUse',sourceDataSetToUse{idx});
                c.set('dataSet',dataSet);
                configs{end+1} = c;
            end
                        
            sourceDataSetToUse = {'ST1','ST2','ST3','ST4'};
            dataSet = 'CR2CR3CR4ST1ST2ST3ST42CR1';
            for idx=1:length(sourceDataSetToUse)
                c = Configs();
                c.set('sourceDataSetToUse',sourceDataSetToUse{idx});
                c.set('dataSet',dataSet);
                configs{end+1} = c;
            end
            %}
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

