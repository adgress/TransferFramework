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
            %error('TODO: Try resampling training data');
            testResults = FoldResults();
            trainData = input.train;
            test = input.test;            
            XLabeled = trainData.X(trainData.isLabeled(),:);
            shouldUseFeature = true(size(XLabeled,2),1);
            for i=1:size(XLabeled,2)
                if length(unique(XLabeled(:,i))) <= 2
                    shouldUseFeature(i) = false;
                end
            end 
            t = find(shouldUseFeature);
            if ProjectConfigs.logRegNumFeatures < length(t)                
                t(ProjectConfigs.logRegNumFeatures+1:end) = [];
            end
            shouldUseFeature(:) = 0;
            shouldUseFeature(t) = 1;
            %Hyperparameter is multiplied with the loss term
            C = 10.^(-5:5);
            XLabeled = XLabeled(:,shouldUseFeature);
            %XLabeled = zscore(XLabeled);
            YLabeled = trainData.Y(trainData.isLabeled(),:);
            %B = mnrfit(XLabeled,YLabeled);                       
            labeledType = trainData.type(trainData.isLabeled());
            
            accs = zeros(size(C));
            XLabeledCurr = XLabeled;
            t = NormalizeTransform();
            t.learn(XLabeledCurr);
            XLabeledCurr = sparse(t.apply(XLabeledCurr));
            YLabeledCurr = YLabeled;
            
            liblinearMethod = 0;
            if ProjectConfigs.useL1LogReg
                liblinearMethod = 6;
            end
            if ProjectConfigs.resampleTarget
                I = LabeledData.ResampleTargetTrainData(labeledType);
                XLabeledCurr = XLabeledCurr(I,:);
                YLabeledCurr = YLabeledCurr(I);
            end
            for cIdx=1:length(C)
                options = ['-s ' num2str(liblinearMethod) ' -c ' num2str(C(cIdx)) ' -B 1 -v 5 -q'];                
                evalc('accs(cIdx) = train(YLabeledCurr,XLabeledCurr,options)');
                %accs(cIdx) = train(YLabeled,XLabeledCurr,options);
            end
            bestCInd = argmax(accs);
            bestC = C(bestCInd);
            bestCVAcc = accs(bestCInd) / 100;          
            testResults.learnerMetadata.cvAcc = bestCVAcc;
            if sum(trainData.isSource()) > 0
                labeledTargetInds = find(trainData.isLabeledTarget());
                cvAcc = 0;
                folds = 10;
                if length(labeledTargetInds) < folds
                    folds = length(labeledTargetInds);
                end
                %for ind=1:length(labeledTargetInds)
                for foldIdx=1:folds
                    if length(labeledTargetInds) <= folds
                        isTest = foldIdx;
                    else
                        isTest = DataSet.generateSplit([.8 .2 0],...
                            trainData.Y(labeledTargetInds)) == 2;
                    end
                    %idx = labeledTargetInds(ind);                    
                    testInds = labeledTargetInds(isTest);
                    options = ['-s ' num2str(liblinearMethod) ' -c ' num2str(bestC) ' -B 1 -q'];
                    %options = ['-s 0 -c ' num2str(bestC) ' -B 1'];
                    currToUse = trainData.isLabeled();
                    %currToUse(idx) = 0;
                    currToUse(testInds) = false;
                    Xcurr = trainData.X(currToUse,shouldUseFeature);
                    Ycurr = trainData.Y(currToUse);
                    type = trainData.type(currToUse);
                    
                    t = NormalizeTransform();
                    t.learn(Xcurr);                    
                    Xcurr = t.apply(Xcurr,Ycurr);
                    
                    if ProjectConfigs.resampleTarget
                        I = LabeledData.ResampleTargetTrainData(type);
                        Xcurr = Xcurr(I,:);
                        Ycurr = Ycurr(I);
                    end
                    m = train(Ycurr,sparse(Xcurr),options);
                    Ytest = trainData.Y(testInds);
                    Xtest = trainData.X(testInds,shouldUseFeature);
                    Xtest = t.apply(Xtest);
                    [~,t,~] = predict(Ytest, sparse(Xtest), m, '-q');
                    %{
                    % Find L2-regularized logistic
                    nVars = size(Xcurr,2);
                    X = [ones(size(Xcurr,1),1) Xcurr];
                    Y = Ycurr;
                    Y(Y == 2) = -1;
                    funObj = @(w)LogisticLoss(w,X,Y);
                    lambda = 1*ones(nVars+1,1);
                    lambda(1) = 0; % Don't penalize bias
                    minFuncOptions = struct();
                    minFuncOptions.Display = 0;
                    fprintf('Training L2-regularized logistic regression model...\n');
                    wL2 = minFunc(@penalizedL2,zeros(nVars+1,1),minFuncOptions,funObj,lambda);
                    %}
                    cvAcc = cvAcc + t(1)/(100*folds);
                end
                testResults.learnerMetadata.cvAcc = cvAcc;
            end
            if ~isempty(test)
                testResults.dataType = [trainData.type ; test.type];
                options = ['-s ' num2str(liblinearMethod) ' -c ' num2str(bestC) ' -B 1 -q'];
                
                t = NormalizeTransform();
                t.learn(XLabeled,YLabeled);
                XLabeled = t.apply(XLabeled,YLabeled);
                
                if ProjectConfigs.resampleTarget
                    I = LabeledData.ResampleTargetTrainData(labeledType);
                    XLabeled = XLabeled(I,:);
                    YLabeled = YLabeled(I);
                end
                
                model = train(YLabeled,sparse(XLabeled),options);
                Xtrain = sparse(trainData.X(:,shouldUseFeature));            
                Xtrain = t.apply(Xtrain);
                [predTrain,~,trainFU] = predict(trainData.trueY, sparse(Xtrain), model, '-q -b 1');
                Xtest = sparse(test.X(:,shouldUseFeature));
                Xtest = t.apply(Xtest);
                [predTest,acc,testFU] = predict(test.Y, sparse(Xtest), model, '-q -b 1');
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

