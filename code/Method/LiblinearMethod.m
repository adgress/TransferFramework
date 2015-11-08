classdef LiblinearMethod < Method
    %LIBLINEARMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        model
        liblinearMethod
    end
    
    methods
        function obj = LiblinearMethod(configs)
            obj = obj@Method(configs);
            %pc = ProjectConfigs.Create();
            obj.liblinearMethod = 0;
        end
        
        function [testResults,savedData] = runMethod(obj,input,savedData)
            train = input.train;
            test = input.test;
            if isempty(test)
                test = DataSet();
                test.X = zeros(0,size(train.X,2));
            end
            obj.train(train.X,train.Y);
            
            [y,fu] = obj.predict([train.X ; test.X]);
            
            testResults = FoldResults(); 
            isLabeledTrain = train.isLabeled();
            toKeep = [train.isLabeled() ; true(size(test.X,1),1)];
            testResults.dataType = [train.type(isLabeledTrain) ; test.type];
            testResults.yActual = [train.trueY(isLabeledTrain) ; test.trueY];
            testResults.yPred = y(toKeep);
            testResults.dataFU = fu(toKeep,:);
        end
        
        function [y,fu] = getLOOestimates(obj,X,Y)
            reg = obj.get('reg');    
            options = ['-s ' num2str(obj.liblinearMethod) ' -c ' num2str(reg) ' -B 1 -q'];                        
            y = zeros(size(Y));
            X = sparse(X);
            probEst = zeros(length(Y),length(unique(Y)));
            for idx=1:length(Y)
                Xi = X;
                Xi(idx,:) = [];
                Yi = Y;
                Yi(idx) = [];
                m = train(ones(size(Y)),Y,sparse(X),options);
                [y(idx),t,probEst(idx,:)] = predict(Y(idx), X(idx,:), m, '-q -b 1');
            end
            fu = Helpers.expandMatrix(probEst,obj.model.Label);
        end
        
        function [] = train(obj,X,Y)            
            I = ~isnan(Y);
            X = X(I,:);
            Y = Y(I);
            reg = obj.get('reg');    
            options = ['-s ' num2str(obj.liblinearMethod) ' -c ' num2str(reg) ' -B 1 -q'];
            %options = ['-s ' num2str(obj.liblinearMethod) ' -c ' num2str(reg) ' -B 1'];
            obj.model = train(ones(size(Y)),Y,sparse(X),options);
        end
        
        function [y,fu] = predict(obj,X)
            [y,t,probEst] = predict(ones(size(X,1),1), sparse(X), obj.model, '-q -b 1');
            fu = Helpers.expandMatrix(probEst,obj.model.Label);            
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            %C = obj.get('cvReg');       
            C = 10.^(-5:10);
            trainData = input.train;
            I = trainData.isLabeled();
            XL = trainData.X(I,:);
            YL = trainData.Y(I,:);
            accs = zeros(size(C));
            for cIdx=1:length(C)
                options = ['-s ' num2str(obj.liblinearMethod) ' -c ' num2str(C(cIdx)) ' -B 1 -v 10 -q'];
                evalc('accs(cIdx) = train(ones(size(YL)),YL,sparse(XL),options)');                
            end
            [~,bestInd] = max(accs);
            obj.set('reg',C(bestInd));
            [testResults] = obj.runMethod(input);
        end
        function [prefix] = getPrefix(obj)
            prefix = 'Liblinear';           
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
    end
    
end

