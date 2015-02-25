classdef LogisticRegressionMethod < Method
    %LOGISTICREGRESSIONMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        function obj = LogisticRegressionMethod(configs)
            obj = obj@Method(configs);
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            testResults = FoldResults();
            trainData = input.train;
            test = input.test;            
            XLabeled = trainData.X(trainData.isLabeled(),:);
            shouldUseFeature = true(size(XLabeled,2),1);
            for i=1:size(XLabeled,2)
                if length(unique(XLabeled(:,i))) == 1
                    shouldUseFeature(i) = false;
                end
            end
            
            %Hyperparameter is multiplied with the loss term
            C = 10.^(-5:5);
            
            XLabeled = XLabeled(:,shouldUseFeature);
            %XLabeled = zscore(XLabeled);
            YLabeled = trainData.Y(trainData.isLabeled(),:);
            %B = mnrfit(XLabeled,YLabeled);                       
            
            accs = zeros(size(C));
            for cIdx=1:length(C)
                options = ['-s 0 -c ' num2str(C(cIdx)) ' -B 1 -v 5 -q'];
                accs(cIdx) = train(YLabeled,sparse(XLabeled),options);
            end
            bestC = argmax(accs);
            bestCVAcc = accs(bestC) / 100;          
            testResults.learnerMetadata.cvAcc = bestCVAcc;
            if sum(trainData.isSource()) > 0
                labeledTargetInds = find(trainData.isLabeledTarget());
                cvAcc = 0;
                for idx=labeledTargetInds'
                    currToUse = trainData.isLabeled();
                    currToUse(idx) = 0;
                    options = ['-s 0 -c ' num2str(bestC) ' -B 1 -q'];
                    Xcurr = trainData.X(currToUse,shouldUseFeature);
                    Ycurr = trainData.Y(currToUse);
                    m = train(Ycurr,sparse(Xcurr),options);
                    [~,t,~] = predict(trainData.Y(idx), ...
                            sparse(trainData.X(idx,shouldUseFeature)),...
                            m, '-q');
                    cvAcc = cvAcc + t(1)/(100*length(labeledTargetInds));
                end
                testResults.learnerMetadata.cvAcc = cvAcc;
            end
            if ~isempty(test)
                testResults.dataType = [trainData.type ; test.type];
                options = ['-s 0 -c ' num2str(bestC) ' -B 1 -q'];
                model = train(YLabeled,sparse(XLabeled),options);

                %Xall = [train.X ; test.X];
                %Xall = Xall(:,shouldUseFeature);
                Xtrain = sparse(trainData.X(:,shouldUseFeature));            
                %Xall = zscore(Xall);

                %vals = mnrval(B,Xall);
                [predTrain,~,trainFU] = predict(trainData.trueY, Xtrain, model, '-q -b 1');

                Xtest = sparse(test.X(:,shouldUseFeature));
                [predTest,acc,testFU] = predict(test.Y, Xtest, model, '-q -b 1');
                acc(1) = acc(1) / 100;
                testResults.yPred = [predTrain;predTest];
                testResults.yActual = [trainData.Y ; test.Y];
                testResults.dataFU = [trainFU ; testFU];
                display(['LogReg Acc: ' num2str(acc(1))]);        
            end
        end 
        
        function [prefix] = getPrefix(obj)
            prefix = 'LogReg';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

