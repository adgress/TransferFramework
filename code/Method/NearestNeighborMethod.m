classdef NearestNeighborMethod < Method
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = NearestNeighborMethod(configs)
            obj = obj@Method(configs);
        end
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            train = input.train;
            test = input.test;
            validate = input.validate;
            experiment = input.configs;                     
            k = obj.get('k');
            
            testResults = FoldResults();
            if isa(train,'DataSet')
                assert(k==1);
                trainX = [train.X ; validate.X];
                trainY = [train.Y; validate.Y];
                testX = test.X;
                testY = test.Y;
                if isfield(input,'distanceMatrix')
                    testResults.testPredicted = ...
                        input.distanceMatrix.getTestToLabeledNN(k);
                    testResults.trainPredicted = trainY;
                else
                    withLabels = trainY > 0;
                    XWithLabels = trainX(withLabels,:);
                    YWithLabels = trainY(withLabels,:);
                    if isempty(YWithLabels)
                        testResults.trainPredicted = ones(size(trainX,1),1);
                        testResults.testPredicted = ones(size(testX,1),1);
                    else
                        %idx = knnsearch(XWithLabels,testX,'k',k);
                        idxTest = Helpers.KNN(XWithLabels,testX,k);
                        %testResults.testPredicted = YWithLabels(idx);
                        %idx = knnsearch(XWithLabels,trainX,'k',k);
                        idxTrain = Helpers.KNN(XWithLabels,trainX,k);
                        %testResults.trainPredicted = YWithLabels(idx);
                        testResults.yPred = [YWithLabels(idxTrain) ; ...
                            YWithLabels(idxTest)];
                        testResults.dataType = [train.type ; test.type];
                    end
                end
            elseif isa(train,'SimilarityDataSet')
                trainIndex = obj.configs('trainSetIndex');
                testIndex = obj.configs('testSetIndex');                
                                
                train1 = [train.X{trainIndex}];                
                train2 = [train.X{testIndex}];
                trainY = [train.getSubW(trainIndex,testIndex)];               
                if ~isempty(validate)
                    trainY = [trainY ; validate.getSubW(trainIndex,testIndex)];
                    train1 = [train1 ; validate.X{trainIndex}];
                end
                idxTrain = Helpers.KNN(train2,train1,k,obj.configs);
                testResults.trainPredicted = idxTrain;                
                assert(size(idxTrain,1) == size(trainY,1));
                
                test1 = test.X{trainIndex};
                test2 = test.X{testIndex};
                testY = test.getSubW(trainIndex,testIndex);
                idxTest = Helpers.KNN(test2,test1,k,obj.configs);
                testResults.testPredicted = idxTest;
            else
                error('Unknown Data Set type');
            end
                        
            assert(~isempty(testResults.yPred));
            %testResults.testActual = testY;
            %testResults.trainActual = trainY;
            testResults.yActual = [train.Y ; test.Y];
            %testResults.testPredicted = Helpers.getMode(testResults.testPredicted);
            %testResults.trainPredicted = Helpers.getMode(testResults.trainPredicted);            
            
            isTest = testResults.dataType == Constants.TARGET_TEST;
            val = sum(testResults.yPred(isTest) == testResults.yActual(isTest))/...
                sum(isTest);
            display(['NN Acc: ' num2str(val)]);            
        end
        function [prefix] = getPrefix(obj)
            prefix = 'kNN';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {'k'};
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

