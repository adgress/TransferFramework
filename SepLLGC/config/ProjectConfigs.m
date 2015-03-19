classdef ProjectConfigs < handle
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        %TODO: Group constants for different experiments into structs, make
        %them accessible through dependent properties
        
        SEP_LLGC_EXPERIMENT=1
        
        experimentSetting = 1
        
        instance = ProjectConfigs.CreateSingleton()
        
        useKSR = false
        
        %data = Constants.HOUSING_DATA
        %data = Constants.TOMMASI_DATA
        data = Constants.YEAST_BINARY_DATA
        
        useSavedSmallResults = 1
        
        useSepLLGC = 1
        
        %tommasiLabels = [10 15 23 25 26 30]
        %housingLabels = [1 2];
        
        %Tommasi labels
        tommasiVizLabels = {[10 15], [10 23], [15 23]}
        
        %Housing labels
        housingVizLabels = {[1 2]}
        
        numRandomFeatures = 0
        
        plotFeatureSmoothness = 0
    end
    
    properties        
        sigmaScale
        k
        alpha
        labelsToUse
        numLabeledPerClass        
        numFolds
        reg        
        
        dataSet
        cvParams
        
        makeSubDomains
        labelNoise
        computeLossFunction
        processMeasureResults
        rerunExperiments
    end
    
    methods(Static, Access=private)
        function [c] = CreateSingleton()
            c = ProjectConfigs();
            c.rerunExperiments = 0;
            
            c.computeLossFunction = true;
            c.processMeasureResults = false;
            
            c.makeSubDomains = false;
            c.labelNoise = 0;
            c.sigmaScale = .2;
            c.k=inf;
            c.alpha=10.^(-5:5);
            c.numFolds = 3;
            c.reg = 0;
            
            c.dataSet = Constants.COIL20_DATA;
            c.cvParams = {'reg'};  
            if ProjectConfigs.experimentSetting == ProjectConfigs.SEP_LLGC_EXPERIMENT                
                c.dataSet = Constants.TOMMASI_DATA;
                c.labelsToUse = [];
                %c.numLabeledPerClass=[5 10 15 20 25];
                c.numLabeledPerClass=[10 20 30 40 50];
                c.numLabeledPerClass=50;
                c.reg = fliplr([0 10.^(-6:6)]);
                c.numFolds = 3;                

            else
                error('');
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

            switch ProjectConfigs.data
                case Constants.HOUSING_DATA
                    c.get('mainConfigs').setHousingBinaryData(); 
                case Constants.TOMMASI_DATA
                    c.get('mainConfigs').setTommasiData(); 
                case Constants.YEAST_BINARY_DATA
                    c.get('mainConfigs').setYeastBinaryData();
            end
            if ProjectConfigs.useSepLLGC
                c.get('mainConfigs').setSepLLGCConfigs();
            else
                c.get('mainConfigs').setLLGCConfigs();
            end
            c.get('mainConfigs').get('learners').set('alpha',pc.alpha);
            c.configsStruct.configLoader = ExperimentConfigLoader();
        end
        
        function [c] = VisualizationConfigs()
            %error('TODO');
            c = VisualizationConfigs();                                           
            c.configsStruct.showPostTransferMeasures = false;
            c.configsStruct.showPreTransferMeasures = false;
            c.configsStruct.showRelativePerformance = false;
            c.configsStruct.showRelativeMeasures = false;
            c.configsStruct.showSoftMeasures = false;
            c.configsStruct.showHardMeasures = false;
            c.configsStruct.showLLGCMeasure = false;
            c.configsStruct.vizMeasureCorrelation = false;
            [c.configsStruct.plotConfigs,legend,title] = ...
                ProjectConfigs.makePlotConfigs();            
            if ~isempty(legend)
                c.set('legend',legend);
            end
            if ~isempty('title')
                c.set('title',title);
            end                        
            
            c.set('prefix','results');
            
            pc = ProjectConfigs.Create();
            
            switch ProjectConfigs.data
                case Constants.TOMMASI_DATA
                    c.set('prefix','results_tommasi');
                    c.set('dataSet',{'tommasi_data'});
                    c.set('resultsDirectory','results_tommasi/tommasi_data');
                case Constants.HOUSING_DATA
                    c.set('prefix','results_housing');
                    c.set('dataSet',{'housingBinary'});
                    c.set('resultsDirectory','results_housing/housingBinary');
                case Constants.YEAST_BINARY_DATA
                    c.set('prefix','results_yeast');
                    c.set('dataSet',{'yeastBinary'});
                    c.set('resultsDirectory','results_yeast/yeastBinary');
                otherwise
                    error('');
                    
            end
            if ProjectConfigs.plotFeatureSmoothness
                c.delete('axisToUse');
            end
        end
        
        function [labels] = getLabels()
            switch ProjectConfigs.data
                case Constants.TOMMASI_DATA
                    labels = ProjectConfigs.tommasiVizLabels;
                case Constants.HOUSING_DATA
                    labels = ProjectConfigs.housingVizLabels;
                case Constants.YEAST_BINARY_DATA
                    labels = {[1 8]};
                otherwise
                    error('');
            end
        end
        
        function [plotConfigs,legend,title] = makePlotConfigs()  
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};
            pc = ProjectConfigs.Create();
            legend = {};
            title = [];
            fields = {};
            if ProjectConfigs.experimentSetting == ProjectConfigs.SEP_LLGC_EXPERIMENT
                if ProjectConfigs.plotFeatureSmoothness
                    methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-regularized=1-addBias=1-slZ=1-redoLLGC=1-negY=1.mat';
                    legend{end+1} = 'SepLLGC: Mean Weighted Smoothness';
                    fields{end+1} = 'weightedFeatureSmoothness';
                    
                    methodResultsFileNames{end+1} = 'LLGC-sigmaScale=0.2.mat';
                    legend{end+1} = 'LLGC: Smoothness';       
                    fields{end+1} = 'featureSmoothness';
                else
                    title = '';
                    %{
                    methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-regularized=1.mat';
                    legend{end+1} = 'LLGC Sep Weighted Regularized';
                    fields{end+1} = 'testResults';
                    %}
                    %{
                    methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-regularized=1-addBias=1-slZ=1.mat';
                    legend{end+1} = 'LLGC Sep Weighted Regularized with Bias';
                    fields{end+1} = 'testResults';
                    %}

                    methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-regularized=1-addBias=1-slZ=1-redoLLGC=1-negY=1.mat';
                    legend{end+1} = 'LLGC Sep Weighted Regularized with Bias - Best Feature';
                    fields{end+1} = 'featureTestAccsBest';

                    %{
                    methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-regularized=1-addBias=1-slZ=1-nonneg=1-redoLLGC=1.mat';
                    legend{end+1} = 'LLGC Sep Weighted Regularized with Bias, nonneg';
                    fields{end+1} = 'testResults';
                    %}
                    methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-regularized=1-addBias=1-slZ=1-redoLLGC=1-negY=1.mat';
                    legend{end+1} = 'LLGC Sep Subset';
                    fields{end+1} = 'subsetTestAcc';
                    %{
                    methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-regularized=1-addBias=1-lasso=1-slZ=1.mat';
                    legend{end+1} = 'LLGC Sep Weighted Regularized Lasso';
                    fields{end+1} = 'testResults';
                    %}
                    methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-regularized=1-addBias=1-slZ=1-redoLLGC=1-negY=1.mat';
                    legend{end+1} = 'LLGC Weighted Reg Bias, negY';       
                    fields{end+1} = 'testResults';
                    
                    methodResultsFileNames{end+1} = '_just1_SepLLGC-sigmaScale=0.2-regularized=1-addBias=1-slZ=1-redoLLGC=1-negY=1.mat';
                    legend{end+1} = 'LLGC Weighted Reg Bias, negY, normRows=0';       
                    fields{end+1} = 'testResults';

                    methodResultsFileNames{end+1} = 'LLGC-sigmaScale=0.2.mat';
                    legend{end+1} = 'LLGC';       
                    fields{end+1} = 'testResults';
                    %methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-alpha=0.9-sum=1.mat';
                                        %'LLGC Sep Sum',...     
                end
            else
                error('TODO');
            end
            plotConfigs = {};
            for fileIdx=1:length(methodResultsFileNames)
                configs = basePlotConfigs.copy();
                configs.set('resultFileName',methodResultsFileNames{fileIdx});
                configs.set('fieldToPlot',fields{fileIdx});
                plotConfigs{end+1} = configs;
            end
        end     
        
         function [c] = SplitConfigs()
             c = SplitConfigs();
             c.setYeastUCIBinary();
         end
    end
    methods(Access = private)
        function [c] = ProjectConfigs()            
        end
    end
    
end

