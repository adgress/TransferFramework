classdef ProjectConfigs
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        %TODO: Group constants for different experiments into structs, make
        %them accessible through dependent properties
        
        NOISY_EXPERIMENT=1
        HYPERPARAMETER_EXPERIMENTS=2
        WEIGHTED_TRANSFER=3
        
        experimentSetting = 1
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
        regParams
        numOverlap
        
        numTarget
        numSource
        tommasiLabels
        
        useOracle
        useUnweighted
        useDataSetWeights 
        useSort
        
        dataSet
    end
    
    methods(Static)
        
        function [c] = Create()
            c = ProjectConfigs();
            c.useOracle=false;
            c.useUnweighted=false;
            c.useDataSetWeights=false;
            c.useSort=true;

            c.sigmaScale = .2;
            c.k=inf;
            c.alpha=.9;
            c.classNoise = 0;
            c.numFolds = 1;
            c.reg = 1e-4;
            c.regParams = [0 1e-8 1e-7 1e-6 5e-6 1e-5 5e-5 1e-4 1e-3 1e-2 .1];
            c.dataSet = Constants.COIL20_DATA;
            if ProjectConfigs.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT                
                c.labelsToUse = 1:20;
                c.classNoise = .25;
                c.numLabeledPerClass=[10 20 30 40 50];
                %c.numLabeledPerClass=[30 40 50];
                c.alpha=.95;
                c.sigmaScale = .2;
                if c.useSort
                    c.regParams = [];
                end
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.HYPERPARAMETER_EXPERIMENTS
                c.dataSet = Constants.USPS_DATA;
                c.sigmaScale = .2:.2:1;
                %k = [10,30,60,120, inf];
                c.alpha = [.1:.2:.9 .95 .99];
                c.labelsToUse=1:20;
                c.numLabeledPerClass=2:2:8;
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER
                c.dataSet = Constants.TOMMASI_DATA;
                c.labelsToUse = [];
                c.numLabeledPerClass=[5 10 15];

                c.numFolds = 0;                
                c.numOverlap = 60;
                c.numTarget = 2;
                c.numSource = 2;
                c.tommasiLabels = [10 15 23 25 26 30 41 56 57];

                c.useDataSetWeights=true;
            else
                error('');
            end
        end
        
        function [c] = BatchConfigs()
            c = BatchConfigs();
            pc = ProjectConfigs.Create();
            c.get('experimentConfigsClass').configsStruct.labelsToUse = pc.labelsToUse;
            if pc.dataSet == Constants.COIL20_DATA
                c.get('experimentConfigsClass').setCOIL20(pc.classNoise);
            end
            if pc.dataSet == Constants.TOMMASI_DATA
                c.get('experimentConfigsClass').setTommasiData(); 
            end
            if pc.dataSet == Constants.USPS_DATA
                c.get('experimentConfigsClass').setUSPSSmall();
            end
            c.get('experimentConfigsClass').setLLGCWeightedConfigs();
            c.configsStruct.experimentConfigLoader = 'ExperimentConfigLoader';
            if ProjectConfigs.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER
                c.configsStruct.transferMethodClass = FuseTransfer();
                c.configsStruct.experimentConfigLoader = 'TransferExperimentConfigLoader';
                c.configsStruct.makeSubDomains = true;
            end
        end
        
        function [c] = SplitConfigs()
            pc = ProjectConfigs.Create();
            c = SplitConfigs();            
            %c.setUSPSSmall();
            c.setCOIL20(ProjectConfigs.classNoise);
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
            c.configsStruct.plotConfigs = ProjectConfigs.makePlotConfigs();
            c.configsStruct.numColors = length(c.c.plotConfigs); 
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
        
        function [plotConfigs] = makePlotConfigs()  
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};
            pc = ProjectConfigs.Create();
            if ProjectConfigs.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT
                %{
                methodResultsFileNames{end+1} = 'LLGC-Weighted-oracle=0-unweighted=0.mat';
                methodResultsFileNames{end+1} = 'LLGC-Weighted-oracle=0-unweighted=1.mat';
                methodResultsFileNames{end+1} = 'LLGC-Weighted-oracle=1-unweighted=0.mat';
                %}
                methodResultsFileNames{end+1} = 'LLGC-Weighted-dataSetWeights=0-oracle=0-unweighted=1-sort=0.mat';
                methodResultsFileNames{end+1} = 'LLGC-Weighted-dataSetWeights=0-oracle=0-unweighted=0-sort=0.mat';
                methodResultsFileNames{end+1} = 'LLGC-Weighted-dataSetWeights=0-oracle=1-unweighted=0-sort=0.mat';
                methodResultsFileNames{end+1} = 'LLGC-Weighted-dataSetWeights=0-oracle=0-unweighted=0-sort=1.mat';
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
                d = '23  25-to-10  15';
                methodResultsFileNames{end+1} = [d '/S+T_LLGC-Weighted-dataSetWeights=1-oracle=0-unweighted=0.mat'];
                methodResultsFileNames{end+1} = [d '/S+T_LLGC-Weighted-dataSetWeights=1-oracle=1-unweighted=0.mat'];
                methodResultsFileNames{end+1} = [d '/S+T_LLGC-Weighted-dataSetWeights=1-oracle=0-unweighted=1.mat'];
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
        
        function [labelProduct] = MakeLabelProduct()
            pc = ProjectConfigs.Create();
            numTargetLabels = pc.numTarget;
            numSourceLabels = pc.numSource;
            targetlabels = pc.tommasiLabels(1:numTargetLabels);
            sourceLabels = pc.tommasiLabels(numTargetLabels+1:numTargetLabels+numSourceLabels);
            targetDomains = Helpers.MakeCrossProductOrdered(targetlabels,targetlabels);
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
    
end

