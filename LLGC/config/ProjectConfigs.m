classdef ProjectConfigs
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        %TODO: Group constants for different experiments into structs, make
        %them accessible through dependent properties
        
        NOISY_EXPERIMENT=1
        HYPERPARAMETER_EXPERIMENTS=2
        WEIGHTED_TRANSFER=3
        
        experimentSetting = 3
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
    end
    
    methods(Static)
        
        function [c] = Create()
            c = ProjectConfigs();
            c.useOracle=false;
            c.useUnweighted=false;
            c.useDataSetWeights=false;

            c.sigmaScale = .2;
            c.k=inf;
            c.alpha=.95;
            c.classNoise = 0;
            c.numFolds = 5;
            c.reg = 1e-4;
            c.regParams = [.1 1 10 100];
            if ProjectConfigs.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT                
                c.labelsToUse = 1:20;
                c.classNoise = .25;
                c.numLabeledPerClass=[30 40 50];
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.HYPERPARAMETER_EXPERIMENTS
                c.sigmaScale = .2:.2:1;
                %k = [10,30,60,120, inf];
                c.alpha = [.1:.2:.9 .95 .99];
                c.labelsToUse=1:20;
                c.numLabeledPerClass=2:2:8;
            elseif ProjectConfigs.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER
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
            %c.get('experimentConfigsClass').setUSPSSmall();
            c.get('experimentConfigsClass').setCOIL20(pc.classNoise);
            c.get('experimentConfigsClass').setLLGCWeightedConfigs();
            
            if ProjectConfigs.experimentSetting == ProjectConfigs.WEIGHTED_TRANSFER
                c.configsStruct.transferMethodClass = FuseTransfer();
                c.configsStruct.experimentConfigLoader = 'TransferExperimentConfigLoader';
                c.get('experimentConfigsClass').setTommasiData();
            end
        end
        
        function [c] = SplitConfigs()
            pc = ProjectConfigs.Create();
            c = SplitConfigs();            
            %c.setUSPSSmall();
            pc.setCOIL20(ProjectConfigs.classNoise);
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
            pc = ProjectConfigs.Create();
            if ProjectConfigs.experimentSetting == ProjectConfigs.NOISY_EXPERIMENT
                methodResultsFileNames{end+1} = 'LLGC-Weighted-oracle=0-unweighted=0.mat';
                methodResultsFileNames{end+1} = 'LLGC-Weighted-oracle=0-unweighted=1.mat';
                methodResultsFileNames{end+1} = 'LLGC-Weighted-oracle=1-unweighted=0.mat';
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

