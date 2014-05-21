classdef GuessMethod < Method
    %GUESSMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = GuessMethod(configs)
            obj = obj@Method(configs);
        end
        
        function [testResults,metadata] = ...
                trainAndTest(obj,input)
            train = input.train;
            test = input.test;
            validate = input.validate;
            experiment = input.configs;                     
            k = experiment.k;
            
            testResults = struct();
            if isa(train,'DataSet')                
                trainY = [train.Y; validate.Y];                
                error('TODO: implement this');
            elseif isa(train,'SimilarityDataSet')
                trainIndex = obj.configs('trainSetIndex');
                testIndex = obj.configs('testSetIndex');
                
                train1 = [train.X{trainIndex} ; validate.X{trainIndex}];
                trainY = [train.getSubW(trainIndex,testIndex) ; ...
                    validate.getSubW(trainIndex,testIndex)];
                yFreq = sum(trainY);
                [vals,mostCommonY] = sort(yFreq);
                numTrain = size(train1,1);                                
                testResults.trainPredicted = zeros(numTrain,k);
                
                test1 = test.X{trainIndex};
                testY = test.getSubW(trainIndex,testIndex);
                numTest = size(test1,1);
                testResults.testPredicted = zeros(numTest,1);
                
                for i=1:k
                    testResults.trainPredicted(:,i) = mostCommonY(i);
                    testResults.testPredicted(:,i) = mostCommonY(i);
                end
            else
                error('Unknown Data Set type');
            end
                        
            assert(~isempty(testResults.testPredicted));
            assert(~isempty(testResults.trainPredicted));
            testResults.testActual = testY;                        
            testResults.testPredicted = Helpers.getMode(testResults.testPredicted);
            testResults.trainActual = trainY;
            testResults.trainPredicted = Helpers.getMode(testResults.trainPredicted);
            if size(testResults.testActual,2) == 1
                val = sum(testResults.testActual == testResults.testPredicted)/...
                    length(testResults.testActual);
                display(['NN Acc: ' num2str(val)]);
            end            
            metadata = struct();
            testResults.metadata = struct();
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'Guess';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

