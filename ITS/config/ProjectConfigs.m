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
        useLLGC
        QQEdgesExperiment
        QQEdges
        makeRBF
        labelsToUse
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
            c.useStudentData = false;
            c.useDS1 = 1;
            c.useLLGC = 1;
            c.QQEdgesExperiment = 1;
            c.QQEdges = 1;
            c.labelsToUse = [];
            useCommonSkills = 1;
            if c.useStudentData
                c.dataSetName = 'DS1-69-student';
                c.labelsToKeep = 1;
                %c.numLabeledPerClass = 2:2:10;
                c.numLabeledPerClass = [5 10 15];
                c.measure = Measure();                
            else
                if c.useDS1
                    c.dataSetName = 'DS1-69';
                    c.numLabeledPerClass = 2:3;   
                    if useCommonSkills
                        c.labelsToUse = [5 6];
                        c.remapLabels = true;
                        c.numLabeledPerClass = 2:2:10;
                    end
                else
                    c.dataSetName = 'DS2-35';
                    c.numLabeledPerClass = 2:5;                      
                    if useCommonSkills
                        %c.numLabeledPerClass = [20];
                        c.numLabeledPerClass = [2 5 10 20];
                        %c.labelsToUse = [4 5 6 13];
                        c.labelsToUse = [4 5];
                        c.remapLabels = true;
                    end
                end
                c.combineGraphFunc = @combineGraphs;
                c.evaluatePerfFunc = @evaluateITSPerf;
                
                c.measure = ITSMeasure();
            end
            c.llgcCVParams = struct('key',{'alpha','sigma'});
            
            c.llgcCVParams(1).values = num2cell(10.^(-4:4));            
            c.llgcCVParams(2).values = num2cell(5.^(-4:4));
            
            %{
            c.llgcCVParams(1).values = num2cell(10.^(5));
            c.llgcCVParams(2).values = num2cell([.1]);            
            %}
            %c.nwCVParams = [];
            c.nwCVParams = struct('key','sigma');
            c.nwCVParams(1).values = num2cell(2.^(-6:6));
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
            c.setITS(pc.dataSetName);        
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
                c.set('prefix','results_DS1-69-student');
                c.set('dataSet',{'DS1-69-student'});
                c.set('resultsDirectory','results_DS1-69-student/DS1-69-student');
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
                legend = {...
                    'LLGC', ...
                    'NW',...
                    };
            else
                title = ['Bipartite Student-Question Graph: ' pc.dataSetName];
                
                methodResultsFileNames{end+1} = 'ITSMethod.mat';
                methodResultsFileNames{end+1} = 'LLGC-QQedges=1.mat';
                methodResultsFileNames{end+1} = 'LLGC-QQedges=0.mat';
                methodResultsFileNames{end+1} = 'LLGC.mat';
                
                legend{end+1} = 'NW';
                legend{end+1} = 'LLGC with all QQ edges';
                legend{end+1} = 'LLGC with no QQ edges';
                legend{end+1} = 'LLGC';
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

