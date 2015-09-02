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
            assert(isempty(train.W));
            
            d = DataSet.Combine(train.copy(),test.copy());
            y = d.Y(d.isLabeled());
            fu = mean(y)*ones(size(d.Y));
            
            testResults.dataFU = sparse(fu);
            testResults.labelSets = [];
            testResults.dataType = d.type;
            testResults.yPred = fu;
            testResults.yActual = d.Y;
            
            
            a = obj.get('measure').evaluate(testResults);
            savedData.val = a.learnerStats.valTest;
            display([obj.getPrefix ': ' num2str(savedData.val)]);
        end
    end
    
end

