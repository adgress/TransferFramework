classdef SepLLGCMethod < LLGCMethod
    %LLGCMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = SepLLGCMethod(configs)
            obj = obj@LLGCMethod(configs);
            if ~obj.has('uniform')
                obj.set('uniform',false);
            end
            if ~obj.has('regularized')
                obj.set('regularized',true);
            end
            if ~obj.has('sum')
                obj.set('sum',false);
            end
            if ~obj.has('addBias')
                obj.set('addBias',1);
            end
            if ~obj.has('lasso')
                obj.set('lasso',0);
            end
            if ~obj.has('slZ')
                obj.set('slZ',1);
            end
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            useHF = false;
            makeRBF = true;
            train = input.train;
            test = input.test;
            trainCopy = train.copy();
            testCopy = test.copy();            
            numClasses = max(train.Y);
            numInstances = size(trainCopy.X,1) + size(testCopy.X,1);         
            invM = {};     
            W = {};
            
            %Different views for feature groups
            %featureGroups = {1:300,301:328,329:368,369:405};            
            %featureGroups = [num2cell(1:300) {301:328,329:368,369:405}];
            %featureGroups = num2cell(1:405);
                                    
            %all pairs of features
            %{
            for i=1:size(trainCopy.X,2)
                for j=i+1:size(trainCopy.X,2)
                    featureGroups{end+1} = [i j];
                end
            end
            %}
            %featureGroups{end+1} = 1:size(trainCopy.X,2);
            %featureGroups = {1:size(trainCopy.X,2)};
            
            %featuresToUse = 5;
            
            featureGroups = num2cell(1:size(trainCopy.X,2));
            F = zeros(numInstances,numClasses,length(featureGroups));
            perGroupAcc = zeros(length(featureGroups),1);
            llgcMethod = LLGCMethod(LearnerConfigs);
            llgcMethod.updateConfigs(obj.configs());
            for groupIdx=1:length(featureGroups);
                dims = featureGroups{groupIdx};
                trainCopy.X = train.X(:,dims);
                testCopy.X = test.X(:,dims);   
                d = obj.createDistanceMatrix(trainCopy,testCopy,...
                    useHF,obj.configs,makeRBF);                                
                d.removeTestLabels();
                %distMats{groupIdx} = d;
                if groupIdx == 1
                    distMat = d;
                    Ymat = Helpers.createLabelMatrix(d.Y);
                end
                if obj.get('sum')
                    if groupIdx > 1
                        distMat.W = distMat.W + d.W;
                    end
                else
                    %{
                    [Wrbf,YtrainMat,sigma] = makeLLGCMatrices(obj,d);                                        
                    invM{end+1} = LLGC.makeInvM_unbiased(Wrbf,alpha,YtrainMat);
                    [F(:,:,groupIdx),~] = LLGC.llgc_inv_unbiased([],YtrainMat,alpha,invM{groupIdx});
                    %}
                    savedData = struct();
                    [F(:,:,groupIdx),savedData,~] = llgcMethod.runLLGC(d,true,savedData);
                    invM{end+1} = savedData.invM;
                    W{groupIdx} = d.W;
                    [~,Fpred] = max(F(:,:,groupIdx),[],2);
                    accVec = distMat.trueY == Fpred;
                    perGroupAcc(groupIdx) = mean(accVec(distMat.isTargetTest()));
                end
            end
            F(isnan(F(:))) = 0;
            assert(~any(isnan(F(:))));
            if obj.get('sum')
                distMat.W = distMat.W ./ length(featureGroups);
            end
            isLabeledInds = distMat.isLabeled();
            numLabeled = sum(isLabeledInds);
            %F_labeled = F(isLabeledInds,:,:);
            Y_labeled = distMat.Y(isLabeledInds);
            Y_labeled_mat = Helpers.createLabelMatrix(Y_labeled);
            isLabeledInds = find(isLabeledInds);

            if obj.get('slZ')
                transform = NormalizeTransform();
            else
                transform = TransformBase();
            end
            if ~obj.get('sum')                     
                F_labeled = zeros(length(isLabeledInds),size(F,2),size(F,3));                
                for instanceIdx = 1:length(isLabeledInds)
                    ind = isLabeledInds(instanceIdx);
                    
                    Y_copy = distMat.Y;
                    Y_copy(ind) = -1;
                    YMatCurrRemoved = Helpers.createLabelMatrix(Y_copy);
                    for groupIdx=1:length(featureGroups)
                         %[F(:,:,groupIdx),~] = LLGC.llgc_inv([],YMatCurrRemoved,alpha,invM{groupIdx});

                         %[F(:,:,groupIdx),~] = LLGC.llgc_inv_unbiased([],YMatCurrRemoved,alpha,invM{groupIdx});
                         %F_labeled(instanceIdx,:,groupIdx) = F(ind,:,groupIdx);
                         
                         %a = LLGC.llgc_inv_unbiased([],YMatCurrRemoved,[],invM{groupIdx});
                         a = LLGC.llgc_inv([],YMatCurrRemoved,[],invM{groupIdx});
                         F_labeled(instanceIdx,:,groupIdx) = a(ind,:);
                         
                         %F_labeled(instanceIdx,:,groupIdx) = F(ind,:,groupIdx);
                    end                    
                end
                F(isnan(F(:))) = 0;
                assert(~any(isnan(F(:))));
                F_labeled(isnan(F_labeled)) = 0;         
                
                trainAccs = zeros(length(featureGroups),1);
                testAccs = trainAccs;
                for groupIdx=1:length(featureGroups);
                    Fcurr = F_labeled(:,:,groupIdx);
                    [~,FcurrPred] = max(Fcurr,[],2);
                    accVec = FcurrPred == distMat.trueY(isLabeledInds);
                    trainAccs(groupIdx) = mean(accVec);
                    
                    Fcurr = F(:,:,groupIdx);
                    [~,FcurrPred] = max(Fcurr,[],2);
                    accVec = FcurrPred == distMat.trueY;
                    testAccs(groupIdx) = mean(accVec);
                end
                
                if ~obj.get('uniform')                    
                    if obj.get('regularized')
                        %error('');
                        reg = .1;
                    else
                        reg = 0;
                    end        
                    solveForBeta = true;
                    numFolds = 10;
                    useFCurrLabeled = 0;
                    if solveForBeta              
                        pc = ProjectConfigs.Create();
                        regVals = pc.reg;            
                        
                        regPerf = zeros(size(regVals));
                        regPerfTrain = regPerf;                        
                        for foldIdx=1:numFolds
                            isTest = DataSet.generateSplit([.8 .2 0],...
                                Y_labeled) == 2;
                            cvLabeledInds = isLabeledInds(~isTest);
                            Fcurr = zeros(length(Y_labeled),size(F,2),size(F,3));                            
                            FcurrLabeled = zeros(length(cvLabeledInds),size(F,2),size(F,3));
                            Y_copy = distMat.Y;
                            Y_copy(isLabeledInds(isTest)) = -1;                            
                            
                            if useFCurrLabeled
                                YMatCurrRemoved = Helpers.createLabelMatrix(Y_copy);
                                for groupIdx=1:length(featureGroups)                                
                                    a = LLGC.llgc_inv_unbiased([],YMatCurrRemoved,[],invM{groupIdx});
                                    Fcurr(:,:,groupIdx) = a(isLabeledInds,:);

                                    for cvIdx=1:length(cvLabeledInds)
                                        Y_copy2 = Y_copy;
                                        Y_copy2(cvLabeledInds(cvIdx)) = -1;
                                        Y_copy2Mat = Helpers.createLabelMatrix(Y_copy2);
                                        a = LLGC.llgc_inv_unbiased([],Y_copy2Mat,[],invM{groupIdx});
                                        FcurrLabeled(cvIdx,:,groupIdx) = a(cvIdx,:);
                                    end
                                end
                            end
                    
                            for regIdx=1:length(regVals)
                                reg = regVals(regIdx);                                                                
                                %Xtrain = Fcurr(~isTest,:,:);
                                
                                if useFCurrLabeled
                                    Xtrain = FcurrLabeled;
                                else
                                    Xtrain = F_labeled(~isTest,:,:);
                                end
                                Ytrain = Helpers.createLabelMatrix(Y_labeled(~isTest));
                                [F_bar_labeled, Y_bar_labeled] = obj.stackLabels(Xtrain,Ytrain);
                                                                                                
                                transform.learn(F_bar_labeled);   
                                F_bar_labeled = transform.apply(F_bar_labeled,Y_bar_labeled);
                                b = obj.solveForBeta(F_bar_labeled,Y_bar_labeled,reg);
                                
                                for i=1:size(Xtrain,2)
                                    a = squeeze(Xtrain(:,i,:));
                                    Xtrain(:,i,:) = transform.apply(a);
                                end
                                
                                [~,trainPred] = max(obj.sumF(Xtrain,b),[],2);
                                accVec = trainPred == Y_labeled(~isTest);
                                regPerfTrain(regIdx) = regPerfTrain(regIdx) + mean(accVec);
                                
                                if useFCurrLabeled                                    
                                    Xtest = Fcurr(isTest,:,:);
                                else                                    
                                    Xtest = F_labeled(isTest,:,:);
                                end                                
                                Ytest = Y_labeled(isTest);                                
                                
                                for i=1:size(Xtest,2)             
                                    a = squeeze(Xtest(:,i,:));
                                    Xtest(:,i,:) = transform.apply(a);
                                    
                                end
                                XbTest = obj.sumF(Xtest,b);
                                [~,YtestPred] = max(XbTest,[],2);
                                regPerf(regIdx) = regPerf(regIdx) + mean(YtestPred == Ytest);
                            end
                        end
                        regPerfTrain = regPerfTrain ./ numFolds;
                        regPerf = regPerf ./ numFolds;
                        regInd = argmax(regPerf);
                        reg = regVals(regInd);
                        display(['best reg: ' num2str(reg)]);
                        [F_bar_labeled,Y_bar_labeled] = obj.stackLabels(F_labeled,Y_labeled_mat);
                        
                        transform.learn(F_bar_labeled);
                        F_bar_labeled = transform.apply(F_bar_labeled,Y_bar_labeled);
                        
                        b = obj.solveForBeta(F_bar_labeled,Y_bar_labeled,reg);
                        [~,sortedFeatures] = sort(abs(b),'descend');
                    else
                        [v,sortedFeatures] = sort(trainAccs,'descend');
                        b = zeros(length(featureGroups),1);
                        b(sortedFeatures(1:featuresToUse)) = 1;
                        b = b./sum(b);                            
                    end
                    
                    combineFeatures = false;                    
                    if ~combineFeatures                  
                        
                        for i=1:size(F_labeled,2)
                            a = squeeze(F_labeled(:,i,:));
                            F_labeled(:,i,:) = transform.apply(a);
                        end
                        
                        Fb_labeled = obj.sumF(F_labeled,b);
                        [~,Fb_labeledPred] = max(Fb_labeled,[],2);
                        accVec = Fb_labeledPred == distMat.Y(isLabeledInds);
                        %t = [Fb_labeledPred distMat.Y(isLabeledInds)];
                        display(['TrainAcc: ' num2str(mean(accVec))]);
                    else
                        dims = sortedFeatures(1:featuresToUse);
                        trainCopy.X = train.X(:,dims);
                        testCopy.X = test.X(:,dims);   
                        distMat = obj.createDistanceMatrix(trainCopy,testCopy,...
                            useHF,obj.configs);                                
                        distMat.removeTestLabels();
                        isLabeledInds = find(distMat.isLabeled());
                        [Wrbf,YtrainMat,sigma] = makeLLGCMatrices(obj,distMat);
                        %invM = LLGC.makeInvM_unbiased(Wrbf,alpha,YtrainMat);
                        %F = LLGC.llgc_inv_unbiased([],YtrainMat,alpha,invM);
                        error('Use llgcMethod.runLLGC');
                        F = LLGC.llgc_inv(Wrbf,YtrainMat,alpha);
                        b = 1;                        
                    end                                        
                end
            end
            
            trueY = distMat.trueY;
            testResults = FoldResults();
            testResults.yActual = trueY;
            testResults.dataType = distMat.type;
            if obj.get('sum')
                F  = obj.runLLGC(distMat);
                [~,FsumPred] = max(F,[],2);
                testResults.dataFU = sparse(F);
                testResults.yPred = FsumPred;
            else                
                if obj.get('uniform')
                    Faverage = obj.sumF(F);
                    [~,FavePred] = max(Faverage,[],2);
                    testResults.yPred = FavePred;
                    testResults.dataFU = sparse(Faverage);
                else                
                    %b = obj.solveForBeta(F_bar,Y_bar,reg);
                    if length(b) > 1
                        for i=1:size(F,2)
                            a = squeeze(F(:,i,:));
                            F(:,i,:) = transform.apply(a);
                        end
                        Fb = obj.sumF(F,b);
                    else
                        Fb = F;
                    end
                    [~,FbPred] = max(Fb,[],2);
                    testResults.yPred = FbPred;                    
                    testResults.dataFU = sparse(Fb);                    
                end              
            end
            featureSmoothness = zeros(length(W),1);
            for i=1:length(W)
                featureSmoothness(i) = LLGC.smoothness(W{i},distMat.trueY);
            end
            testResults.learnerStats.featureWeights = b;
            if obj.get('addBias')
                testResults.learnerStats.featureWeights = b(2:end);
                testResults.learnerStats.bias = b(1);
            end
            testResults.learnerStats.featureTrainAccs = trainAccs;
            testResults.learnerStats.featureTestAccs = testAccs;
            testResults.learnerStats.featureSmoothness = featureSmoothness;
            v = testResults.yPred;
            accVec = testResults.yPred == trueY;
            trainAcc = mean(accVec(isLabeledInds));
            testAcc = mean(accVec(distMat.isTargetTest()));
            display([num2str(trainAcc) ' ' num2str(testAcc)]);
            assert(~any(isnan(testResults.dataFU(:))));
            t = [trainAccs testAccs featureSmoothness testResults.learnerStats.featureWeights];
        end
        
        function [Fb] = sumF(obj,F,b)
            addBias = obj.get('addBias');
            if ~exist('b','var')
                Fb = sum(F,3)./size(F,3);
            else
                Fb = zeros(size(F,1),size(F,2));
                if addBias
                    Fb = Fb + b(1);
                    for featIdx=1:(length(b)-1)
                        Fb = Fb + F(:,:,featIdx)*b(featIdx+1);
                    end
                else
                    for featIdx=1:length(b)
                        Fb = Fb + F(:,:,featIdx)*b(featIdx);
                    end
                end
            end
        end
        
        function [F_bar,Y_bar] = stackLabels(obj,F,Y)
            numInstances = size(F,1);
            numClasses = size(F,2);
            numFeatures = size(F,3);
            F_bar = zeros(numInstances*numClasses,numFeatures);
            Y_bar = zeros(size(F_bar,1),1);
            for classIdx=1:numClasses
                start = (classIdx-1)*numInstances + 1;
                finish = classIdx*numInstances;
                %F_bar(start:finish,:) = reshape(F(:,classIdx,:),numInstances,numFeatures);
                F_bar(start:finish,:) = squeeze(F(:,classIdx,:));
                Y_bar(start:finish) = Y(:,classIdx);
                display('Not stacking all');
                break;
            end
            if obj.get('addBias')
            	%Y_bar(Y_bar==0) = -1;
            end
        end
        
        function [b] = solveForBeta(obj,F_bar,Y_bar,reg)
            if obj.get('addBias')
                if obj.get('lasso')
                    [B,stats] = lasso(F_bar,Y_bar,'Lambda',reg);
                    b = [stats.Intercept ; B];
                else
                    b = ridge(Y_bar,F_bar,reg,0);                 
                end
                F_bar_bias = [ones(size(F_bar,1),1) F_bar];
                d = F_bar_bias*b - Y_bar;
            else
                assert(~obj.get('lasso'));
                numFeatures = size(F_bar,2);            
                u = ones(numFeatures,1)./numFeatures;
                warning off
                cvx_begin quiet
                    variable b(numFeatures,1)
                    %minimize(norm(F_bar*b-Y_bar,'fro') + reg*norm(b-u,2))
                    minimize(norm(F_bar*b-Y_bar) + reg*norm(b,2))
                    subject to
                        %b >= 0
                cvx_end  
                warning on
            end            
            %b(b < 0) = 0;
            
        end
        
        function [] = updateConfigs(obj, newConfigs)
            %keys = {'sigma', 'sigmaScale','k','alpha'};
            keys = {'sigmaScale','alpha'};
            obj.updateConfigsWithKeys(newConfigs,keys);
        end                
        
        function [prefix] = getPrefix(obj)
            prefix = 'SepLLGC';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {'sigmaScale'};
            if length(obj.get('alpha')) == 1
                nameParams{end+1} = 'alpha';
            end            
            if obj.has('sum') && obj.get('sum')
                nameParams{end+1} = 'sum';
            elseif obj.has('uniform') && obj.get('uniform')
                nameParams{end+1} = 'uniform';
            else
                nameParams{end+1} = 'regularized';
            end
            if obj.has('addBias') && obj.get('addBias')
                nameParams{end+1} = 'addBias';
            end
            if obj.has('lasso') && obj.get('lasso')
                nameParams{end+1} = 'lasso';
            end
            if obj.has('slZ') && obj.get('slZ')
                nameParams{end+1} = 'slZ';
            end
        end
    end
    
end

