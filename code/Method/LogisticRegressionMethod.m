classdef LogisticRegressionMethod < Method
    %LOGISTICREGRESSIONMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        
        function obj = LogisticRegressionMethod(configs)
            obj = obj@Method(configs);
            if ~obj.has('fixReg')
                obj.set('fixReg',ProjectConfigs.fixReg);
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
            if ~obj.has('cvWeight')
                obj.set('cvWeight',0);
            end
            if ~obj.has('LOOCV')
                obj.set('LOOCV',0);
            end
            if ~obj.has('svm')
                obj.set('svm',ProjectConfigs.useSVM);
            end
            if ~obj.has('NB')
                obj.set('NB',ProjectConfigs.useNB);
            end
            assert(~(obj.get('svm') && obj.get('NB')));
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            %error('TODO: Try resampling training data');
            testResults = FoldResults();
            trainData = input.train;
            test = input.test;   
            trainX = trainData.X;
            testX = test.X;
            if ProjectConfigs.data == Constants.NG_DATA && ProjectConfigs.useNB
                trainX = double(trainData.X > 0);
                testX = double(test.X > 0);
            end
            useValidationSet = obj.get('useVal') && any(trainData.isValidation);
            shouldUse = trainData.isLabeled();
            if useValidationSet
                shouldUse = shouldUse & ~trainData.isValidation;
            end            
            XLabeled = trainX(shouldUse,:);
            shouldUseFeature = true(size(XLabeled,2),1);
            for i=1:size(XLabeled,2)
                if length(unique(XLabeled(:,i))) <= 1
                    shouldUseFeature(i) = false;
                end
            end
            t = find(shouldUseFeature);
            if ProjectConfigs.logRegNumFeatures < length(t)                
                t(ProjectConfigs.logRegNumFeatures+1:end) = [];
            end
            shouldUseFeature(:) = 0;
            shouldUseFeature(t) = 1;
            
            XLabeled = XLabeled(:,shouldUseFeature);
            validationWeights = [];
            if isfield(input,'validationWeights')
                validationWeights = input.validationWeights(shouldUse);
            end
            YLabeled = trainData.Y(shouldUse,:);                  
            labeledType = trainData.type(shouldUse);
                        
            
            XLabeledCurr = XLabeled;
            YLabeledCurr = YLabeled;
            
            liblinearMethod = 0;
            if ProjectConfigs.useL1LogReg
                liblinearMethod = 6;
            end
            useLogReg = true;
            useNB = false;
            useLibLinear = true;
            if obj.get('svm')
                %liblinearMethod = 3;
                liblinearMethod = 3;
                useLogReg = false;
            end
            if obj.get('NB')
                useLogReg = false;
                useLibLinear = false;
                useNB = true;
            end
            
            %Liblinear Hyperparameter is multiplied with the loss term
            C = 10.^(-5:5);
            if obj.get('fixReg')
                C = 1e3;
            end
            if useNB
                C = -1;
                %remove features with zero in class variance
            end
            accs = zeros(size(C));
            NBOptions = {};
            transform = NormalizeTransform();
            if ProjectConfigs.data == Constants.NG_DATA
                transform = TransformBase();
                %NBOptions = {'Distribution','mvmn'};            
            end
            %transform = TransformBase();
            instanceWeights = ones(size(YLabeledCurr));
            if ProjectConfigs.resampleTarget
                numSource = sum(labeledType == Constants.SOURCE);
                numTarget = sum(labeledType == Constants.TARGET_TRAIN);
                instanceWeights(labeledType == Constants.SOURCE) = 1/numSource;
                instanceWeights(labeledType == Constants.TARGET_TRAIN) = 1/numTarget;
            end
            useInitialVal = obj.get('justInitialVal');
            useManualCV = sum(trainData.isSource()) > 0 || useValidationSet || useInitialVal ...
                    || ~isempty(validationWeights) || ~useLibLinear;
            if ~useManualCV
                for cIdx=1:length(C)
                    options = ['-s ' num2str(liblinearMethod) ' -c ' num2str(C(cIdx)) ' -B 1 -v 10 -q'];                
                    evalc('accs(cIdx) = train(instanceWeights,YLabeledCurr,sparse(XLabeledCurr),options)');                
                end
                bestCInd = argmax(accs);
                bestC = C(bestCInd);
                bestCVAcc = accs(bestCInd) / 100;
            elseif useManualCV
                bestC = [];
                bestCInd = [];
                bestCVAcc = [];
                accs = zeros(size(C));
                labeledTargetInds = find(trainData.isLabeledTarget());
                cvAcc = 0;
                folds = 10;
                if length(labeledTargetInds) < folds || obj.get('LOOCV')
                    folds = length(labeledTargetInds);
                end
                if useValidationSet
                    folds = 1;
                end
                weightSums = zeros(size(C));
                weightSums2 = zeros(size(C));
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
                        currToUse = trainData.isLabeled();
                        currToUse(testInds) = false;
                        Xcurr = trainX(currToUse,shouldUseFeature);
                        Ycurr = trainData.Y(currToUse);
                        type = trainData.type(currToUse);

                        transform.learn(Xcurr);                    
                        Xcurr = transform.apply(Xcurr,Ycurr);
                        instanceWeights = ones(size(Ycurr));
                        if ProjectConfigs.resampleTarget                                                        
                            numSource = sum(type == Constants.SOURCE);
                            numTarget = sum(type == Constants.TARGET_TRAIN);                            
                            if numSource > 0
                                display('Resampling target');
                                instanceWeights(type == Constants.SOURCE) = 1/numSource;
                                instanceWeights(type == Constants.TARGET_TRAIN) = 1/numTarget;                            
                                assert(useLibLinear);
                            end
                        end
                        Ytest = trainData.Y(testInds);
                        Xtest = trainX(testInds,shouldUseFeature);
                        Xtest = transform.apply(Xtest);
                        if useLibLinear
                            options = ['-s ' num2str(liblinearMethod) ' -c ' num2str(C(cIdx)) ' -B 1 -q'];
                            m = train(instanceWeights,Ycurr,sparse(Xcurr),options);                        
                            [predLabels,t,~] = predict(Ytest, sparse(Xtest), m, '-q');
                        elseif useNB
                            featsToUse = Helpers.hasZeroInClassVariance(Xcurr,Ycurr);
                            m = NaiveBayes.fit(full(Xcurr(:,~featsToUse)),Ycurr,NBOptions{:});
                            predLabels = m.predict(Xtest(:,~featsToUse));
                            t = 100*mean(predLabels == Ytest);
                        end
                        if isempty(validationWeights)
                            accs(cIdx) = accs(cIdx) + t(1)/folds;
                        else
                            vWeights = 1 ./ validationWeights(isTest);
                            %{
                            if obj.get('cvWeight') == 1
                                vWeights = validationWeights(isTest);
                                %vWeights = vWeights ./ prod(vWeights);
                                vWeights = ones(size(vWeights)) ./ prod(vWeights);
                                vWeights = vWeights / length(vWeights);
                            end
                            %}
                            assert(mean(predLabels == Ytest)*100 == t(1));
                            accVec = (predLabels == Ytest) .* vWeights;
                            accs(cIdx) = accs(cIdx) + sum(accVec);
                            weightSums2(cIdx) = weightSums2(cIdx) + sum(vWeights);
                            if obj.get('cvWeight')
                                weightSums(cIdx) = weightSums(cIdx) + length(vWeights);
                            else
                                weightSums(cIdx) = weightSums(cIdx) + sum(vWeights);
                            end
                        end                        
                    end
                end
                if ~isempty(validationWeights)
                    if obj.get('cvWeight')
                        %weightSums = 1./weightSums;
                    end
                    delta = weightSums - weightSums2;
                    accs = accs ./ weightSums;
                    accs = accs * 100;
                end
                bestCInd = argmax(accs);
                bestC = C(bestCInd);
                bestCVAcc = accs(bestCInd) / 100;                     
            end
            display(['CV Acc: ' num2str(bestCVAcc)]);
            if bestCVAcc > 2
                display('CV Acc > 2!!!');
            end
            testResults.learnerMetadata.cvAcc = bestCVAcc;
            testResults.learnerMetadata.reg = bestC;
            instanceWeights = ones(size(YLabeled));            
            if ~isempty(test)
                testResults.dataType = [trainData.type ; test.type];                
                testResults.yActual = [trainData.trueY ; test.trueY];
                testResults.yTrain = [trainData.Y ; -ones(size(test.Y))];
                testResults.isValidation = [trainData.isValidation; test.isValidation];
                                
                transform.learn(XLabeled,YLabeled);
                XLabeled = transform.apply(XLabeled,YLabeled);
                
                if ProjectConfigs.resampleTarget
                    numSource = sum(labeledType == Constants.SOURCE);
                    numTarget = sum(labeledType == Constants.TARGET_TRAIN);
                    instanceWeights(labeledType == Constants.SOURCE) = 1/numSource;
                    instanceWeights(labeledType == Constants.TARGET_TRAIN) = 1/numTarget;
                end
                
                if ~obj.get('trainAllReg')
                    C = bestC;
                end
                Xtrain = sparse(trainX(:,shouldUseFeature));            
                Xtrain = transform.apply(Xtrain);
                Xtest = sparse(testX(:,shouldUseFeature));
                Xtest = transform.apply(Xtest);
                for cIdx=1:length(C)
                    currC = C(cIdx);
                    if useLibLinear
                        options = ['-s ' num2str(liblinearMethod) ' -c ' num2str(currC) ' -B 1 -q'];
                        model = train(instanceWeights,YLabeled,sparse(XLabeled),options);                  
                        predictOptions = '-q -b 1';
                        if ~useLogReg
                            predictOptions = '-q';
                        end
                        [predTrain,~,trainFU] = predict(trainData.trueY, sparse(Xtrain), model, predictOptions);                    
                        [predTest,acc,testFU] = predict(test.Y, sparse(Xtest), model, predictOptions);                                        
                    else
                        featsToUse = Helpers.hasZeroInClassVariance(XLabeled,YLabeled);
                        XLabeled = full(XLabeled);                        
                        m = NaiveBayes.fit(XLabeled(:,~featsToUse),YLabeled,NBOptions{:});
                        [trainFU,predTrain] = m.posterior(Xtrain(:,~featsToUse));
                        [testFU,predTest] = m.posterior(Xtest(:,~featsToUse));
                        acc = 100*mean(predTest == test.Y);
                    end
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
            if obj.get('svm')
                prefix = 'SVML2';
            end
            if obj.get('NB')
                prefix = 'NaiveBayes';
            end
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
            if obj.has('cvWeight') && obj.get('cvWeight')
                nameParams{end+1} = 'cvWeight';
            end
            if obj.has('LOOCV') && obj.get('LOOCV')
                nameParams{end+1} = 'LOOCV';
            end
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end
    
end

