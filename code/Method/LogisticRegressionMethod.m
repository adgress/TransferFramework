classdef LogisticRegressionMethod < Method
    %LOGISTICREGRESSIONMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        function obj = LogisticRegressionMethod(configs)
            obj = obj@Method(configs);
            if ~obj.has('fixReg')
                obj.set('fixReg',0);
            end
            if ~obj.has('useVal')
                obj.set('useVal',0);
            end
            if ~obj.has('justInitialVal')
                obj.set('justInitialVal',0);
            end            
            if ~obj.has('trainAllReg')
                obj.set('trainAllReg',1);
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
            t = find(shouldUseFeature);
            if ProjectConfigs.logRegNumFeatures < length(t)                
                t(ProjectConfigs.logRegNumFeatures+1:end) = [];
            end
            shouldUseFeature(:) = 0;
            shouldUseFeature(t) = 1;
            %Hyperparameter is multiplied with the loss term
            C = 10.^(-5:5);
            if obj.get('fixReg')
                C = 1e3;
            end
            XLabeled = XLabeled(:,shouldUseFeature);
            validationWeights = [];
            if isfield(input,'validationWeights')
                validationWeights = input.validationWeights(shouldUse);
            end
            YLabeled = trainData.Y(shouldUse,:);                  
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
                evalc('accs(cIdx) = train(instanceWeights,YLabeledCurr,sparse(XLabeledCurr),options)');                
            end
            bestCInd = argmax(accs);
            bestC = C(bestCInd);
            bestCVAcc = accs(bestCInd) / 100;          
            useInitialVal = obj.get('justInitialVal');
            %useInitialVal = obj.get('useInitialVal');
            if sum(trainData.isSource()) > 0 || useValidationSet || useInitialVal ...
                    || ~isempty(validationWeights)
                bestC = [];
                bestCInd = [];
                bestCVAcc = [];
                accs = zeros(size(C));
                labeledTargetInds = find(trainData.isLabeledTarget());
                cvAcc = 0;
                folds = 10;
                if length(labeledTargetInds) < folds
                    folds = length(labeledTargetInds);
                end
                if useValidationSet
                    folds = 1;
                end
                weightSums = zeros(size(C));
                for cIdx=1:length(C)
                    for foldIdx=1:folds
                        if useValidationSet
                            isTest = trainData.isValidation(labeledTargetInds);
                        elseif useInitialVal                       
                            isOriginalTarget = ~trainData.isValidation(labeledTargetInds);
                            originalTargetInds = labeledTargetInds(isOriginalTarget);
                            isTest = DataSet.generateSplit([.8 .2 0],...
                                    trainData.Y(originalTargetInds)) == 2;

                            I = false(size(labeledTargetInds));
                            I(isOriginalTarget) = isTest;
                            isTest = I;
                        else
                            if length(labeledTargetInds) <= folds
                                isTest = foldIdx;
                            else
                                isTest = DataSet.generateSplit([.8 .2 0],...
                                    trainData.Y(labeledTargetInds)) == 2;
                            end
                        end          
                        testInds = labeledTargetInds(isTest);
                        options = ['-s ' num2str(liblinearMethod) ' -c ' num2str(C(cIdx)) ' -B 1 -q'];
                        currToUse = trainData.isLabeled();
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
                        m = train(instanceWeights,Ycurr,sparse(Xcurr),options);
                        Ytest = trainData.Y(testInds);
                        Xtest = trainData.X(testInds,shouldUseFeature);
                        Xtest = t.apply(Xtest);
                        [predLabels,t,~] = predict(Ytest, sparse(Xtest), m, '-q');
                        if isempty(validationWeights)
                            accs(cIdx) = accs(cIdx) + t(1)/folds;
                        else
                            assert(mean(predLabels == Ytest)*100 == t(1));
                            accVec = (predLabels == Ytest) ./ validationWeights(isTest);
                            accs(cIdx) = accs(cIdx) + sum(accVec);
                            weightSums(cIdx) = weightSums(cIdx) + sum(1 ./ validationWeights(isTest));
                        end
                        
                    end
                end
                if ~isempty(validationWeights)
                    accs = accs ./ weightSums;
                    accs = accs * 100;
                end
                bestCInd = argmax(accs);
                bestC = C(bestCInd);
                bestCVAcc = accs(bestCInd) / 100;                     
            end
            testResults.learnerMetadata.cvAcc = bestCVAcc;
            testResults.learnerMetadata.reg = bestC;
            instanceWeights = ones(size(YLabeled));            
            if ~isempty(test)
                testResults.dataType = [trainData.type ; test.type];                
                testResults.yActual = [trainData.trueY ; test.trueY];
                testResults.yTrain = [trainData.Y ; -ones(size(test.Y))];
                testResults.isValidation = [trainData.isValidation; test.isValidation];
                
                t = NormalizeTransform();
                t.learn(XLabeled,YLabeled);
                XLabeled = t.apply(XLabeled,YLabeled);
                
                if ProjectConfigs.resampleTarget
                    numSource = sum(labeledType == Constants.SOURCE);
                    numTarget = sum(labeledType == Constants.TARGET_TRAIN);
                    instanceWeights(labeledType == Constants.SOURCE) = 1/numSource;
                    instanceWeights(labeledType == Constants.TARGET_TRAIN) = 1/numTarget;
                end
                
                if ~obj.get('trainAllReg')
                    C = bestC;
                end
                Xtrain = sparse(trainData.X(:,shouldUseFeature));            
                Xtrain = t.apply(Xtrain);
                Xtest = sparse(test.X(:,shouldUseFeature));
                    Xtest = t.apply(Xtest);
                for cIdx=1:length(C)
                    currC = C(cIdx);
                    options = ['-s ' num2str(liblinearMethod) ' -c ' num2str(currC) ' -B 1 -q'];
                    model = train(instanceWeights,YLabeled,sparse(XLabeled),options);                    
                    [predTrain,~,trainFU] = predict(trainData.trueY, sparse(Xtrain), model, '-q -b 1');
                    
                    [predTest,acc,testFU] = predict(test.Y, sparse(Xtest), model, '-q -b 1');                                        
                    testResults.modelResults(cIdx).yPred = [predTrain;predTest];                    
                    testResults.modelResults(cIdx).dataFU = [trainFU ; testFU];
                    testResults.modelResults(cIdx).cvAcc = accs(cIdx);
                    acc(1) = acc(1) / 100;
                    testResults.modelResults(cIdx).testAcc = acc(1);
                    testResults.modelResults(cIdx).reg = currC;
                    if currC == bestC
                        testResults.yPred = ...
                            testResults.modelResults(cIdx).yPred;
                        testResults.dataFU = ...
                            testResults.modelResults(cIdx).dataFU;                        
                        
                        display(['LogReg Acc: ' num2str(acc(1))]);  
                    end
                end
            end
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
            if obj.has('justInitialVal') && obj.get('justInitialVal')
                nameParams{end+1} = 'justInitialVal';
            end
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

