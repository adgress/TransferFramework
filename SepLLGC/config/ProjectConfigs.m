classdef ProjectConfigs < handle
    %PROJECTCONFIGS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        %TODO: Group constants for different experiments into structs, make
        %them accessible through dependent properties
        
        SEP_LLGC_EXPERIMENT=1
        
        experimentSetting = 1
        
        instance = ProjectConfigs.CreateSingleton()
        
        %labels = [10 15 23 25 26 30]
        
        %Tommasi labels
        labels = {[10 15], [10 23], [15 23]}
        
        %Housing labels
        %labels = {[1 2]}
        
        numRandomFeatures = 0
    end
    
    properties        
        sigmaScale
        k
        alpha
        labelsToUse
        numLabeledPerClass        
        numFolds
        reg
        
        tommasiLabels                
        
        dataSet
        cvParams
    end
    
    methods(Static, Access=private)
        function [c] = CreateSingleton()
            c = ProjectConfigs();
            
            
            c.sigmaScale = .2;
            c.k=inf;
            c.alpha=.9;
            c.numFolds = 3;
            c.reg = 0;
            
            c.dataSet = Constants.COIL20_DATA;
            c.cvParams = {'reg'};  
            if ProjectConfigs.experimentSetting == ProjectConfigs.SEP_LLGC_EXPERIMENT                
                c.dataSet = Constants.TOMMASI_DATA;
                c.labelsToUse = [];
                c.numLabeledPerClass=[5 10 15 20 25];
                %c.numLabeledPerClass=[25];
                c.reg = [0 1e-3 1e-2 .1 1 10];
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
            %{
            if pc.dataSet == Constants.TOMMASI_DATA
                c.get('experimentConfigsClass').setTommasiData(); 
            end
            %}
            %c.get('experimentConfigsClass').setHousingBinaryData(); 
            c.get('experimentConfigsClass').setTommasiData(); 
            c.get('experimentConfigsClass').setSepLLGCConfigs();
            %c.get('experimentConfigsClass').setLLGCConfigs();
            c.configsStruct.experimentConfigLoader = 'ExperimentConfigLoader';
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
            c.configsStruct.numColors = length(c.c.plotConfigs); 
            if ~isempty(legend)
                c.set('legend',legend);
                c.configsStruct.numColors = length(legend);
            end
            if ~isempty('title')
                c.set('title',title);
            end                        
            
            c.set('prefix','results');
            
            pc = ProjectConfigs.Create();
            
            if pc.dataSet == Constants.TOMMASI_DATA
                c.set('prefix','results_tommasi');
                c.set('dataSet',{'tommasi_data'});
            end
            
            %{
            c.set('prefix','results_housing');
            c.set('dataSet',{'housingBinary'});
            %}
        end
        
        function [plotConfigs,legend,title] = makePlotConfigs()  
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};
            pc = ProjectConfigs.Create();
            legend = [];
            title = [];
            if ProjectConfigs.experimentSetting == ProjectConfigs.SEP_LLGC_EXPERIMENT
                title = '';
                methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-alpha=0.9-uniform=1.mat';                 
                methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-alpha=0.9-regularized=0.mat';                                  
                legend = {...
                        'LLGC Sep Uniform',...
                        'LLGC Sep Weighted',...                                                .                                        
                };
                methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-alpha=0.9-regularized=1.mat';
                legend{end+1} = 'LLGC Sep Weighted Regularized';
                methodResultsFileNames{end+1} = 'LLGC-sigmaScale=0.2-alpha=0.9.mat';
                legend{end+1} = 'LLGC';
                
                %methodResultsFileNames{end+1} = 'SepLLGC-sigmaScale=0.2-alpha=0.9-sum=1.mat';
                                    %'LLGC Sep Sum',...                                                    
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
        
         function [c] = SplitConfigs()
             c = SplitConfigs();
             c.setHousingBinary();
         end
    end
    methods(Access = private)
        function [c] = ProjectConfigs()            
        end
    end
    
end

