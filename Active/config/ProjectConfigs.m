classdef ProjectConfigs < ProjectConfigsBase
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        %TODO: Group constants for different experiments into structs, make
        %them accessible through dependent properties
        
        EXPERIMENT_ACTIVE = 1
        EXPERIMENT_ACTIVE_TRANSFER = 2
        experimentSetting = 2
        
        numRandomFeatures = 0
        
        instance = ProjectConfigs.CreateSingleton()

        data = Constants.NG_DATA
        %data = Constants.TOMMASI_DATA
        %data = Constants.CV_DATA
        
        resampleTarget = false
        %kNumLabeledPerClass = 2
        kNumLabeledPerClass = 10
        logRegNumFeatures = inf
        useL1LogReg = false
        
        axisToUse = [0 10 -.5 1.1]
        %axisToUse = [0 10 -.05 .1]
        %axisToUse = [0 10 -.5 .2]
        useOverrideConfigs = 1        
        
        useSavedSmallResults = 1
        useKSR = 0
        
        showBothPerformance = 0
        showPreTransferPerformance = 0
        showTransferPerformance = 0
        
        showTransferDifference = 0
        showTransferPrediction = 0
                        
        showTransferMeasurePerfDiff = 0
        showPreTransferMeasurePerfDiff = 0
        
        showWeightedPrecisionTransferLoss = 1
         %{
        activeIterations = 10;
        labelsPerIteration = 5;
        %}
        
        activeIterations = 5;
        labelsPerIteration = 10;
        activeMethodsToPlot = {'Random','SumEntropy_method'}
        %activeMethodsToPlot = {'Random','SumEntropy_method=1'}
        %activeMethodsToPlot = {'Random','TargetEntropy','Entropy'}
        %activeMethodsToPlot = {'Random','TargetEntropy','Entropy','SumEntropy','TransferRep'}
        %activeMethodsToPlot = {'TransferRepCov_method=6','TransferRepCov_method=5'}
        %activeMethodsToPlot = {'TargetEntropy','TransferRepCov_method=5','TransferRep'}
        %activeMethodsToPlot = {'Entropy','TargetEntropy','TransferRep'}
        %activeMethodsToPlot = {'Random','Entropy','TargetEntropy','TransferRep'}
        %activeMethodsToPlot = {'Random','Entropy','TargetEntropy','SumEntropy'}
        %activeMethodsToPlot = {'Random','Entropy','TargetEntropy'}
        %activeMethodsToPlot = {'Entropy','TargetEntropy','SumEntropy'}
        %activeMethodsToPlot = {'Entropy','TargetEntropy'}
        %activeMethodsToPlot = {'Entropy'}
        %activeMethodsToPlot = {'Random'}
        useDomainsToViz = 1
        
        vizTargetLabels = [10 15]
        vizSourceLabels = [25 26];
        
        tommasiDomainsToViz = {...
            '250  124-to-10  15',...
            '250  252-to-10  15',...
            '250  124-to-105   57',...
            '250  124-to-10  15',...
            '30  41-to-105   57',...
            '30  41-to-10  15',...
            '25  26-to-105  145',...
            '25  26-to-10  15',...
            }
        
        cvDomainsToViz = {...
            'A2C',...
            'D2W',...
            'W2D',...
            }
        %{
        ngDomainsToViz = {...
            'ST12CR1',...
            'ST22CR1',...
            'ST32CR1',...
            'ST42CR1',...
            }
        %}
        %{
        ngDomainsToViz = {...
            'CR22CR1',...
            'CR32CR1',...
            'CR42CR1',...
            }
        %}
        ngDomainsToViz = {...
            'ST12CR1',...
            'ST22CR1',...
            'ST32CR1',...
            'ST42CR1',...
            'CR22CR1',...
            'CR32CR1',...
            'CR42CR1',...
        }
    end
    
    properties        
        %sigmaScale
        %k
        %alpha
        %labelsToUse
        numLabeledPerClass                                
        %tommasiLabels                       
        multiSourceTransfer
        makeSubDomains
        addTargetDomain
        numOverlap
        maxSourceSize
        justTargetNoSource
        dataSet
        
        labelNoise
        %Update trueY based on noisy labels.  Hack to make active learning
        %work
        replaceTrueY 
    end
    
    methods(Static, Access=private)
        function [c] = CreateSingleton()
            c = ProjectConfigs();
            c.labelNoise = .0;
            c.replaceTrueY = true;
            
            %{
            c.sigmaScale = .2;
            c.k=inf;
            c.alpha=.9;
            %}
            c.dataSet = ProjectConfigs.data;

            c.numLabeledPerClass=ProjectConfigs.kNumLabeledPerClass;
            c.numTarget = 2;
            c.numSource = 2;
            
            c.tommasiLabels = [10 15 23 25 26 30 41 56 57];
                    
                        
            c.makeSubDomains = true;
            c.addTargetDomain = false;
            c.numOverlap = 0;
            c.justTargetNoSource = false;
            c.maxSourceSize = inf;
            if c.dataSet == Constants.CV_DATA
                c.makeSubDomains = false;
            elseif c.dataSet == Constants.NG_DATA
                c.makeSubDomains = false;
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
            %c.get('mainConfigs').configsStruct.labelsToUse = pc.labelsToUse;
            switch pc.dataSet
                case Constants.CV_DATA
                    c.get('mainConfigs').setCVData(); 
                case Constants.TOMMASI_DATA
                    c.get('mainConfigs').setTommasiData(); 
                case Constants.NG_DATA
                    c.get('mainConfigs').setNGData();
                    c.get('mainConfigs').set('includeDataNameInResultsDirectory',false);
                otherwise
                    error('Unknown data set');
            end
            c.configsStruct.configLoader=ActiveExperimentConfigLoader();
            c.set('transferMethodClass', FuseTransfer());        
            %c.set('transferMethodClass', Transfer());                    
        end
        
        function [c] = SplitConfigs()
            pc = ProjectConfigs.Create();
            c = SplitConfigs();            
            %c.setTommasi();
            c.set20NG();
        end
        
        function [c] = VisualizationConfigs()            
            c = VisualizationConfigs();                                                       
            c.configsStruct.confidenceInterval = VisualizationConfigs.CONF_INTERVAL_BINOMIAL;
            %c.configsStruct.confidenceInterval = VisualizationConfigs.CONF_INTERVAL_STD;
            
            [c.configsStruct.plotConfigs,legend,title] = ...
                ProjectConfigs.makePlotConfigs();
            if ~isempty(legend)
                c.set('legend',legend);
            end
            if ~isempty('title')
                c.set('title',title);
            end            
            
            c.configsStruct.xAxisDisplay = 'Active Learning Iterations';
            c.configsStruct.axisToUse = ProjectConfigs.axisToUse;
            %c.configsStruct.axisToUse = [0 10 -.5 1.1];
            %c.configsStruct.axisToUse = [0 10 -.05 .1];
            pc = ProjectConfigs.Create();
            
            [d] = ProjectConfigs.getResultsDirectory();
            switch ProjectConfigs.data
                case Constants.TOMMASI_DATA
                    c.set('prefix','results_tommasi');
                    c.set('dataSet',{'tommasi_data'});

                    t = ProjectConfigs.vizTargetLabels;
                    s = ProjectConfigs.vizSourceLabels;
                    %[t,s] = pc.GetTargetSourceLabels();
                    transferDir = [num2str(s) '-to-' num2str(t)];
                case Constants.CV_DATA
                    c.set('prefix','');
                    c.set('dataSet',{'CV-small'});
                    transferDir = 'A2C';
                case Constants.NG_DATA                    
                    c.set('prefix','results_ng');
                    c.set('dataSet',{'CR2CR3CR42CR1'});
                    transferDir = 'CR42CR1';
                otherwise
                    error('Unknown data set');
            end            
            c.set('resultsDirectory',[d transferDir]);
            %c.set('resultsDirectory','results_tommasi/tommasi_data/25  23-to-10  15');
        end
        
        function [d] = getResultsDirectory()
            pc = ProjectConfigs.Create();
            switch pc.data
                case Constants.TOMMASI_DATA
                    d = 'results_tommasi/tommasi_data/';
                case Constants.CV_DATA
                    d = 'results/CV-small/';
                case Constants.NG_DATA
                    d = 'results_ng/';
                otherwise
                    error('Unknown data set');
            end           
            if pc.labelNoise > 0
                d = [d '/labelNoise=' num2str(pc.labelNoise) '/'];
            end
        end
        
        function [plotConfigs,legend,title] = makePlotConfigs()  
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};           
            legend = {};
            s = num2str(ProjectConfigs.vizTargetLabels);
            title = s;
            if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE
                methodResultsFileNames{end+1} = ['/Random_HF.mat'];
                legend{end+1} = 'Random';
                methodResultsFileNames{end+1} = ['/Entropy_HF.mat'];
                legend{end+1} = 'Entropy';
                methodResultsFileNames{end+1} = ['/VM_HF.mat'];
                legend{end+1} = 'VM';
            else
                plotFields = {}; 
                legendSuffixes = {};
                %fileSuffix = '_S+T_LLGC-sigmaScale=0.2-alpha=0.9.mat';
                l = ProjectConfigs.labelsPerIteration;
                a = ProjectConfigs.activeIterations;
                %fileSuffix = '_S+T_LogReg_10_5.mat';
                fileSuffix = '_S+T_LogReg-fixReg=1';
                %fileSuffix = '_S+T_LLGC-sigmaScale=0.2-alpha=0.9';
                if l > 0 && a > 0
                    fileSuffix = [fileSuffix '_' num2str(a) '_' num2str(l)]; 
                end
                fileSuffix = [fileSuffix '.mat'];
                if ProjectConfigs.showBothPerformance
                    plotFields = [plotFields {'testResults','preTransferValTest'}];
                    legendSuffixes = [legendSuffixes {'Transfer Performance','Performance'}];
                end
                if ProjectConfigs.showPreTransferPerformance
                    plotFields{end+1} = 'preTransferValTest';
                    legendSuffixes{end+1} = 'Pre Transfer Performance';
                end
                if ProjectConfigs.showTransferPrediction
                    plotFields{end+1} = 'negativeTransferPrediction';
                    legendSuffixes{end+1} = 'Negative Transfer Prediction Accuracy';
                end
                if ProjectConfigs.showTransferDifference
                    plotFields{end+1} = 'transferDifference';
                    legendSuffixes{end+1} = 'Test Error Difference';
                end
                if ProjectConfigs.showTransferPerformance
                    plotFields{end+1} = 'testResults';
                    legendSuffixes{end+1} = 'Transfer Performance';  
                end
                if ProjectConfigs.showPreTransferMeasurePerfDiff
                    plotFields{end+1} = 'transferMeasurePerfDiff';
                    legendSuffixes{end+1} = 'Pre-Transfer abs(Measure-Perf)';
                end
                if ProjectConfigs.showTransferMeasurePerfDiff
                    plotFields{end+1} = 'preTransferMeasurePerfDiff';
                    legendSuffixes{end+1} = 'Transfer abs(Measure-Perf)';
                end
                if ProjectConfigs.showWeightedPrecisionTransferLoss
                    plotFields{end+1} = 'weightedPrecisionTransferLoss';
                    legendSuffixes{end+1} = 'Weighted Precision Transfer Loss';
                end
                %TODO: This assumes activeMethodsToPlot has length one                
                methods = ProjectConfigs.activeMethodsToPlot;
                fields = {};
                for methodIdx=1:length(ProjectConfigs.activeMethodsToPlot)
                    for legendIdx=1:length(legendSuffixes)
                        toPlot = ProjectConfigs.activeMethodsToPlot{methodIdx};
                        methodResultsFileNames{end+1} = ...
                            [toPlot fileSuffix];
                        legend{end+1} = [toPlot ': ' legendSuffixes{legendIdx}];
                        fields{end+1} = plotFields{legendIdx};
                    end                
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
    methods(Access = private)
        function [c] = ProjectConfigs()            
        end
    end
    
end

