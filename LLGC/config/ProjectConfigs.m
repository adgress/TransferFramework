classdef ProjectConfigs < handle
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        %TODO: Group constants for different experiments into structs, make
        %them accessible through dependent properties
        
        NOISY_EXPERIMENT=1
        HYPERPARAMETER_EXPERIMENTS=2
        WEIGHTED_TRANSFER=3
        
        experimentSetting = 3
        
        instance = ProjectConfigs.CreateSingleton()
        
        vizIncreasingNoise = 0
        vizWeights = 1
        vizNoisyAcc = 0
        trainLabels = [23 25]
        labels = [10 15 23 25 26 30]
        
        CLASS_NOISE = .25
    end
    
    properties        
        sigmaScale
        k
        alpha
        labelsToUse
        classNoise
        numLabeledPerClass        
        numFolds
        reg
        noise
        numOverlap
        
        numTarget
        numSource
        tommasiLabels
        addTargetDomain
        
        useOracle
        useUnweighted
        useDataSetWeights 
        useSort
        useOracleNoise
        useJustTarget
        useRobustLoss
        
        useJustTargetNoSource
        
        dataSet
        cvParams
    end
    
    methods(Static, Access=private)
        function [c] = CreateSingleton()
            c = ProjectConfigs();
            c.useOracle=false;
            c.useUnweighted=false;                        
            c.useJustTarget=false;
            c.useJustTargetNoSource=false;
            c.useRobustLoss=false;
            
            c.useOracleNoise=false;
            
            c.useDataSetWeights=false;                        
            
            c.addTargetDomain = true;
            c.useSort=true;
            c.sigmaScale = .2;
            c.k=inf;
            c.alpha=.9;
            c.classNoise = 0;
            c.numFolds = 3;
            c.reg = 0;
            c.noise = 0;
            c.dataSet = Constants.COIL20_DATA;
            c.cvParams = {'reg','noise'};
            if ProjectConfigs.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT                
                c.noise = 0:.05:.4;
                c.labelsToUse = 1:20;
                c.classNoise = .0;
                c.numLabeledPerClass=[10 20 30 40 50];
                c.alpha=.95;
                c.sigmaScale = .2;
                c.reg = 0;
                if c.useOracleNoise
                    c.noise = c.classNoise;
                end
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.HYPERPARAMETER_EXPERIMENTS
                c.dataSet = Constants.USPS_DATA;
                c.sigmaScale = .2:.2:1;
                c.noise = 0;
                %k = [10,30,60,120, inf];
                c.alpha = [.1:.2:.9 .95 .99];
                c.labelsToUse=1:20;
                c.numLabeledPerClass=2:2:8;
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER
                c.useDataSetWeights = true;
                c.dataSet = Constants.TOMMASI_DATA;
                c.labelsToUse = [];
                c.numLabeledPerClass=[5 10 15 20 25];
                %c.numLabeledPerClass=[25];
                %c.reg = [0 1e-6 1e-5 5e-5 1e-4 1e-3 5e-3 1e-2 .05 .1];
                c.reg = .5:.5:4;
                c.numFolds = 3;                
                c.numOverlap = 60;
                c.numTarget = 2;
                c.numSource = 4;
                
                allLabels = ProjectConfigs.labels;
                train = ProjectConfigs.trainLabels;
                c.tommasiLabels = [train setdiff(allLabels,train)];
                c.useDataSetWeights=true;
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
            c.get('mainConfigs').configsStruct.labelsToUse = pc.labelsToUse;
            if pc.dataSet == Constants.COIL20_DATA
                c.get('mainConfigs').setCOIL20(pc.classNoise);
            end
            if pc.dataSet == Constants.TOMMASI_DATA
                c.get('mainConfigs').setTommasiData(); 
            end
            if pc.dataSet == Constants.USPS_DATA
                c.get('mainConfigs').setUSPSSmall();
            end
            c.get('mainConfigs').setLLGCWeightedConfigs();
            c.configsStruct.configLoader = ExperimentConfigLoader();
            if ProjectConfigs.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER
                c.configsStruct.transferMethodClass = FuseTransfer();
                c.configsStruct.configLoader = TransferExperimentConfigLoader();
                c.configsStruct.makeSubDomains = true;
            end
        end
        
        function [c] = SplitConfigs()
            pc = ProjectConfigs.Create();
            c = SplitConfigs();            
            c.setTommasi();
            %c.setUSPSSmall();
            %c.setCOIL20(ProjectConfigs.classNoise);
            %c.setCOIL20(.25);
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
            
            if ProjectConfigs.vizWeights
                c.configsStruct.xAxisField = 'dataSetWeights';
                c.configsStruct.xAxisDisplay = 'Data Set Weights';
                c.configsStruct.sizeToUse = 10;
                c.configsStruct.confidenceInterval = ...
                    VisualizationConfigs.CONF_INTERVAL_BINOMIAL;
            end
            c.configsStruct.vizWeights = ProjectConfigs.vizWeights;
            c.configsStruct.vizNoisyAcc = ProjectConfigs.vizNoisyAcc;
            [c.configsStruct.plotConfigs,legend,title] = ...
                ProjectConfigs.makePlotConfigs();
            if ~isempty(legend)
                c.set('legend',legend);
            end
            if ~isempty('title')
                c.set('title',title);
            end            
            
            if ProjectConfigs.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT
                c.configsStruct.xAxisDisplay = 'Labels Per Class';
            end
            
            c.set('prefix','results');
            
            pc = ProjectConfigs.Create();
            if pc.dataSet == Constants.USPS_DATA
                c.set('dataSet',{'USPS-small'});
            end
            if pc.dataSet == Constants.COIL20_DATA
                c.set('dataSet',{'COIL20'});
            end
            if pc.dataSet == Constants.TOMMASI_DATA
                c.set('prefix','results_tommasi');
                c.set('dataSet',{'tommasi_data'});
            end
        end
        
        function [plotConfigs,legend,title] = makePlotConfigs()  
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};
            pc = ProjectConfigs.Create();
            legend = [];
            title = [];
            if ProjectConfigs.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT
                if ProjectConfigs.vizIncreasingNoise
                     title = 'Accuracy with Label Noise';
                     methodResultsFileNames{end+1} = 'LLGC-Weighted-classNoise=0-unweighted=1.mat';
                     methodResultsFileNames{end+1} = 'LLGC-Weighted-classNoise=0.05-unweighted=1.mat';
                     methodResultsFileNames{end+1} = 'LLGC-Weighted-classNoise=0.15-unweighted=1.mat';
                     methodResultsFileNames{end+1} = 'LLGC-Weighted-classNoise=0.25-unweighted=1.mat';
                     legend = {...
                            'LLGC: 0% Noise',...
                            'LLGC: 5% Noise',...
                            'LLGC: 15% Noise',...                                        
                            'LLGC: 25% Noise',...                                        
                    };
                else

                    title = ['Class Noise: ' num2str(ProjectConfigs.CLASS_NOISE)];
                    if ProjectConfigs.vizNoisyAcc
                        methodResultsFileNames{end+1} = 'LLGC-Weighted-classNoise=%s.mat';
                        legend = {...
                            'Noise Precision',...
                            'Predicted Noise Level',...
                        };
                    else
                        methodResultsFileNames{end+1} = 'LLGC-Weighted-classNoise=%s-oracle=1.mat';
                        methodResultsFileNames{end+1} = 'LLGC-Weighted-classNoise=%s.mat';
                        methodResultsFileNames{end+1} = 'LLGC-Weighted-classNoise=%s-unweighted=1.mat';
                        legend = {...
                            'LLGC: Oracle Weights',...
                            'LLGC: Learn Weights',...
                            'LLGC: Uniform Weights',...                                        
                        };
                    end
                    for i=1:length(methodResultsFileNames)
                        methodResultsFileNames{i} = sprintf(methodResultsFileNames{i},num2str(ProjectConfigs.CLASS_NOISE));
                    end
                end
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.HYPERPARAMETER_EXPERIMENTS
                k=inf;
                alpha=.9;
                sigmaScale='%s';
                %for s=ProjectConfigs.sigmaScale
                %for k=ProjectConfigs.k
                for alpha=pc.alpha                
                        methodResultsFileNames{end+1} = ...
                            ['LLGC-sigmaScale=' sigmaScale ...
                            '-k=' num2str(k)...
                            '-alpha=' num2str(alpha) '.mat'];
                end                   
                %end
                %end            
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER
                labels = ProjectConfigs.labels;
                targetLabels = ProjectConfigs.trainLabels;
                sourceLabels = setdiff(labels,targetLabels);
                
                
                s = [num2str(sourceLabels) '-to-' num2str(targetLabels)];
                %title = s;
                title = 'Target Classes: ';
                classNames = containers.Map;
                classNames('10') = 'Beer Mug';
                classNames('15') = 'Bonsai';
                classNames('23') = 'Bulldozer';
                classNames('25') = 'Cactus';
                classNames('26') = 'Cake';
                classNames('30') = 'Canoe';
                for i=1:length(targetLabels)
                    title = [title classNames(num2str(targetLabels(i)))];
                    if i ~= length(targetLabels)
                        title = [title ', '];
                    end
                end
                d = [s '-numOverlap=60'];
                if ProjectConfigs.vizWeights
                    methodResultsFileNames{end+1} = [d '/S+T_LLGC-Weighted-dataSetWeights=1.mat'];
                    legend = {...                      
                        'LLGC: Learn Weights',...
                    };
                else
                    methodResultsFileNames{end+1} = [d '/S+T_LLGC-Weighted-dataSetWeights=1-oracle=1.mat'];                    
                    methodResultsFileNames{end+1} = [d '/S+T_LLGC-Weighted-dataSetWeights=1.mat'];
                    methodResultsFileNames{end+1} = [d '/S+T_LLGC-Weighted-dataSetWeights=1-justTarget=1.mat'];
                    %methodResultsFileNames{end+1} = [d '/S+T_LLGC-Weighted-dataSetWeights=1-justTargetNoSource=1.mat'];
                    methodResultsFileNames{end+1} = [d '/S+T_LLGC-Weighted-dataSetWeights=1-unweighted=1.mat'];                                
                    legend = {...
                        'LLGC: Oracle Weights',...
                        'LLGC: Learn Weights',...
                        'LLGC: Just Target',...                        
                        'LLGC: Uniform Weights',...                                        
                    };
                    %'LLGC: Just Target No Source',...
                end
            else
                error('TODO');
            end
            plotConfigs = {};
            for fileIdx=1:length(methodResultsFileNames)
                configs = basePlotConfigs.copy();
                configs.set('resultFileName',methodResultsFileNames{fileIdx});
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

