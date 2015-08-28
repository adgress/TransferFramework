classdef MeanMethod < Method
    %MEANMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = MeanMethod(configs)
            obj = obj@Method(configs);
        end
        function s = getPrefix(obj)
            s = 'Mean';
        end
        
        function [testResults,savedData] = trainAndTest(obj,input,savedData)   
            if ~exist('savedData','var')
                savedData = struct();
            end
            [testResults,savedData] = runMethod(obj,input,savedData);
        end
        function [testResults,savedData] = runMethod(obj,input,savedData)
            train = input.train;
            test = input.test;
            testResults = FoldResults();   
            
            t = train.copy();
            t.removeTestLabels();
            y = t.Y(t.isLabeled());
            fu = mean(y)*ones(size(t.Y));
            testResults.dataFU = sparse(fu);
            testResults.labelSets = [];
            testResults.dataType = train.type;
            testResults.yPred = fu;
            testResults.yActual = train.Y;
            a = obj.get('measure').evaluate(testResults);
            savedData.val = a.learnerStats.valTest;
            display([obj.getPrefix ': ' num2str(savedData.val)]);
        end
    end
    
end

