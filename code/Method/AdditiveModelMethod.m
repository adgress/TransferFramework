classdef AdditiveModelMethod < Method
    %ADDITIVEMODELMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        allMethods
        alpha
    end
    
    methods
        function obj = AdditiveModelMethod(configs)
            obj = obj@Method(configs);
        end
        function [y] = predict(obj,X)
            y = obj.alpha*ones(size(X,1),1);
            for j=1:size(X,2)
                y = y + obj.allMethods{j}.predict(X(:,j));
            end
        end
        function [testResults,savedData] = runMethod(obj,input,savedData)
            train = input.train;
            test = input.test;
            assert(all(test.isLabeled));
            trainX = train.X(train.isLabeled,:);
            trainY = train.Y(train.isLabeled,:);
            testX = test.X;
            testY = test.Y;
            
            obj.alpha = mean(trainY);
            
            obj.allMethods = {};
            for idx=1:size(trainX,2)
                m = NWMethod();
                m.set('measure',L2Measure());
                %m.set('cvParameters',obj.get('cvParameters'));                
                obj.allMethods{idx} = m;
            end
            sigmaVals = obj.get('sigmaVals');
            maxIters = 5;
            for i=1:maxIters            
                for idx=1:size(trainX,2)
                    currPred = obj.alpha*ones(size(trainX,1),1);
                    for j=1:size(trainX,2)
                        if j == idx
                            continue;
                        end
                        currPred = currPred + obj.allMethods{j}.predict(trainX(:,j));
                    end
                    res = trainY - currPred;
                    obj.allMethods{idx}.set('sigma',sigmaVals);
                    obj.allMethods{idx}.train(trainX(:,idx),res);
                    yPred = obj.allMethods{idx}.predict(trainX(:,idx));
                    m = mean(yPred);
                    %What about step (b)?  Best way to incorporate it?
                end
                y = obj.predict(trainX);
                if norm(y-trainY)/norm(y) < 1e-6
                    display('Converged - stopping');
                    break;
                end
            end
            
            testResults.dataType = [train.type(train.isLabeled) ; test.type];
            testResults.yPred = [obj.predict(trainX) ; obj.predict(testX)];
            testResults.yActual = [trainY ; testY];
            assert(all(~isnan(testResults.yActual)));
            assert(all(~isnan(testResults.yPred)));
            
            a = obj.configs.get('measure').evaluate(testResults);
            savedData.val = a.learnerStats.valTest;
            assert(~isnan(savedData.val));
            assert(~isinf(savedData.val) && ~isnan(savedData.val));
        end
        function [testResults,metadata] = ...
            trainAndTest(obj,input,savedData)       
            %{
            cv = CrossValidation();
            cv.trainData = input.train.copy();
            cv.parameters = obj.get('cvParameters');
            cv.methodObj = obj;
            cv.measure = obj.get('measure');
            tic
            [bestParams,acc] = cv.runCV();
            toc
            obj.setParams(bestParams);
            %}
            [testResults,savedData] = obj.runMethod(input);
            if ~obj.configs.get('quiet')
                display([ obj.getPrefix() ' Acc: ' num2str(savedData.val)]);
            end
        end            
        
        function [s] = getPrefix(obj)
            s = 'AddMod';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = getNameParams@Method(obj);
        end 
    end
    
end

