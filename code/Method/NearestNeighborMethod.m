classdef NearestNeighborMethod < Method
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = NearestNeighborMethod
            %obj = obj@Method();
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
            %assert(k == 1);
            trainX = train.X;
            trainY = train.Y;
            testX = test.X;
            testY = test.Y;
            testResults = struct();
            if isfield(metadata,'distanceMatrix')
                %{
                numTrain = size(trainX,1);
                numTest = size(testX,1);
                labeled = metadata.Y > 0;
                labeledDist = ...
                    metadata.distanceMatrix(numTrain+1:numTrain+numTest,...
                    labeled);
                labeledY = metadata.Y(labeled);
                [~, minIDX] = min(labeledDist);
                testResults.testPredicted = labeledY(minIDX);
                %}
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
    end
    
    methods(Static)
        function [name] = getMethodName(configs)
            if nargin < 1
                name = 'kNN';
            else
                name = ['kNN, k=' num2str(configs('k'))];
            end
        end
    end
    
end

