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
                    case Constants.NG_DATA
                        overrideConfigs = BatchConfigs.makeNGOverrideConfigs();
                    case Constants.HOUSING_DATA
                        overrideConfigs = BatchConfigs.makeHousingOverrideConfigs();
                    otherwise
                        error('Unknown data set');
                end
                activeConfigs = Configs();
                %{
                activeMethods = {
                    TransferRepCoverage(activeConfigs),...
                    TransferRepEntropyActiveMethod(activeConfigs),...
                    TransferRepresentativeActiveMethod(activeConfigs),...
                    RandomActiveMethod(activeConfigs),...
                    SumEntropyActiveMethod(activeConfigs),...
                    EntropyActiveMethod(activeConfigs), ...
                    TargetEntropyActiveMethod(activeConfigs),...                    
                };
                %}
                activeMethods = {                      
                    RandomActiveMethod(activeConfigs),...                    
                    EntropyActiveMethod(activeConfigs), ...
                    SumEntropyActiveMethod(activeConfigs), ...
                    TargetEntropyActiveMethod(activeConfigs), ...
                };
            
                
                activeMethods{end+1} = EntropyActiveMethod(activeConfigs);
                activeMethods{end}.set('valWeights',1);
                activeMethods{end+1} = EntropyActiveMethod(activeConfigs);
                activeMethods{end}.set('valWeights',2);
                activeMethods{end+1} = EntropyActiveMethod(activeConfigs);
                activeMethods{end}.set('valWeights',3);
                activeMethods{end+1} = EntropyActiveMethod(activeConfigs);
                activeMethods{end}.set('valWeights',4);
                
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
            targetLabelSets{end+1} = [105 57];
            targetLabelSets{end+1} = [10 15];
            targetLabelSets{end+1} = [10 15];
            targetLabelSets{end+1} = [105 145];
            
            targetLabelSets{end+1} = [10 15];
            targetLabelSets{end+1} = [10 15];            
            targetLabelSets{end+1} = [105 57];
            targetLabelSets{end+1} = [105 145];
            
            sourceLabelSets = {};
            sourceLabelSets{end+1} = [250 124];
            sourceLabelSets{end+1} = [30 41];
            sourceLabelSets{end+1} = [25 26];
            sourceLabelSets{end+1} = [250 252];            
            
            sourceLabelSets{end+1} = [250 124];
            sourceLabelSets{end+1} = [250 252];
            sourceLabelSets{end+1} = [30 41];
            sourceLabelSets{end+1} = [25 26];
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
            if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE
                dataSets = { ...
                    'CR2CR3CR4ST1ST2ST3ST42CR1',...
                    'CR1CR3CR4ST1ST2ST3ST42CR2',...
                    'CR1CR2CR4ST1ST2ST3ST42CR3',...
                    'CR1CR2CR3ST1ST2ST3ST42CR4'
                };
                for idx=1:length(dataSets)
                    c = Configs();
                    c.set('dataSet',dataSets{idx});
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
        function [configs] = makeHousingOverrideConfigs()
            configs = {};
        end
    end
end

