classdef NearestNeighborMethod < Method
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = NearestNeighborMethod(configs)
            obj = obj@Method(configs);
        end
        function [testResults,metadata] = ...
                trainAndTest(obj,input)
            train = input.train;
            test = input.test;
            validate = input.validate;
            experiment = input.configs;
            metadata = input.metadata;           
            numTest = numel(test.Y);
            k = experiment.k;
            assert(k == 1);
            trainX = train.X;
            trainY = train.Y;
            testX = test.X;
            testY = test.Y;
            testResults = struct();
            if isfield(metadata,'distanceMatrix')
                testResults.testPredicted = ...
                    metadata.distanceMatrix.getTestToLabeledNN(k);
                testResults.trainPredicted = trainY;
            else
                withLabels = train.Y > 0;
                XWithLabels = train.X(withLabels,:);
                YWithLabels = train.Y(withLabels,:);
                if isempty(YWithLabels)
                    testResults.trainPredicted = ones(size(train.X,1),1);
                    testResults.testPredicted = ones(size(test.X,1),1);
                else                                                            
                    %idx = knnsearch(XWithLabels,testX,'k',k);
                    idx = Helpers.KNN(XWithLabels,testX,k);
                    testResults.testPredicted = YWithLabels(idx);                
                    %idx = knnsearch(XWithLabels,trainX,'k',k);
                    idx = Helpers.KNN(XWithLabels,trainX,k);
                    testResults.trainPredicted = YWithLabels(idx);
                end
            end
            assert(~isempty(testResults.testPredicted));
            assert(~isempty(testResults.trainPredicted));
            testResults.testActual = testY;
            testResults.trainActual = trainY;
            testResults.testPredicted = Helpers.getMode(testResults.testPredicted);
            testResults.trainPredicted = Helpers.getMode(testResults.trainPredicted);
            val = sum(testResults.testActual == testResults.testPredicted)/...
                length(testResults.testActual);
            display(['NN Acc: ' num2str(val)]);
            metadata = {};
        end
        function [prefix] = getPrefix(obj)
            prefix = 'kNN';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

