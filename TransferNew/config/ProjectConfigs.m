classdef ProjectConfigs < ProjectConfigsBase
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        %TODO: Group constants for different experiments into structs, make
        %them accessible through dependent properties
        
        SPARSITY_TRANFER_EXPERIMENT = 1
        INEQUALITY_TRANSFER_EXPERIMENT = 2
        HYPOTHESIS_TRANSFER_EXPERIMENT = 3
        
        experimentSetting = 3
        
        instance = ProjectConfigs.CreateSingleton()        
        %useTransfer = false
        useTransfer = true
        vizWeights = 0
        vizLayeredWeights = 0
        vizCoefficients = 0
    end
    
    properties    
        sigma
        numFolds
        reg
        regTransfer
        numOverlap
        
        addTargetDomain
        useJustTarget
        
        cvParams
        
        useHypothesisTransfer
        noTransfer
        
        syntheticDir
        targetSuffix
        sourceSuffix
        
        maxSourceSize
    end
    
    methods(Static, Access=private)
        function [c] = CreateSingleton()
            c = ProjectConfigs();                               
            
            c.computeLossFunction = true;
            c.processMeasureResults = false;
            c.rerunExperiments = false;            
            
            c.useHypothesisTransfer = 1;            
            c.useJustTarget=false;
            
            c.noTransfer = 0;            
            %c.regTransfer = [0];
            c.sigma = (2.^(2:4));

            c.labelsToKeep = [];

            switch ProjectConfigs.experimentSetting
                case ProjectConfigs.SPARSITY_TRANFER_EXPERIMENT
                    c.reg = fliplr([0 2.^(-10:8)]);
                    c.regTransfer = fliplr([0 .5 1 2 4]);
                    c.dataSet = Constants.SPARSE_SYNTHETIC_DATA;

                    c.syntheticDir = 'syntheticSparse';
                    %c.syntheticSuffix = 'n=500,p=20,sigma=0.1';
                    c.targetSuffix = 'n=500,p=50,sigma=0.1';
                    c.sourceSuffix = 'n=500,p=50,sigma=0.1';
                    c.cvParams = {'reg','regTransfer'};
                case ProjectConfigs.INEQUALITY_TRANSFER_EXPERIMENT
                    c.dataSet = Constants.POLYNOMIRAL_SYNTHETIC_DATA;
                    c.reg = fliplr([0 .01 .1 1 10 100]);
                    c.sigma = fliplr([.001 .01 .1 1 10]);
                    c.syntheticDir = 'syntheticPolynomial';
                    c.targetSuffix = 'n=100,degree=2,sigma=0.5';
                    c.sourceSuffix = 'n=100,degree=3,sigma=0.5';
                    c.cvParams = {'reg','sigma'};
                case ProjectConfigs.HYPOTHESIS_TRANSFER_EXPERIMENT
                    c.dataSet = Constants.TOMMASI_DATA;
                    %c.dataSet = Constants.NG_DATA;
                    c.reg = ([0 .2:.2:.8]);
                    %c.reg = fliplr([10.^(-1:8)]);                   
                    %c.reg = 0;
                    c.sigma = fliplr([.001 .01 .1 1 10]);
                    %c.sigma = fliplr([.01]);
                    c.syntheticDir = 'syntheticPolynomial';
                    c.targetSuffix = 'n=100,degree=2,sigma=0.5';
                    c.sourceSuffix = 'n=100,degree=3,sigma=0.5';
                    c.cvParams = {'reg','sigma'};
            end
            
            switch c.dataSet
                case Constants.SPARSE_SYNTHETIC_DATA
                    c.numLabeledPerClass=[10 20 50 100 300];
                    %c.numLabeledPerClass=[100];
                case Constants.POLYNOMIRAL_SYNTHETIC_DATA
                    c.numLabeledPerClass=[5 10 20 40 80];
                case Constants.TOMMASI_DATA                    
                    c.numLabeledPerClass=[5 10 20];
                    %c.numLabeledPerClass=[20];
                    c.makeSubDomains = true;
                    c.addTargetDomain = true;
                    c.maxSourceSize = inf;
                    c.numOverlap = 30;
                case Constants.NG_DATA
                    c.addTargetDomain = false;
                    c.makeSubDomains = false;
                    %c.numLabeledPerClass=[20 40 60 80 100 120 140];
                    c.numLabeledPerClass=[3 5 10 15 20 40];
            end
        end
    end
    
    methods(Static)
               
        function [c] = Create()
            %c = ProjectConfigs.instance;
            c = ProjectConfigs.CreateSingleton();
        end
        
        function [c] = BatchConfigs()
            c = BatchConfigs();
            pc = ProjectConfigs.Create();
            %c.get('mainConfigs').configsStruct.labelsToUse = pc.labelsToUse;
            switch pc.dataSet
                case Constants.COIL20_DATA
                    c.get('mainConfigs').setCOIL20(pc.labelNoise);
                case Constants.TOMMASI_DATA
                    c.get('mainConfigs').setTommasiData(); 
                case Constants.USPS_DATA
                    c.get('mainConfigs').setUSPSSmall();
                case Constants.HOUSING_DATA
                    c.get('mainConfigs').setHousingBinaryData();
                case Constants.NG_DATA
                    c.get('mainConfigs').setNGData();
                case Constants.SPARSE_SYNTHETIC_DATA
                    c.get('mainConfigs').setSynthetic(...
                        pc.syntheticDir,'S2T');
                case Constants.POLYNOMIRAL_SYNTHETIC_DATA
                    c.get('mainConfigs').setSyntheticPolynomial(pc.syntheticDir,'S2T');
                otherwise
                    error('unknown data set');
            end
            if pc.dataSet == Constants.NG_DATA
                c.get('mainConfigs').get('learners').configs.set('zscore',0)
            end
            c.configsStruct.configLoader = ExperimentConfigLoader();            

            c.configsStruct.transferMethodClass = PriorTransfer();
            c.configsStruct.configLoader = TransferExperimentConfigLoader();
            c.configsStruct.makeSubDomains = true;
            
        end
        
        function [c] = SplitConfigs()
            pc = ProjectConfigs.Create();
            c = SplitConfigs();                        
            c.setSyntheticTransfer(['Data/' pc.syntheticDir],...
                pc.targetSuffix,pc.sourceSuffix);
        end
        
        function [c] = VisualizationConfigs()
            c = VisualizationConfigs();                                                       
                        
            c.configsStruct.confidenceInterval = ...
                VisualizationConfigs.CONF_INTERVAL_BINOMIAL;
            c.set('yAxisDisplay','Error');            
            c.configsStruct.xAxisDisplay = 'Training Size';
            [c.configsStruct.plotConfigs,legend,title] = ...
                ProjectConfigs.makePlotConfigs();
            if ~isempty(legend)
                c.set('legend',legend);
            end
            if ~isempty('title')
                c.set('title',title);
            end            
            
            if ProjectConfigs.vizWeights || ProjectConfigs.vizLayeredWeights
                c.configsStruct.xAxisField = 'dataSetWeights';
                c.configsStruct.xAxisDisplay = 'Data Set';
                c.configsStruct.sizeToUse = 5;
                c.configsStruct.confidenceInterval = ...
                    VisualizationConfigs.CONF_INTERVAL_BINOMIAL;
                c.set('vizBarChartForField',true);
                %c.set('normalizeField',true);
                c.set('yAxisDisplay','Weight');
            end
            c.configsStruct.vizWeights = ProjectConfigs.vizWeights;
            
            c.set('prefix','results');
            c.set('Measure',Measure());
            pc = ProjectConfigs.Create();
            switch pc.dataSet
                case Constants.SPARSE_SYNTHETIC_DATA
                    c.set('prefix','results_synthetic_sparse');
                    c.set('dataSet',{'syntheticSparse'});
                    c.set('resultsDirectory','results_synthetic_sparse/syntheticSparse');
                case Constants.POLYNOMIRAL_SYNTHETIC_DATA
                    c.set('prefix','results_synthetic_polynomial');
                    c.set('dataSet',{'syntheticPolynomial'});
                    c.set('resultsDirectory','results_synthetic_polynomial/syntheticPolynomial');
                case Constants.TOMMASI_DATA
                    c.set('prefix','results_tommasi');
                    c.set('dataSet',{'tommasi_data'});
                    c.set('resultsDirectory','results_tommasi/tommasi_data');
                case Constants.NG_DATA
                    
                    c.set('prefix','results_ng');
                    c.set('dataSet',{'20news-bydate/splitData'});
                    c.set('resultsDirectory','results_ng/20news-bydate/splitData');
                    
                    %{
                    c.set('prefix','results_ng (little labeled data, ST1 ST2)');
                    c.set('dataSet',{'20news-bydate/splitData'});
                    c.set('resultsDirectory','results_ng (little labeled data, ST1 ST2)/20news-bydate/splitData');
                    %}
                otherwise
                    error('unknown data set');
            end
            
        end
        
        function [plotConfigs,legend,title] = makePlotConfigs()  
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};
            pc = ProjectConfigs.Create();
            legend = {};            
            fields = {};
            
            switch pc.dataSet
                case Constants.SPARSE_SYNTHETIC_DATA
                    title = 'Sparsity Transfer';
                    methodResultsFileNames{end+1} = 'Prior_Lasso.mat';
                    legend{end+1} = 'Lasso';
                    methodResultsFileNames{end+1} = 'Prior_HypTransfer.mat';
                    legend{end+1} = 'Lasso Transfer';
                case Constants.POLYNOMIRAL_SYNTHETIC_DATA
                    title = 'Inequality Transfer';
                    methodResultsFileNames{end+1} = 'Prior_NW.mat';
                    legend{end+1} = 'NW No Transfer';
                    methodResultsFileNames{end+1} = 'Prior_InequalityTransfer.mat';
                    legend{end+1} = 'NW Transfer';
                case Constants.TOMMASI_DATA
                    title = 'Hypothesis Transfer';
                    %{
                    methodResultsFileNames{end+1} = 'Prior_HypTran-noTransfer=1-useNW=1-useBaseNW=1.mat';
                    legend{end+1} = 'NW';
                    methodResultsFileNames{end+1} = 'Prior_HypTran-useNW=1.mat';
                    legend{end+1} = 'HypTran NW';
                    %}
                    methodResultsFileNames{end+1} = 'Prior_HypTran-targetMethod=Liblinear-noTransfer=1.mat';
                    legend{end+1} = 'l2 LogReg';
                    methodResultsFileNames{end+1} = 'Prior_HypTran-targetMethod=Liblinear.mat';
                    legend{end+1} = 'HypTran l2 LogReg';
                    methodResultsFileNames{end+1} = 'Prior_HypTran-targetMethod=Liblinear-oracle=1.mat';
                    legend{end+1} = 'HypTran l2 LogReg Oracle';
                    methodResultsFileNames{end+1} = 'Prior_LayeredHypTran-targetMethod=Liblinear.mat';
                    legend{end+1} = 'LayeredHypTran';
                case Constants.NG_DATA
                    title = 'Hypothesis Transfer';
                    %{
                    methodResultsFileNames{end+1} = 'Prior_HypTran-noTransfer=1-useNW=1-useBaseNW=1.mat';
                    legend{end+1} = 'NW';
                    methodResultsFileNames{end+1} = 'Prior_HypTran-useNW=1.mat';
                    legend{end+1} = 'HypTran NW';
                    %}
                    methodResultsFileNames{end+1} = 'Prior_HypTran-targetMethod=Liblinear-noTransfer=1.mat';
                    legend{end+1} = 'l2 LogReg';
                    methodResultsFileNames{end+1} = 'Prior_HypTran-targetMethod=Liblinear.mat';
                    legend{end+1} = 'HypTran l2 LogReg';
                    methodResultsFileNames{end+1} = 'Prior_HypTran-targetMethod=Liblinear-oracle=1.mat';
                    legend{end+1} = 'HypTran l2 LogReg Oracle';
                    methodResultsFileNames{end+1} = 'Prior_LayeredHypTran-targetMethod=Liblinear.mat';
                    legend{end+1} = 'LayeredHypTran';
            end
            if ProjectConfigs.vizWeights
                
                methodResultsFileNames = {'Prior_HypTran-targetMethod=Liblinear.mat'};
                
                legend = {'HypTran l2 LogReg'};
                fields = {'dataSetWeights'};
            elseif ProjectConfigs.vizLayeredWeights
                methodResultsFileNames = {'Prior_LayeredHypTran-targetMethod=Liblinear.mat'};
                
                legend = {'LayeredHypTran l2 LogReg'};
                fields = {'dataSetWeights'};
            end
            plotConfigs = {};
            for fileIdx=1:length(methodResultsFileNames)
                configs = basePlotConfigs.copy();
                configs.set('resultFileName',methodResultsFileNames{fileIdx});
                configs.set('lineStyle','-');
                if ~isempty(fields)
                    configs.set('fieldToPlot',fields{fileIdx});
                else
                    configs.set('fieldToPlot','testResults');
                end
                configs.set('methodId',num2str(fileIdx));
                plotConfigs{end+1} = configs;
            end
        end
        
        function [targetLabels,sourceLabels] = GetTargetSourceLabels()
            pc = ProjectConfigs.Create();
            numTargetLabels = pc.numTarget;
            numSourceLabels = pc.numSource;
            targetLabels = pc.tommasiLabels(1:numTargetLabels);
            sourceLabels = pc.tommasiLabels(numTargetLabels+1:numTargetLabels+numSourceLabels);
        end
        
        function [labelProduct] = MakeLabelProduct()       
            error('What target-source labels should we use?');
            %[targetLabels,sourceLabels] = ProjectConfigs.GetTargetSourceLabels();
            
            targetDomains = Helpers.MakeCrossProductOrdered(targetLabels,targetLabels);
            %sourceDomains = Helpers.MakeCrossProductNoDupe(sourceLabels,sourceLabels);
            sourceDomains = Helpers.MakeCrossProductOrdered(sourceLabels,sourceLabels);
            labelProduct = Helpers.MakeCrossProduct(targetDomains,sourceDomains);
        end
        
        function [targetDomains,sourceDomains] = MakeDomains()
            pc = ProjectConfigs.Create();
            numTargetLabels = pc.numTarget;
            numSourceLabels = pc.numSource;
            
            targetlabels = pc.tommasiLabels(1:numTargetLabels);
            targetDomains = Helpers.MakeCrossProductOrdered(targetlabels,targetlabels);
            
            sourceLabels = pc.tommasiLabels(numTargetLabels+1:numTargetLabels+numSourceLabels);            
            sourceDomains = Helpers.MakeCrossProductNoDupe(sourceLabels,sourceLabels);           
        end
        
    end
    methods(Access = private)
        function [c] = ProjectConfigs()            
        end
    end
    
end

