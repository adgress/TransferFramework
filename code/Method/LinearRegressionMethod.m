classdef LinearRegressionMethod < Method
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LinearRegressionMethod(configs)
            obj = obj@Method(configs);
        end
        
        function [testResults,savedData] = runMethod(obj,input,savedData)
            train = input.train;
            test = input.test;
            assert(all(test.isLabeled));
            trainX = train.X(train.isLabeled,:);
            trainY = train.Y(train.isLabeled,:);;
            testX = test.X;
            testY = test.Y;
            normalizeTransform = NormalizeTransform();
            normalizeTransform.learn(trainX);
            trainX = normalizeTransform.apply(trainX);
            testX = normalizeTransform.apply(testX);
            
            warning off;
            w = ridge(trainY,trainX,0,0);
            warning on;
            
            trainXBias = [ones(size(trainX,1),1) trainX];
            testXBias = [ones(size(testX,1),1) testX];
            
            Ytr = trainXBias*w;
            Yte = testXBias*w;
            testResults.dataType = [train.type(train.isLabeled) ; test.type];
            testResults.yPred= [Ytr ; Yte];
            testResults.yActual = [trainY ; testY];
            
            a = obj.configs.get('measure').evaluate(testResults);
            savedData.val = a.learnerStats.valTest;
            assert(~isnan(savedData.val));
            assert(~isinf(savedData.val) && ~isnan(savedData.val));
        end
        function [testResults,metadata] = ...
            trainAndTest(obj,input,savedData)                                                
            cv = CrossValidation();
            cv.trainData = input.train.copy();
            cv.parameters = obj.get('cvParameters');
            cv.methodObj = obj;
            cv.measure = obj.get('measure');
            tic
            [bestParams,acc] = cv.runCV();
            toc
            obj.setParams(bestParams);
            [testResults,savedData] = obj.runMethod(input);
            if ~obj.configs.get('quiet')
                display([ obj.getPrefix() ' Acc: ' num2str(savedData.val)]);
            end
        end            
        
        function [s] = getPrefix(obj)
            s = 'LinReg';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end 
    end   
end




