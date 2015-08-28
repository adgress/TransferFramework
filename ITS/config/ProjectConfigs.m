classdef ProjectConfigs < ProjectConfigsBase
    %PROJECTCONFIGSBASE Summary of this class goes here
    %   Detailed explanation goes here
    
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
        useDS1
        useDS3
        useLLGC
        usePRG
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
            c.dataSet = Constants.ITS_DATA;            
            c.QQEdgesExperiment = 0;
            c.QQEdges = 1;
            c.labelsToUse = [];
            c.justCorrectNodes = false;
            c.useLLGCRegression = false;
            useCommonSkills = 1;
            singleSkill = 1;
            
            
            c.useStudentData = 1;
            c.useDS1 = 1;
            c.useDS3 = 0;
            c.usePRG = 0;
            c.graphTransferExp = 1;
            
            c.useLLGC = 0;
            c.useMean = 0;
            
            if c.graphTransferExp
                c.useLLGCRegression = 1;
            end            
            if c.useStudentData
                if c.useDS1
                    %c.dataSetName = 'DS1-69';
                    c.dataSetName = 'DS1-69_reg';
                    %c.labelsToKeep = 1;
                    c.sourceLabels = 4;
                    c.targetLabels = 5;
                    c.numLabeledPerClass = [5 10 15];                                
                elseif c.usePRG
                    c.dataSetName = 'Prgusap1_reg';
                    %c.dataSetName = 'Prgusap1';
                    c.sourceLabels = 4;
                    c.targetLabels = 1;    
                    c.numLabeledPerClass = [5 10 20 30];
                    %c.numLabeledPerClass = [30];
                else
                    c.dataSetName = 'DS2-35_reg';
                    %c.dataSetName = 'DS2-35';
                    %c.labelsToKeep = 1;
                    c.numLabeledPerClass = [2 5 10 15];     
                    %c.numLabeledPerClass = [15];
                    %{
                    c.sourceLabels = 5;
                    c.targetLabels = 6;                    
                    %}
                    c.sourceLabels = 6;
                    c.targetLabels = 14;                    
                end
                c.measure = L2Measure();                
            else
                if c.usePRG
                    c.dataSetName = 'Prgusap1';
                    c.labelsToUse = 1;
                    %c.numLabeledPerClass = [5 10 15];
                    c.numLabeledPerClass = [15];
                elseif c.useDS1
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
                else
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
                end                               
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
            c.nwCVParams(1).values = num2cell(2.^(-5:5));
            %c.nwCVParams(1).values = num2cell(.01*(2:2:100));
            %c.nwCVParams(1).values = num2cell(.2);
            c.alpha = [];
            %c.sigma = .2;            
            c.sigma = [];
            
        end
        function [c] = BatchConfigs()            
            c = BatchConfigs();
        end
        function [c] = SplitConfigs()
            pc = ProjectConfigs.Create();
            c = SplitConfigs();
            useReg = 1;
            c.setITS(pc.dataSetName,useReg);                 
            if pc.usePRG || pc.useDS3
                if pc.useStudentData
                    c.set('maxToUse',500);
                else
                    c.set('maxToUse',[inf 1000]);
                end
            end
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
                if pc.useDS1                    
                    c.set('prefix','results_DS1-69_reg');
                    c.set('dataSet',{'results_DS1-69_reg'});
                    c.set('resultsDirectory','results_DS1-69_reg/');                                        
                elseif pc.usePRG
                    c.set('prefix','results_Prgusap1_reg');
                    c.set('dataSet',{'results_Prgusap1_reg'});
                    c.set('resultsDirectory','results_Prgusap1_reg');
                else
                    c.set('prefix','results_DS2-35_reg');
                    c.set('dataSet',{'results_DS2-35_reg'});
                    c.set('resultsDirectory','results_DS2-35_reg/');
                                        
                end
                c.set('measure',L2Measure());
            else
                c.set('measure',ITSMeasure());
                if pc.useDS1                
                    c.set('prefix','results_DS1-69');
                    c.set('dataSet',{'DS1-69'});
                    c.set('resultsDirectory','results_DS1-69/');
                else
                    c.set('prefix','results_DS2-35');
                    c.set('dataSet',{'DS2-35'});
                    c.set('resultsDirectory',['results_DS2-35/']);                    
                end
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
            if pc.useStudentData
                title = 'Just Students';
                methodResultsFileNames{end+1} = 'LLGC.mat';
                methodResultsFileNames{end+1} = 'NW.mat';
                methodResultsFileNames{end+1} = 'Mean.mat';
                legend = {...
                    'LLGC', ...
                    'NW',...
                    'Mean',...
                    };
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
            
            
            fields = {};
                
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

