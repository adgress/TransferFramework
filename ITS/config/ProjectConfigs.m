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
            c.useStudentData = true;
            
            if c.useStudentData
                c.dataSetName = 'DS1-69-student';
                c.labelsToKeep = 1;
                %c.numLabeledPerClass = 2:2:10;
                c.numLabeledPerClass = 10;
                c.measure = Measure();
            else
                c.dataSetName = 'DS2-35';                
                c.combineGraphFunc = @combineGraphs;
                c.evaluatePerfFunc = @evaluateITSPerf;
                c.numLabeledPerClass = 3;
                c.measure = ITSMeasure();
            end
            
            c.alpha = 1;
            %c.sigma = .2;            
            c.sigma = 1;
            
        end
        function [c] = BatchConfigs()            
            c = BatchConfigs();
        end
        function [c] = SplitConfigs()
            pc = ProjectConfigs.Create();
            c = SplitConfigs();
            c.setITS(pc.dataSetName);        
        end
    end
    methods(Access = private)
        function [c] = ProjectConfigs()            
        end
    end
    
end

