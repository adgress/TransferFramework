classdef KMeansMethod < Method
    %KMEANSMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = KMeansMethod(configs)
            obj = obj@Method(configs);
        end
        function [testResults,metadata] = ...
                trainAndTest(obj,input)
            train = input.train;
            test = input.test;
            validate = input.validate;                        
            
            assert(isa(train,'SimilarityDataSet'));
            trainIndex = obj.configs('trainSetIndex');
            testIndex = obj.configs('testSetIndex');
            
            %assert(length(obj.configs('setsToUse')) == 2);
            train1 = [train.X{trainIndex}];
            train2 = [train.X{testIndex}];
            trainY = [train.getSubW(trainIndex,testIndex)];
            if ~isempty(validate)
                trainY = [trainY ; validate.getSubW(trainIndex,testIndex)];
                train1 = [train1 ; validate.X{trainIndex}];
            end            
            
            test1 = test.X{trainIndex};
            test2 = test.X{testIndex};
            testY = test.getSubW(trainIndex,testIndex);            
            
            trainData = [train1;train2];
            testData = [test1;test2];
            
            warning off;
            %{
            [idx, centroids] = kmeans([trainData ; testData],obj.configs('numClusters'),...
                'emptyaction','singleton');
            %}
            [idxTrain, centroidsTrain] = kmeans(trainData,obj.configs('numClusters'),...
                'emptyaction','singleton');
            [idxTest, centroidsTest] = kmeans(testData,obj.configs('numClusters'),...
                'emptyaction','singleton');
            warning on;
            
            %idxTrain = idx(1:size(trainData,1));
            idxTrain1 = idxTrain(1:size(train1,1));
            idxTrain2 = idxTrain(size(train1,1)+1:end);
            
            %idxTest = idx(size(trainData,1)+1:end);
            idxTest1 = idxTest(1:size(test1,1));
            idxTest2 = idxTest(size(test1,1)+1:end);
            
            error('Update this!');
            testResults = FoldResults();
            %testResults.centroids = centroids;
            testResults.centroidsTrain = centroidsTrain;
            testResults.centroidsTest = centroidsTest;
            testResults.numClusters = obj.configs('numClusters');
            
            testResults.trainResults = struct();
            testResults.trainResults.idx = idxTrain;
            testResults.trainResults.idxPerDataset = {idxTrain1,idxTrain2};
            testResults.trainResults.W = trainY;
            
            testResults.testResults = struct();
            testResults.testResults.idx = idxTest;
            testResults.testResults.idxPerDataset = {idxTest1,idxTest2};
            testResults.testResults.W = testY;
            
            metadata = struct();
            testResults.metadata = struct();
        end                        
        
        function [prefix] = getPrefix(obj)
            prefix = 'KMeans';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {'numClusters'};
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

