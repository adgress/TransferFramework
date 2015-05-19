classdef ProjectConfigs < ProjectConfigsBase
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        %TODO: Group constants for different experiments into structs, make
        %them accessible through dependent properties
        
        EXPERIMENT_ACTIVE = 1
        EXPERIMENT_ACTIVE_TRANSFER = 2
        experimentSetting = 1
        
        numRandomFeatures = 0
        
        instance = ProjectConfigs.CreateSingleton()
        
        %data = Constants.TOMMASI_DATA
        %data = Constants.CV_DATA
        
        %learningMethod = 'LogReg'
        %learningMethod = 'SVML2'
        learningMethod = 'NaiveBayes'
        
        createTable = 1;
        
        %data = Constants.NG_DATA
        %data = Constants.HOUSING_DATA
        %data = Constants.YEAST_BINARY_DATA
        %data = Constants.USPS_DATA
        data = Constants.ALL_DATA        
        useTransfer = false;
        
        resampleTarget = true
        %kNumLabeledPerClass = 2        
        logRegNumFeatures = inf
        useL1LogReg = false
        useSVM = false
        useNB = 1
        
        axisToUse = [0 10 -.5 1.1]
        %axisToUse = [0 10 -.05 .1]
        %axisToUse = [0 10 -.5 .2]
        useOverrideConfigs = 1        
        
        useSavedSmallResults = 1
        smallResultsFiles = 1
        useKSR = 0
        
        showBothPerformance = 0
        showPreTransferPerformance = 0
        showTransferPerformance = 0
        
        showTransferDifference = 0
        showTransferPrediction = 0
                        
        showTransferMeasurePerfDiff = 0
        showPreTransferMeasurePerfDiff = 0
        
        showWeightedPrecisionTransferLoss = 0
        showCVBias = 0
         %{
        activeIterations = 10;
        labelsPerIteration = 5;
        %}
        %{
        kNumLabeledPerClass = 2
        activeIterations = 100;
        labelsPerIteration = 1;
        %}
        
        kNumLabeledPerClass = 2
        activeIterations = 20;
        labelsPerIteration = 5;
        
        %labelsPerIteration = 4;
        
        
        %activeMethodsToPlot = {'Random','Entropy','TargetEntropy','SumEntropy'}
        %activeMethodsToPlot = {'Random','Entropy'}
        activeMethodsToPlot = {'Entropy'}
        useDomainsToViz = 1
        fixReg = 0
        activeMethodScale = 1
        
        
        showRegular = 1
        showWeighted1 = 0
        showWeighted2 = 0
        showNewCVWeight = 0
        
        showFixReg = 0
        showTestPerf = 1
        showCVPerf = 0
        showCVDelta = 0
        showDivergence = 0
        
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
        numLabeledPerClass                                                  
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
            if ProjectConfigs.useNB && c.numLabeledPerClass == 2
                c.numLabeledPerClass = 3;
            end
            c.numTarget = 2;
            c.numSource = 2;
            
            c.tommasiLabels = [10 15 23 25 26 30 41 56 57];
                    
                        
            c.makeSubDomains = false;
            c.addTargetDomain = false;
            c.numOverlap = 0;
            c.justTargetNoSource = false;
            c.maxSourceSize = inf;
            switch ProjectConfigs.data
                case Constants.CV_DATA
                    c.makeSubDomains = false;
                case Constants.NG_DATA
                    c.makeSubDomains = false;
                case Constants.HOUSING_DATA
                    c.makeSubDomains = false;
                case Constants.TOMMASI_DATA
                    c.makeSubDomains = ProjectConfigs.experimentSetting ...
                        == ProjectConfigs.EXPERIMENT_ACTIVE_TRANSFER;
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
            c.configsStruct.configLoader=ActiveExperimentConfigLoader();
            c.set('transferMethodClass', FuseTransfer());        
            if ~ProjectConfigs.useTransfer
                c.set('transferMethodClass', []);
            end
            switch pc.dataSet
                case Constants.CV_DATA
                    c.get('mainConfigs').setCVData(); 
                case Constants.TOMMASI_DATA
                    c.get('mainConfigs').setTommasiData(); 
                case Constants.NG_DATA
                    c.get('mainConfigs').setNGData();
                    c.get('mainConfigs').set('includeDataNameInResultsDirectory',false);
                case Constants.HOUSING_DATA
                    c.get('mainConfigs').setHousingBinaryData();    
                case Constants.YEAST_BINARY_DATA
                    c.get('mainConfigs').setYeastBinaryData();    
                case Constants.USPS_DATA
                    c.get('mainConfigs').setUSPS();                    
                otherwise
                    error('Unknown data set');
            end                        
            %c.set('transferMethodClass', Transfer());                    
        end
        
        function [c] = SplitConfigs()
            pc = ProjectConfigs.Create();
            c = SplitConfigs();            
            %c.setTommasi();
            %c.set20NG();
            c.setUSPS();
        end
        
        function [c] = VisualizationConfigs(dataSet)    
            if ~exist('dataSet','var')
                dataSet = ProjectConfigs.data;
            end
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
            c.configsStruct.yAxisDisplay = 'Absolute Error';
            c.configsStruct.xAxisDisplay = 'Active Learning Iterations';
            c.configsStruct.axisToUse = ProjectConfigs.axisToUse;
            if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE
                %c.configsStruct.axisToUse = [0 1 -.1 1];
                c.configsStruct.axisToUse = [0 1 -.5 1];
            else
                c.configsStruct.axisToUse = [0 10 -.5 1.1];
                %c.configsStruct.axisToUse = [0 10 -.05 .1];
            end
            if ProjectConfigs.createTable
                c.set('showPlots',false);
            end
            pc = ProjectConfigs.Create();
            
            [d] = ProjectConfigs.getResultsDirectory(dataSet);
            transferDir = '';
            switch dataSet
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
                    if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE
                        c.set('dataSet',{''});
                        transferDir = 'CR1';
                    end
                case Constants.HOUSING_DATA
                    c.set('prefix','');
                    c.set('dataSet',{''});                    
                case Constants.YEAST_BINARY_DATA
                    c.set('prefix','');
                    c.set('dataSet',{''});
                case Constants.USPS_DATA
                    c.set('prefix','');
                    c.set('dataSet',{''});
                case Constants.ALL_DATA
                    
                    
                otherwise
                    error('Unknown data set');
            end            
            c.set('resultsDirectory',[d transferDir]);
            %c.set('resultsDirectory','results_tommasi/tommasi_data/25  23-to-10  15');
        end
        
        function [d] = getResultsDirectory(dataSet)
            pc = ProjectConfigs.Create();
            if ~exist('dataSet','var')
                dataSet = pc.data;
            end            
            switch dataSet
                case Constants.TOMMASI_DATA
                    d = 'results_tommasi/tommasi_data/';
                case Constants.CV_DATA
                    d = 'results/CV-small/';
                case Constants.NG_DATA
                    d = 'results_ng/';
                case Constants.HOUSING_DATA
                    d = 'results_housing/housingBinary';
                case Constants.YEAST_BINARY_DATA
                    d = 'results_yeast/yeastBinary';
                case Constants.USPS_DATA
                    d = 'results_usps/USPS';
                otherwise
                    error('Unknown data set');
                    
            end           
            if pc.labelNoise > 0
                d = [d '/labelNoise=' num2str(pc.labelNoise) '/'];
            end
        end
        
        function [plotConfigs,legend,title] = makePlotConfigs(learnerName)  
            if ~exist('learnerName','var')
                learnerName = ProjectConfigs.learningMethod;
            end
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};           
            legend = {};
            s = num2str(ProjectConfigs.vizTargetLabels);
            title = s;
            l = ProjectConfigs.labelsPerIteration;
            a = ProjectConfigs.activeIterations;
            plotFields = {}; 
            legendSuffixes = {};            
            fileSuffixes = {};
            fileSuffixLegend = {};
            newCVWeight = [];
            if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE                               
                method = learnerName;
                s = ProjectConfigs.activeMethodScale;
                if ProjectConfigs.showRegular
                    fileSuffixes{end+1} = ['_' method];
                    fileSuffixLegend{end+1} = '';
                    newCVWeight(end+1) = false;
                end                
                if ProjectConfigs.showWeighted1
                    t = '_valWeights=1';
                    if s ~= 1
                        t = ['_valWeights=1_scale=' num2str(s)];
                    end
                    fileSuffixes{end+1} = [t '_' method];
                    fileSuffixLegend{end+1} = 'Our Method';
                    newCVWeight(end+1) = true;
                end
                if ProjectConfigs.showWeighted2
                    t = '_valWeights=2';
                    if s ~= 1
                        t = ['_valWeights=2_scale=' num2str(s)];
                    end
                    fileSuffixes{end+1} = [t '_' method];
                    fileSuffixLegend{end+1} = 'Our Method No CV Weighting';
                    newCVWeight(end+1) = false;
                end
                if ProjectConfigs.showNewCVWeight
                    fileSuffixes{end+1} = ['_valWeights=1_' method '-cvWeight=1'];
                    if s ~= 1
                        fileSuffixes{end} = ['_valWeights=1_scale=' num2str(s) '_' method '-cvWeight=1'];
                    end
                    fileSuffixLegend{end+1} = 'Standord CV Weighting';
                    %{
                    for idx=1:length(fileSuffixes)
                        if newCVWeight(idx)
                            fileSuffixes{idx} = [fileSuffixes{idx} '-cvWeight=1-LOOCV=1'];
                            fileSuffixLegend{idx} = ['NEW WEIGHTS ' fileSuffixLegend{idx}];
                        end
                    end
                    %}
                end
                if ProjectConfigs.showFixReg
                    for idx=1:length(fileSuffixes)
                        fileSuffixes{idx} = [fileSuffixes{idx} '-fixReg=1'];
                    end
                end
                
                %{
                fileSuffixes{end+1} = '_valWeights=3_LogReg';
                fileSuffixLegend{end+1} = 'Weighted3';
                
                fileSuffixes{end+1} = '_valWeights=4_LogReg';
                fileSuffixLegend{end+1} = 'Weighted4';
                %}                                
                if ProjectConfigs.showTestPerf
                    plotFields{end+1} = 'preTransferValTest';
                    legendSuffixes{end+1} = 'Performance';
                end
                if ProjectConfigs.showCVPerf
                    plotFields{end+1} = 'cvPerfDiff';
                    legendSuffixes{end+1} = 'CV Accuracy';
                end
                if ProjectConfigs.showCVDelta
                    plotFields{end+1} = 'cvPerfDelta';
                    legendSuffixes{end+1} = 'CV Delta';
                end
                if ProjectConfigs.showDivergence
                    plotFields{end+1} = 'divergence';
                    legendSuffixes{end+1} = 'Divergence';
                end
                %{
                plotFields{end+1} = 'bestRegs';
                legendSuffixes{end+1} = 'bestRegs';
                
                plotFields{end+1} = 'regs';
                legendSuffixes{end+1} = 'regs';
                %}
            else                
                %{
                fileSuffixes{end+1} = '_S+T_LogReg-fixReg=1';
                fileSuffixLegend{end+1} = '';
                
                fileSuffixes{end+1} = '_valWeights=1_S+T_LogReg-fixReg=1';
                fileSuffixLegend{end+1} = 'Weighted';
                
                fileSuffixes{end+1} = '_valWeights=2_S+T_LogReg-fixReg=1';
                fileSuffixLegend{end+1} = 'Weighted2';
                %}
                %{
                fileSuffixes{end+1} = '_valWeights=3_S+T_LogReg-fixReg=1';
                fileSuffixLegend{end+1} = 'Weighted3';
                
                fileSuffixes{end+1} = '_valWeights=4_S+T_LogReg-fixReg=1';
                fileSuffixLegend{end+1} = 'Weighted4';
                %}
                
                fileSuffixes{end+1} = '_S+T_LogReg';
                fileSuffixLegend{end+1} = '';
                
                fileSuffixes{end+1} = '_valWeights=1_S+T_LogReg';
                fileSuffixLegend{end+1} = 'Weighted';
                
                fileSuffixes{end+1} = '_valWeights=2_S+T_LogReg';
                fileSuffixLegend{end+1} = 'Weighted2';
                
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
                if ProjectConfigs.showCVBias
                    plotFields{end+1} = 'cvPerfDiff';
                    legendSuffixes{end+1} = 'CV Accuracy';
                end
            end
            if l > 0 && a > 0
                for suffixIdx=1:length(fileSuffixes)
                    fileSuffixes{suffixIdx} = ...
                        [fileSuffixes{suffixIdx} '_' num2str(a) '_' num2str(l) '.mat'];
                end
            end
            lineStyles = {'-','--',':'};
            methodSuffixID = [];
            methodSuffixIdx = 1;
            fieldLineStyles = {};
            fields = {};
            for methodIdx=1:length(ProjectConfigs.activeMethodsToPlot)                
                for suffixIdx=1:length(fileSuffixes)
                    
                    for legendIdx=1:length(legendSuffixes)
                        toPlot = ProjectConfigs.activeMethodsToPlot{methodIdx};
                        methodResultsFileNames{end+1} = ...
                            [toPlot fileSuffixes{suffixIdx}];
                        legend{end+1} = [toPlot ': ' ...
                            legendSuffixes{legendIdx} ' ' fileSuffixLegend{suffixIdx}];
                        fields{end+1} = plotFields{legendIdx};
                        fieldLineStyles{end+1} = lineStyles{legendIdx};
                        methodSuffixID(end+1) = methodSuffixIdx;
                    end
                    methodSuffixIdx = methodSuffixIdx+1;
                end
            end
            plotConfigs = {};
            for fileIdx=1:length(methodResultsFileNames)
                configs = basePlotConfigs.copy();
                configs.set('resultFileName',methodResultsFileNames{fileIdx});
                if exist('fields','var')
                    configs.set('fieldToPlot',fields{fileIdx});
                end
                configs.set('lineStyle',fieldLineStyles{fileIdx});
                configs.set('methodId',methodSuffixID(fileIdx));
                plotConfigs{end+1} = configs;
            end
        end                
    end    
    methods(Access = private)
        function [c] = ProjectConfigs()            
        end
    end
    
end

