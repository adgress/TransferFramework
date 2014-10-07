classdef TauMethod < Method
    %TAUMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function obj = TauMethod(configs)
            obj = obj@Method(configs);
        end
        function [testResults,metadata] = ...
                trainAndTest(obj,input)
            error('Update!');
            train = input.train;
            test = input.test;
            validate = input.validate;
            experiment = input.configs;                     
            tau = obj.configs('tau');;
            
            testResults = struct();
  
            assert(isa(train,'SimilarityDataSet'));
            trainIndex = obj.configs('trainSetIndex');
            testIndex = obj.configs('testSetIndex');
            
            train1 = [train.X{trainIndex}];
            train2 = [train.X{testIndex}];
            trainY = [train.getSubW(trainIndex,testIndex)];
            if ~isempty(validate)
                trainY = [trainY ; validate.getSubW(trainIndex,testIndex)];
                train1 = [train1 ; validate.X{trainIndex}];
            end
            trainIsPositive = trainY > 0;
            Dtrain = Helpers.CreateDistanceMatrix(train1,train2);
            meanTrainDist = mean(Dtrain(:));
            trainPositiveDistances = Dtrain(trainIsPositive);
            
            test1 = test.X{trainIndex};
            test2 = test.X{testIndex};
            testY = test.getSubW(trainIndex,testIndex);
            testIsPositive = testY > 0;
            Dtest = Helpers.CreateDistanceMatrix(test1,test2);
            meanTestDist = mean(Dtest(:));
            testPositiveDistances = Dtest(testIsPositive);
            
            numTau = length(tau);
            testResults.trainPercLessThanTau = zeros(numTau,1);
            testResults.testPercLessThanTau = zeros(numTau,1);
            for i=1:numTau                                
                testResults.trainPercLessThanTau(i) = sum(trainPositiveDistances <= tau(i)*meanTrainDist)/...
                    numel(trainPositiveDistances);                               
                testResults.testPercLessThanTau(i) = sum(testPositiveDistances <= tau(i)*meanTestDist)/...
                    numel(testPositiveDistances);
            end
            metadata = struct();
            testResults.metadata = struct();
        end
        function [prefix] = getPrefix(obj)
            prefix = 'tau';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

