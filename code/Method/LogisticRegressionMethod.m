classdef LogisticRegressionMethod < Method
    %LOGISTICREGRESSIONMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        function obj = LogisticRegressionMethod(configs)
            obj = obj@Method(configs);
            if ~obj.has('fixReg')
                obj.set('fixReg',1);
            end
            if ~obj.has('useVal')
                obj.set('useVal',1);
            end
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            %error('TODO: Try resampling training data');
            testResults = FoldResults();
            trainData = input.train;
            test = input.test;   
            
            useValidationSet = obj.get('useVal') && any(trainData.isValidation);
            shouldUse = trainData.isLabeled();
            if useValidationSet
                shouldUse = shouldUse & ~trainData.isValidation;
            end
            XLabeled = trainData.X(shouldUse,:);
            shouldUseFeature = true(size(XLabeled,2),1);
            for i=1:size(XLabeled,2)
                if length(unique(XLabeled(:,i))) <= 2
                    shouldUseFeature(i) = false;
                end
            end
            %display(num2str(sum(shouldUseFeature)));
            t = find(shouldUseFeature);
            if ProjectConfigs.logRegNumFeatures < length(t)                
                t(ProjectConfigs.logRegNumFeatures+1:end) = [];
            end
            shouldUseFeature(:) = 0;
            shouldUseFeature(t) = 1;
            %Hyperparameter is multiplied with the loss term
            C = 10.^(-5:5);
            if obj.get('fixReg')
                C = 1e-3;
            end
            %C = 10^3;
            XLabeled = XLabeled(:,shouldUseFeature);
            
            %XLabeled = zscore(XLabeled);
            YLabeled = trainData.Y(shouldUse,:);
            %B = mnrfit(XLabeled,YLabeled);                       
            labeledType = trainData.type(shouldUse);
            
            accs = zeros(size(C));
            XLabeledCurr = XLabeled;
            YLabeledCurr = YLabeled;
            
            liblinearMethod = 0;
            if ProjectConfigs.useL1LogReg
                liblinearMethod = 6;
            end
            instanceWeights = ones(size(YLabeledCurr));
            if ProjectConfigs.resampleTarget
                numSource = sum(labeledType == Constants.SOURCE);
                numTarget = sum(labeledType == Constants.TARGET_TRAIN);
                instanceWeights(labeledType == Constants.SOURCE) = 1/numSource;
                instanceWeights(labeledType == Constants.TARGET_TRAIN) = 1/numTarget;
            end
            for cIdx=1:length(C)
                options = ['-s ' num2str(liblinearMethod) ' -c ' num2str(C(cIdx)) ' -B 1 -v 10 -q'];                
                %evalc('accs(cIdx) = train(YLabeledCurr,XLabeledCurr,options)');
                evalc('accs(cIdx) = train(instanceWeights,YLabeledCurr,sparse(XLabeledCurr),options)');                
            end
            bestCInd = argmax(accs);
            bestC = C(bestCInd);
            bestCVAcc = accs(bestCInd) / 100;          
            testResults.learnerMetadata.cvAcc = bestCVAcc;            
            if sum(trainData.isSource()) > 0 || useValidationSet
                labeledTargetInds = find(trainData.isLabeledTarget());
                cvAcc = 0;
                folds = 10;
                if length(labeledTargetInds) < folds
                    folds = length(labeledTargetInds);
                end
                %for ind=1:length(labeledTargetInds)
                if useValidationSet
                    folds = 1;
                end
                for foldIdx=1:folds
                    if useValidationSet
                        isTest = trainData.isValidation(labeledTargetInds);
                    else
                        if length(labeledTargetInds) <= folds
                            isTest = foldIdx;
                        else
                            isTest = DataSet.generateSplit([.8 .2 0],...
                                trainData.Y(labeledTargetInds)) == 2;
                        end
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
                    instanceWeights = ones(size(Ycurr));
                    if ProjectConfigs.resampleTarget
                        numSource = sum(type == Constants.SOURCE);
                        numTarget = sum(type == Constants.TARGET_TRAIN);
                        instanceWeights(type == Constants.SOURCE) = 1/numSource;
                        instanceWeights(type == Constants.TARGET_TRAIN) = 1/numTarget;
                    end
                    %m = train(Ycurr,sparse(Xcurr),options);
                    m = train(instanceWeights,Ycurr,sparse(Xcurr),options);
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
            instanceWeights = ones(size(YLabeled));            
            if ~isempty(test)
                testResults.dataType = [trainData.type ; test.type];
                options = ['-s ' num2str(liblinearMethod) ' -c ' num2str(bestC) ' -B 1 -q'];
                
                t = NormalizeTransform();
                t.learn(XLabeled,YLabeled);
                XLabeled = t.apply(XLabeled,YLabeled);
                
                if ProjectConfigs.resampleTarget
                    %I = LabeledData.ResampleTargetTrainData(labeledType);
                    %XLabeled = XLabeled(I,:);
                    %YLabeled = YLabeled(I);
                    numSource = sum(labeledType == Constants.SOURCE);
                    numTarget = sum(labeledType == Constants.TARGET_TRAIN);
                    instanceWeights(labeledType == Constants.SOURCE) = 1/numSource;
                    instanceWeights(labeledType == Constants.TARGET_TRAIN) = 1/numTarget;
                end
                
                %model = train(YLabeled,sparse(XLabeled),options);
                model = train(instanceWeights,YLabeled,sparse(XLabeled),options);
                Xtrain = sparse(trainData.X(:,shouldUseFeature));            
                Xtrain = t.apply(Xtrain);
                [predTrain,~,trainFU] = predict(trainData.trueY, sparse(Xtrain), model, '-q -b 1');
                Xtest = sparse(test.X(:,shouldUseFeature));
                Xtest = t.apply(Xtest);
                [predTest,acc,testFU] = predict(test.Y, sparse(Xtest), model, '-q -b 1');
                acc(1) = acc(1) / 100;
                testResults.yPred = [predTrain;predTest];
                testResults.yActual = [trainData.trueY ; test.trueY];
                testResults.dataFU = [trainFU ; testFU];
                testResults.yTrain = [trainData.Y ; -ones(size(test.Y))];
                testResults.isValidation = [trainData.isValidation; test.isValidation];
                display(['LogReg Acc: ' num2str(acc(1))]);  
                %mean(testResults.yPred==testResults.yActual)
            end
            %{
            if length(find(shouldUse)) < 20
                display(find(shouldUse)');
                shouldUse;
            end
            %}
        end 
        
        function [prefix] = getPrefix(obj)
            prefix = 'LogReg';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
            if obj.has('fixReg') && obj.get('fixReg')
                nameParams{end+1} = 'fixReg';
            end
            if obj.has('useVal') && obj.get('useVal')
                nameParams{end+1} = 'useVal';
            end
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

