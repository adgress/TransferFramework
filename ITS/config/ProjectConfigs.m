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
            c.dataSet = Constants.ITS_DATA;
            c.useStudentData = false;
            
            if c.useStudentData
                c.dataSetName = 'DS1-69-student';
                c.labelsToKeep = 1;
                %c.numLabeledPerClass = 2:2:10;
                c.numLabeledPerClass = [5 10 15];
                c.measure = Measure();
            else
                %c.dataSetName = 'DS2-35';
                %c.numLabeledPerClass = [3:5];
                c.dataSetName = 'DS1-69';
                c.numLabeledPerClass = [2:3];
                c.combineGraphFunc = @combineGraphs;
                c.evaluatePerfFunc = @evaluateITSPerf;
                
                c.measure = ITSMeasure();
            end
            c.llgcCVParams = struct('key',{'alpha','sigma'});
            c.llgcCVParams(1).values = num2cell(10.^(-3:3));
            c.llgcCVParams(2).values = num2cell([.01 .1 1 10]);
            
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
                c.set('prefix','results_DS1-69');
                c.set('dataSet',{'DS1-69'});
                c.set('resultsDirectory','results_DS1-69/DS1');
            end
        end
        
        function [plotConfigs,legend,title] = makePlotConfigs(targetLabels)  
            
            basePlotConfigs = Configs();
            basePlotConfigs.set('baselineFile',''); 
            methodResultsFileNames = {};
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
                title = 'Bipartite Student-Question Graph';
                methodResultsFileNames{end+1} = 'LLGC.mat';
                methodResultsFileNames{end+1} = 'ITSMethod.mat';
                legend = {...
                    'LLGC', ...
                    'NW',...
                    };
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

