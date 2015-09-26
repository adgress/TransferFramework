classdef ProjectConfigs < ProjectConfigsBase
    %PROJECTCONFIGSBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        EXPERIMENT_REGRESSION = 1
        EXPERIMENT_ACTIVE = 2
        experimentSetting = 1
    end
    properties
        dataSetName
        combineGraphFunc
        evaluatePerfFunc
        alpha
        sigma
        useStudentData
        measure
        llgcCVParams
        nwCVParams        
        useLLGC
        useLogReg
        useLinReg
        linRegCVParams
        useAddMod
        addModCVParams
        
        QQEdgesExperiment
        QQEdges
        makeRBF
        labelsToUse
        justCorrectNodes
        useLLGCRegression
        
        sourceLabels
        targetLabels
        graphTransferExp
        useMean
        
        useStudentQuestionGraph
        useLabelsAsX
        
        numLabelsPerIteration
        activeIterations
                
        sigmaVals
    end
    
    methods(Static, Access=private)
        function [c] = CreateSingleton()
            c = ProjectConfigs();
        end       
    end
    
    methods(Static)

        function [c] = Create()
            %c = ProjectConfigs.instance;            
            c = ProjectConfigs.CreateSingleton();
            c.smallResultsFiles = false;
            c.makeRBF = true;                          
            c.QQEdgesExperiment = 0;
            c.QQEdges = 1;
            c.labelsToUse = [];
            c.justCorrectNodes = false;
            c.useLLGCRegression = false;
            useCommonSkills = 0;
            singleSkill = 0;
            
            %c.dataSet = Constants.DS1;
            c.dataSet = Constants.DS2;
            %c.dataSet = Constants.DS3;
            %c.dataSet = Constants.PRG;
            
            c.useStudentData = 1;
            c.graphTransferExp = 1;
            c.useStudentQuestionGraph = 0;
            c.useLabelsAsX = 1;
            
            c.useLLGC = 0;
            c.useMean = 0;
            c.useLinReg = 0;
            c.useAddMod = 0;
            
            c.useLogReg = 0;
            
            if c.graphTransferExp
                c.useLLGCRegression = 1;
            end            
            if c.useStudentData
                switch c.dataSet
                    case Constants.DS1
                        %c.dataSetName = 'DS1-69';
                        c.dataSetName = 'DS1-69_reg';
                        %c.labelsToKeep = 1;
                       
                        %c.sourceLabels = 3:5;
                        c.sourceLabels = 4;
                        c.targetLabels = 4;
                        c.numLabeledPerClass = [5 10 15 20];
                    case Constants.PRG
                        c.dataSetName = 'Prgusap1_reg';
                        %c.dataSetName = 'Prgusap1';
                        
                        %{
                        c.sourceLabels = 2;
                        c.targetLabels = 3;
                        %}
                        %c.sourceLabels = [1 2];
                        c.sourceLabels = 1;
                        c.targetLabels = 3;
                        %c.numLabeledPerClass = [5 10 20 30];
                        c.numLabeledPerClass = [20 50 100 150];
                        %c.numLabeledPerClass = [30];
                    case Constants.DS2
                        c.dataSetName = 'DS2-35_reg';
                        %c.dataSetName = 'DS2-35';
                        %c.labelsToKeep = 1;
                        c.numLabeledPerClass = [5 10 20 40];
                        %c.numLabeledPerClass = [15];
                        %{
                        c.sourceLabels = 5;
                        c.targetLabels = 6;
                        %}
                        %{
                        c.sourceLabels = 6;
                        c.targetLabels = 14;
                        %}
                        %c.sourceLabels = 3:6;
                        c.sourceLabels = 4;
                        c.targetLabels = 6;
                    case Constants.DS3
                        c.dataSetName = 'DS3-39_reg';
                        c.numLabeledPerClass = [20 50 100 150];
                        c.sourceLabels = 2:10;
                        c.targetLabels = 11;
                end
                c.measure = L2Measure();
            else
                switch c.dataSet
                    case Constants.PRG
                        c.dataSetName = 'Prgusap1';
                        c.labelsToUse = 1;
                        %c.numLabeledPerClass = [5 10 15];
                        c.numLabeledPerClass = [15];
                    case Constants.DS1
                        c.dataSetName = 'DS1-69';
                        c.numLabeledPerClass = 2:3;
                        if useCommonSkills
                            c.labelsToUse = [5 6];
                            c.remapLabels = true;
                            c.numLabeledPerClass = 2:2:10;
                        end
                        if singleSkill
                            c.labelsToUse = 5;
                        end
                    case Constants.DS2
                        c.dataSetName = 'DS2-35';
                        c.numLabeledPerClass = 2:5;
                        if useCommonSkills
                            c.numLabeledPerClass = [20];
                            %c.numLabeledPerClass = [2 5 10 20];
                            %c.labelsToUse = [4 5 6 13];
                            c.labelsToUse = [4 5];
                            c.remapLabels = true;
                        end
                        if singleSkill
                            %c.labelsToUse = 5;
                            c.labelsToUse = 4;
                        end
                    case Constants.DS3
                        error('');
                end
            end
            if ProjectConfigs.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE
                c.numLabeledPerClass = 3;
                c.numLabelsPerIteration = 1;
                c.activeIterations = 20;
            end
            if c.useStudentQuestionGraph
                c.dataSetName = [c.dataSetName '_SQgraph'];
            end
            if ~c.useStudentData
                c.measure = ITSMeasure();
                c.combineGraphFunc = @combineGraphs;
                c.evaluatePerfFunc = @evaluateITSPerf;
                if c.justCorrectNodes
                    c.combineGraphFunc = @makeSingleNodeGraph;
                end
            else
                c.measure = L2Measure();
                c.preprocessDataFunc = @makeSkillTransferGraph;
            end
            c.llgcCVParams = struct('key',{'alpha','sigma'});
            
            c.llgcCVParams(1).values = num2cell(10.^(-4:4));            
            c.llgcCVParams(2).values = num2cell(2.^(-4:4));
            %c.llgcCVParams(1).values = num2cell(100);            
            %c.llgcCVParams(2).values = num2cell(.2);
                        
            %c.llgcCVParams(2).values = num2cell([.001 .01 .1:.1:2 10 100 1000]);
            %c.llgcCVParams(2).values = num2cell([.001 .01 .1:.1:2 10 100 1000]);
            %c.nwCVParams = [];
            c.nwCVParams = struct('key','sigma');            
            c.nwCVParams(1).values = num2cell(2.^(5:-1:-5));
            %c.nwCVParams(1).values = num2cell(.5);
            c.alpha = [];
            %c.sigma = .2;            
            c.sigma = [];
            c.linRegCVParams = struct('key','reg');
            c.linRegCVParams(1).values = num2cell(10.^(-10:10));
            
            c.addModCVParams = c.nwCVParams;
            c.sigmaVals = 2.^(-10:10);
        end
        function [c] = BatchConfigs()            
            c = BatchConfigs();
        end
        function [c] = SplitConfigs()
            pc = ProjectConfigs.Create();
            c = SplitConfigs();
            useReg = 1;
            d = pc.dataSetName;
            i = strfind(d,'_SQgraph');
            if ~isempty(i)
                d = d(1:i-1);
            end
            c.setITS(d,useReg,pc.useStudentQuestionGraph);    
            if pc.useLabelsAsX
                c.delete('WName');
                c.set('XName','studentSkills');
            end
            %{
            if pc.dataSet == Constants.PRG || pc.dataSet == Constants.DS3
                if pc.useStudentData
                    c.set('maxToUse',500);
                else
                    c.set('maxToUse',[inf 1000]);
                end
            end
            %}
        end                
        
        function [c] = VisualizationConfigs()            
            c = VisualizationConfigs();                                                       
            
            %c.configsStruct.xAxisField = 'dataSetWeights';
            %c.configsStruct.xAxisDisplay = 'Data Set';
            %c.configsStruct.sizeToUse = 40;
            c.configsStruct.confidenceInterval = ...
                VisualizationConfigs.CONF_INTERVAL_BINOMIAL;
                
            [c.configsStruct.plotConfigs,legend,title] = ...
                ProjectConfigs.makePlotConfigs();
            if ~isempty(legend)
                c.set('legend',legend);
            end
            if ~isempty(title)
                c.set('title',title);
            end
            
            c.set('prefix','results');
            
            pc = ProjectConfigs.Create();
            if pc.useStudentData
                switch pc.dataSet
                    case Constants.DS1
                        c.set('prefix','results_DS1-69_reg');
                        c.set('dataSet',{'results_DS1-69_reg'});
                        c.set('resultsDirectory','results_DS1-69_reg');
                    case Constants.PRG
                        c.set('prefix','results_Prgusap1_reg');
                        c.set('dataSet',{'results_Prgusap1_reg'});
                        c.set('resultsDirectory','results_Prgusap1_reg');
                    case Constants.DS2
                        c.set('prefix','results_DS2-35_reg');
                        c.set('dataSet',{'results_DS2-35_reg'});
                        c.set('resultsDirectory','results_DS2-35_reg');
                    case Constants.DS3
                        c.set('prefix','results_DS3-39_reg');
                        c.set('dataSet',{'results_DS3-39_reg'});
                        c.set('resultsDirectory','results_DS3-39_reg');
                end
                c.set('measure',L2Measure());
            else
                c.set('measure',ITSMeasure());
                switch pc.dataSet
                    case Constants.DS1           
                        c.set('prefix','results_DS1-69');
                        c.set('dataSet',{'DS1-69'});
                        c.set('resultsDirectory','results_DS1-69/');
                    case Constants.DS2
                        c.set('prefix','results_DS2-35');
                        c.set('dataSet',{'DS2-35'});
                        c.set('resultsDirectory',['results_DS2-35/']);
                end
            end
            if pc.useStudentQuestionGraph
                f = {'prefix','dataSet','resultsDirectory'};
                for idx=1:length(f)
                    s = c.get(f{idx});
                    c.set(f{idx},[s '_SQgraph']);
                end
            end
            if pc.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE
                c.set('measure',ActiveLearningL2Measure());
            end
            r = c.get('resultsDirectory');
            c.set('resultsDirectory',[r '/' num2str(pc.labelsToUse) '/']);
        end
        
        function [plotConfigs,legend,title] = makePlotConfigs(targetLabels)  
            
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};
            legend = {};
            pc = ProjectConfigs.Create();

            title = '';
            fields = {};
            if pc.useStudentData
                title = 'Just Students';
                
                sources = [4:6];
                t = pc.targetLabels;
                for idx=1:length(sources)
                    s = sources(idx);
                    methodResultsFileNames{end+1} = ...
                        ['NW-source=' num2str(s) '-target=' num2str(t) '.mat'];
                    legend{end+1} = [num2str(s) ' to ' num2str(t)];
                end
                
                %{
                s = ['-source=' num2str(pc.sourceLabels) '-target=' ...
                    num2str(pc.targetLabels) '.mat'];
                methodResultsFileNames{end+1} = ['LLGC' s];
                methodResultsFileNames{end+1} = ['NW' s];
                methodResultsFileNames{end+1} = ['Mean' s];
                methodResultsFileNames{end+1} = ['LinReg' s];
                methodResultsFileNames{end+1} = ['AddMod' s];
                legend = {...
                    'LLGC', ...
                    'NW',...
                    'Mean',...
                    'LinReg',...
                    'AddMod',...
                    };
                %}
            else
                title = ['Bipartite Student-Question Graph: ' pc.dataSetName];
                if ~isempty(pc.labelsToUse) 
                    title = [title  ', skills: ' num2str(pc.labelsToUse)];
                else
                    title = [title  ', All Skills' ];
                end
                
                methodResultsFileNames{end+1} = 'LLGC.mat';
                methodResultsFileNames{end+1} = 'ITSMethod.mat';
                methodResultsFileNames{end+1} = 'ITSConstant.mat';
                methodResultsFileNames{end+1} = 'LLGC-QQedges=1.mat';
                %methodResultsFileNames{end+1} = 'LLGC-QQedges=0.mat';
                
                legend{end+1} = 'LLGC';
                legend{end+1} = 'NW';
                legend{end+1} = 'Always predict constant';
                legend{end+1} = 'LLGC with all QQ edges';
                %legend{end+1} = 'LLGC with no QQ edges';                
            end
            if pc.experimentSetting == ProjectConfigs.EXPERIMENT_ACTIVE
                methodResultsFileNames = {};
                legend = {};
                s1 = num2str(pc.sourceLabels);
                s2 = num2str(pc.targetLabels);
                
                methodResultsFileNames{end+1} = ['Random_NW-source=' s1 '-target=' s2 '_20_1.mat'];
                legend{end+1} = 'NW - Random Queries';
                fields{end+1} = 'preTransferValTest';
                
                methodResultsFileNames{end+1} = ['MinDistance_NW-source=' s1 '-target=' s2 '_20_1.mat'];
                legend{end+1} = 'NW - Min Distance';
                fields{end+1} = 'preTransferValTest';
                
                methodResultsFileNames{end+1} = ['VarEstimate_NW-source=' s1 '-target=' s2 '_20_1.mat'];
                legend{end+1} = 'NW - Variance Estimate';
                fields{end+1} = 'preTransferValTest';
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
        
    end
    methods(Access = private)
        function [c] = ProjectConfigs()            
        end
    end
    
end

