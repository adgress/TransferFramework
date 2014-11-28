classdef ProjectConfigs
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        %TODO: Group constants for different experiments into structs, make
        %them accessible through dependent properties
        
        NOISY_EXPERIMENTS=1
        HYPERPARAMETER_EXPERIMENTS=2
        WEIGHTED_TRANSFER=3

        %Weighted Transfer Configs
        sigmaScale = .2
        k=inf
        alpha=.9
        labelsToUse = []
        classNoise = .0
        numLabeledPerClass=[5 10 15]
        experimentSetting = 3
        numFolds = 0
        reg = 1e-4;
        numOverlap = 60
        
        numTarget = 2;
        numSource = 2;
        tommasiLabels = [10 15 23 25 26 30 41 56 57];
        %tommasiLabels = [23 25 26 30 41 56 57];
        
        useOracle=false
        useUnweighted=true
        useDataSetWeights=true
        
        %{
        %Noisy data experiment configs
        sigmaScale = .2
        k=inf
        alpha=.95
        labelsToUse = 1:20
        classNoise = .25
        numLabeledPerClass=[30 40 50]
        experimentSetting = NOISY_EXPERIMENTS
        
        useOracle=false
        useUnweighted=false
        %}
        %{
        %Hyperparameter experiments configs
        sigmaScale = .2:.2:1;
        %k = [10,30,60,120, inf];
        k=inf
        alpha = [.1:.2:.9 .95 .99];
        labelsToUse=1:20
        numLabeledPerClass=2:2:8
        experimentSetting = HYPERPARAMETER_EXPERIMENTS
        %}
    end
    
    methods(Static)                
        function [c] = BatchConfigs()
            c = BatchConfigs();
            c.get('experimentConfigsClass').configsStruct.labelsToUse = ProjectConfigs.labelsToUse;
            %c.get('experimentConfigsClass').setUSPSSmall();
            c.get('experimentConfigsClass').setCOIL20(ProjectConfigs.classNoise);
            c.get('experimentConfigsClass').setLLGCWeightedConfigs();
            
            if ProjectConfigs.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER
                c.configsStruct.transferMethodClass = FuseTransfer();
                c.configsStruct.experimentConfigLoader = 'TransferExperimentConfigLoader';
                c.get('experimentConfigsClass').setTommasiData();
            end
        end
        
        function [c] = SplitConfigs()
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
            if ProjectConfigs.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER
                c.set('prefix','results_tommasi');
            end
        end
        
        function [plotConfigs] = makePlotConfigs()  
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};
            
            if ProjectConfigs.experimentSetting == ProjectConfigs.NOISY_EXPERIMENTS
                methodResultsFileNames{end+1} = 'LLGC-Weighted-oracle=0-unweighted=0.mat';
                methodResultsFileNames{end+1} = 'LLGC-Weighted-oracle=0-unweighted=1.mat';
                methodResultsFileNames{end+1} = 'LLGC-Weighted-oracle=1-unweighted=0.mat';
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.HYPERPARAMETER_EXPERIMENTS
                k=inf;
                alpha=.9;
                sigmaScale='%s';
                %for s=ProjectConfigs.sigmaScale
                %for k=ProjectConfigs.k
                for alpha=ProjectConfigs.alpha                
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
            numTargetLabels = ProjectConfigs.numTarget;
            numSourceLabels = ProjectConfigs.numSource;
            targetlabels = ProjectConfigs.tommasiLabels(1:numTargetLabels);
            sourceLabels = ProjectConfigs.tommasiLabels(numTargetLabels+1:numTargetLabels+numSourceLabels);
            targetDomains = Helpers.MakeCrossProductOrdered(targetlabels,targetlabels);
            %sourceDomains = Helpers.MakeCrossProductNoDupe(sourceLabels,sourceLabels);
            sourceDomains = Helpers.MakeCrossProductOrdered(sourceLabels,sourceLabels);
            labelProduct = Helpers.MakeCrossProduct(targetDomains,sourceDomains);
        end
        
        function [targetDomains,sourceDomains] = MakeDomains()
            numTargetLabels = ProjectConfigs.numTarget;
            numSourceLabels = ProjectConfigs.numSource;
            
            targetlabels = ProjectConfigs.tommasiLabels(1:numTargetLabels);
            targetDomains = Helpers.MakeCrossProductOrdered(targetlabels,targetlabels);
            
            sourceLabels = ProjectConfigs.tommasiLabels(numTargetLabels+1:numTargetLabels+numSourceLabels);            
            sourceDomains = Helpers.MakeCrossProductNoDupe(sourceLabels,sourceLabels);           
        end
        
    end
    
end

