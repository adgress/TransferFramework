classdef ProjectConfigs < ProjectConfigsBase
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        %TODO: Group constants for different experiments into structs, make
        %them accessible through dependent properties
        
        EXPERIMENT_ACTIVE = 1
        EXPERIMENT_ACTIVE_TRANSFER = 2
        experimentSetting = 2
        
        
        
        instance = ProjectConfigs.CreateSingleton()
        
        data = Constants.CV_DATA
        targetLabels = [1:10]
        sourceLabels = [1:10]
        
        %{
        data = Constants.TOMMASI_DATA        
        targetLabels = [10 15]
        sourceLabels = [25 26]
        %}
        %Weak positive transfer for small number of labels
        %targetLabels = [105 145]
        %sourceLabels = [250 252]
        
        %targetLabels = [10 15]
        %sourceLabels = [25 26]
        trainLabels = [10 15]
        %[10 15 23 25 26 30 41 56 57]
        showBothPerformance = 0
        showTransferDifference = 1
        showTransferPrediction = 1
        showTransferPerformance = 0
        
        activeMethodsToPlot = {'Random'}
        %domainsToViz = {}
        tommasiDomainsToViz = {...
            '25  26-to-10  15',...
            '30  41-to-10  15',...
            '250  124-to-105   57',...
            '250  252-to-105  145'...
            }
        
        cvDomainsToViz = {...
            'A2C',...
            'D2W',...
            'W2D',...
            }
    end
    
    properties        
        sigmaScale
        k
        alpha
        labelsToUse
        numLabeledPerClass                                
        %tommasiLabels                       
        multiSourceTransfer
        makeSubDomains
        addTargetDomain
        numOverlap
        maxSourceSize
        justTargetNoSource
        dataSet
    end
    
    methods(Static, Access=private)
        function [c] = CreateSingleton()
            c = ProjectConfigs();            
            c.sigmaScale = .2;
            c.k=inf;
            c.alpha=.9;

            c.dataSet = ProjectConfigs.data;
            %c.labelsToUse = ProjectConfigs.trainLabels;
            c.labelsToUse = ProjectConfigs.targetLabels;
            %c.sourceLabels = ProjectConfigs.sourceLabels;
            c.numLabeledPerClass=[2];
            c.numTarget = 2;
            c.numSource = 2;
            
            c.tommasiLabels = [10 15 23 25 26 30 41 56 57];
            
            %allLabels = ProjectConfigs.labels;
            %train = ProjectConfigs.trainLabels;
            %c.tommasiLabels = [train setdiff(allLabels,train)];           
            
            c.multiSourceTransfer = true;
            c.makeSubDomains = true;
            c.addTargetDomain = false;
            c.numOverlap = 0;
            c.justTargetNoSource = false;
            c.maxSourceSize = inf;
            if c.dataSet == Constants.CV_DATA
                c.makeSubDomains = false;
                c.labelsToUse = [];
            end
        end
    end
    
    methods(Static)
               
        function [c] = Create()
            c = ProjectConfigs.instance;
        end
        
        function [c] = BatchConfigs()
            c = BatchConfigs();
            pc = ProjectConfigs.Create();
            c.get('experimentConfigsClass').configsStruct.labelsToUse = pc.labelsToUse;
            if pc.dataSet == Constants.TOMMASI_DATA
                c.get('experimentConfigsClass').setTommasiData(); 
            elseif pc.dataSet == Constants.CV_DATA
                c.get('experimentConfigsClass').setCVData(); 
            end
            c.configsStruct.experimentConfigLoader='ActiveExperimentConfigLoader';
            c.set('transferMethodClass', FuseTransfer());        
            %c.set('transferMethodClass', Transfer());        
            
        end
        
        function [c] = SplitConfigs()
            pc = ProjectConfigs.Create();
            c = SplitConfigs();            
            c.setTommasi();
        end
        
        function [c] = VisualizationConfigs()            
            c = VisualizationConfigs();                                           
            c.configsStruct.showPostTransferMeasures = false;
            c.configsStruct.showPreTransferMeasures = false;
            c.configsStruct.showRelativePerformance = false;
            c.configsStruct.showRelativeMeasures = false;
            c.configsStruct.showSoftMeasures = false;
            c.configsStruct.showHardMeasures = false;
            c.configsStruct.showLLGCMeasure = false;
            c.configsStruct.vizMeasureCorrelation = false;
            c.configsStruct.confidenceInterval = VisualizationConfigs.CONF_INTERVAL_BINOMIAL;
            
            c.configsStruct.vizWeights = false;
            c.configsStruct.vizNoisyAcc = false;
            [c.configsStruct.plotConfigs,legend,title] = ...
                ProjectConfigs.makePlotConfigs();
            c.configsStruct.numColors = length(c.c.plotConfigs); 
            if ~isempty(legend)
                c.set('legend',legend);
                c.configsStruct.numColors = length(legend);
            end
            if ~isempty('title')
                c.set('title',title);
            end            
            
            c.configsStruct.xAxisDisplay = 'Active Learning Iterations';
            c.configsStruct.axisToUse = [0 10 -.5 1.1];
            pc = ProjectConfigs.Create();
            
            if ProjectConfigs.data == Constants.TOMMASI_DATA
                c.set('prefix','results_tommasi');
                c.set('dataSet',{'tommasi_data'});

                [t,s] = pc.GetTargetSourceLabels();
                transferDir = [num2str(s) '-to-' num2str(t)];
                c.set('resultsDirectory',['results_tommasi/tommasi_data/' transferDir]);
            else
                c.set('prefix','');
                c.set('dataSet',{'CV-small'});
               
                transferDir = 'A2C';
                c.set('resultsDirectory',['results/CV-small/' transferDir]);
            end
            %c.set('resultsDirectory','results_tommasi/tommasi_data/25  23-to-10  15');
        end
        
        function [plotConfigs,legend,title] = makePlotConfigs()  
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};           
            legend = {};
            s = num2str(ProjectConfigs.trainLabels);
            title = s;
            if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE
                methodResultsFileNames{end+1} = ['/Random_HF.mat'];
                legend{end+1} = 'Random';
                methodResultsFileNames{end+1} = ['/Entropy_HF.mat'];
                legend{end+1} = 'Entropy';
                methodResultsFileNames{end+1} = ['/VM_HF.mat'];
                legend{end+1} = 'VM';
            else
                fields = {}; 
                legendSuffixes = {};
                fileSuffix = '_S+T_LLGC-sigmaScale=0.2-alpha=0.9.mat';
                
                if ProjectConfigs.showBothPerformance
                    fields = [fields {'testResults','preTransferValTest'}];
                    legendSuffixes = [legendSuffixes {'Transfer Performance','Performance'}];
                end
                if ProjectConfigs.showTransferPrediction
                    fields{end+1} = 'negativeTransferPrediction';
                    legendSuffixes{end+1} = 'Negative Transfer Prediction Accuracy';
                end
                if ProjectConfigs.showTransferDifference
                    fields{end+1} = 'transferDifference';
                    legendSuffixes{end+1} = 'Test Error Difference';
                end
                if ProjectConfigs.showTransferPerformance
                    fields{end+1} = 'testResults';
                    legendSuffixes{end+1} = 'Transfer Performance';  
                end
                %TODO: This assumes activeMethodsToPlot has length one                
                for i=1:length(legendSuffixes)
                    toPlot = ProjectConfigs.activeMethodsToPlot{1};
                    methodResultsFileNames{i} = ...
                        [toPlot fileSuffix];
                    legend{i} = [toPlot ': ' legendSuffixes{i}];
                end                
            end
            plotConfigs = {};
            for fileIdx=1:length(methodResultsFileNames)
                configs = basePlotConfigs.copy();
                configs.set('resultFileName',methodResultsFileNames{fileIdx});
                if exist('fields','var')
                    configs.set('fieldToPlot',fields{fileIdx});
                end
                plotConfigs{end+1} = configs;
            end
        end                
    end
    methods
        function [t,s] = GetTargetSourceLabels(obj)
            t = ProjectConfigs.targetLabels;
            s = ProjectConfigs.sourceLabels;
        end    
        function [labelProduct] = MakeLabelProduct(obj)
            [t,s] = obj.GetTargetSourceLabels();                        
            targetDomains = Helpers.MakeCrossProductOrdered(t,t);
            %sourceDomains = Helpers.MakeCrossProductNoDupe(sourceLabels,sourceLabels);
            sourceDomains = Helpers.MakeCrossProductOrdered(s,s);
            labelProduct = Helpers.MakeCrossProduct(targetDomains,sourceDomains);
        end
    end
    methods(Access = private)
        function [c] = ProjectConfigs()            
        end
    end
    
end

