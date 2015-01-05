classdef LLGCWeightedMethod < LLGCMethod
    %LLGCWEIGHTED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LLGCWeightedMethod(configs)
            obj = obj@LLGCMethod(configs);
            if ~obj.has('oracle')
                obj.set('oracle',false);
            end
            if ~obj.has('unweighted')
                obj.set('unweighted',false);
            end
            if ~obj.has('dataSetWeights')
                obj.set('dataSetWeights',false);
            end
            if ~obj.has('sort')
                obj.set('sort',true);
            end           
            if ~obj.has('useOracleNoise')
                obj.set('useOracleNoise',false);
            end            
            if ~obj.has('useJustTarget')
                obj.set('justTarget',false);
            end
            if ~obj.has('justTargetNoSource')
                obj.set('justTargetNoSource',false);
            end
            if ~obj.has('robustLoss')
                obj.set('robustLoss',false);
            end
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            pc = ProjectConfigs.Create();
            useHF = false;
            %{
            if exist('savedData','var')
                [testResults,savedData] = ...
                    obj.trainAndTestGraphMethod(input,useHF,savedData);
            else
                [testResults] = ...
                    obj.trainAndTestGraphMethod(input,useHF);
            end
            %}
            train = input.train;
            test = input.test;   
            testResults = FoldResults();   
            if isfield(input,'distanceMatrix')
                distMat = input.distanceMatrix;
                error('Possible bug - is this taking advantage of source data?');
            else                
                %[distMat] = obj.createDistanceMatrix(train,test,useHF,learner.configs);
                [distMat] = obj.createDistanceMatrix(train,test,useHF,obj.configs);
                testResults.dataType = distMat.type;
            end
            [Wrbf,YtrainMat,sigma,Y_testCleared,instanceIDs] = obj.makeLLGCMatrices(distMat);
            labels = pc.labelsToUse; 
            if isempty(labels)
                labels = distMat.classes;
            end
            YtrainMat = Helpers.createLabelMatrix(Y_testCleared);
            
            M = obj.makeM(Wrbf);  
            M_inv = inv(M);
            distMatRBF = DistanceMatrix(M,Y_testCleared,distMat.type,distMat.trueY,distMat.instanceIDs);            
            useOracle = obj.get('oracle');
            useUnweighted = obj.get('unweighted');
            useDataSetWeights = obj.get('dataSetWeights');
            useJustTarget = obj.get('justTarget');
            useJustTargetNoSource = obj.get('justTargetNoSource');
            useRobustLoss = obj.get('robustLoss');
            useSorted = obj.get('sort');
            assert(~(useOracle && useUnweighted));            
            if useOracle || useUnweighted || useJustTarget || useJustTargetNoSource ...
                    || useRobustLoss
                
            else
                paramsCrossProduct = Helpers.MakeCrossProductForFields(pc.cvParams,pc);
                numFolds = pc.numFolds;
                cvAcc = zeros(length(paramsCrossProduct),numFolds);
                splits = cell(numFolds,1);
                for foldIdx=1:numFolds
                    splits{foldIdx} = distMatRBF.generateSplitArray(.8,.2);
                end                
                for cvIndex = 1:length(paramsCrossProduct)
                    currParamValues = paramsCrossProduct(cvIndex);
                    currParamValues{1}
                    obj.set(pc.cvParams,Helpers.Mat2CellArray(currParamValues{1}));
                    for foldIdx=1:numFolds
                        split = splits{foldIdx};

                        YtrainMatCurr = YtrainMat;
                        YtrainMatCurr(split==2,:) = 0;
                        Y_testClearedCurr = Y_testCleared;
                        Y_testClearedCurr(split==2) = -1;

                        hasLabel = Y_testClearedCurr > 0;
                        Msub = M_inv(hasLabel,hasLabel);        
                        Ysub = YtrainMatCurr(hasLabel,:);

                        A = Msub;
                        instanceIDsSub = instanceIDs(hasLabel);
                        if useDataSetWeights
                            [a] = obj.solveForNodeWeights(A,Ysub,instanceIDsSub);
                        else
                            [a] = obj.solveForNodeWeights(A,Ysub,instanceIDsSub);
                        end
                        aAll = zeros(size(M,1),1);
                        aAll(hasLabel) = a;                        
                        aAll = repmat(aAll,1,max(labels));
                        Ypred = Helpers.normRows(M\(YtrainMatCurr.*aAll));
                        [~,Y1] = max(Ypred,[],2);
                        Y1soft = sum(Ypred.*YtrainMat,2);
                        YpredNorm = Helpers.normRows(M\YtrainMatCurr);
                        [~,Y2] = max(YpredNorm,[],2);                                
                        Y2soft = sum(YpredNorm.*YtrainMat,2);
                        isLabeledTest = Y_testCleared > 0 & split == 2;                        
                        if useDataSetWeights
                            isLabeledTest = isLabeledTest & instanceIDs == 0;
                        end
                        numTest = sum(isLabeledTest);
                        Yactual = distMat.Y;
                        %Yactual = distMat.trueY;                        
                        acc = sum(Yactual(isLabeledTest) == Y1(isLabeledTest))/numTest;
                        accSoft = sum(Y1soft(isLabeledTest))/numTest;
                        accSoftNormal = sum(Y2soft(isLabeledTest))/numTest;
                        display(['Accuracy: ' num2str(acc)]);
                        accNormal = sum(Yactual(isLabeledTest) == Y2(isLabeledTest))/numTest;
                        display(['Accuracy Normal: ' num2str(accNormal)]);
                                                
                        if useDataSetWeights
                            YtrainMatCurrOracle = YtrainMatCurr;
                            YtrainMatCurrOracle(instanceIDs > 1,:) = 0;
                            YpredOracle = M\YtrainMatCurrOracle;
                        else
                            aOracle = zeros(size(M,1),1);
                            aOracle(hasLabel) = 1;
                            aOracle(distMat.isNoisy) = 0;                            
                            aOracle = repmat(aOracle,1,max(labels));
                            YpredOracle = M\(YtrainMatCurr.*aOracle);
                        end
                        YpredOracle = Helpers.normRows(YpredOracle);
                        [~,Y3] = max(YpredOracle,[],2);
                        Y3soft = sum(YpredOracle.*YtrainMat,2);
                        accSoftOracle = sum(Y3soft(isLabeledTest))/numTest;
                        accOracle = sum(Yactual(isLabeledTest) == Y3(isLabeledTest))/numTest;
                        display(['Accuracy Oracle: ' num2str(accOracle)]);
                        display(['Acc Soft: ' num2str(accSoft)]);
                        display(['Acc Soft Normal: ' num2str(accSoftNormal)]);
                        display(['Acc Soft Oracle: ' num2str(accSoftOracle)]);
                        %cvAcc(cvIndex,foldIdx) = accSoft;
                        cvAcc(cvIndex,foldIdx) = accSoft;
                    end
                end
                if pc.numFolds > 0
                    meanRegAcc = mean(cvAcc,2);
                    [~,maxIdx] = max(meanRegAcc);
                    params = paramsCrossProduct(maxIdx);
                    obj.set(pc.cvParams,Helpers.Mat2CellArray(params{1}));
                    display(['Best noise: ' num2str(obj.get('noise'))]);
                    display(['Best reg: ' num2str(obj.get('reg'))]);
                else   
                    obj.set('reg',.01);
                    %error('TODO: Default params?');
                    %reg = pc.reg;
                end
                if ~useOracle && ~useUnweighted
                    hasLabel = Y_testCleared > 0;     
                    Msub = M_inv(hasLabel,hasLabel);
                    Ysub = YtrainMat(hasLabel,:);
                    A = Msub;                
                    instanceIDsSub = instanceIDs(hasLabel);
                    [aSub,undupedWeights] = obj.solveForNodeWeights(A,Ysub,instanceIDsSub);
                    a = zeros(size(M,1),1);
                    a(hasLabel) = aSub;
                    a = repmat(a,1,max(labels));
                end
            end
            
            testResults = FoldResults();
            testResults.yActual = distMat.trueY;
            testResults.learnerMetadata.sigma = sigma;
            testResults.dataType = distMat.type;
            isTest = distMat.isTargetTest() & distMat.Y > 0;
            if ~useOracle && ~useUnweighted && ~useJustTarget && ~useJustTargetNoSource ...
                    && ~useRobustLoss
                F = M\(YtrainMat.*a);
                [~,Ypred] = max(F,[],2);                                
                testResults.yPred = Ypred;                        
                testResults.dataFU = sparse(F);                            
                acc = sum(Ypred(isTest) == distMat.trueY(isTest))/sum(isTest);
                display(['LLGCMethod Acc: ' num2str(acc)]);
                testResults.instanceWeights = a(:,1);
                testResults.learnerStats.reg = obj.get('reg');
                testResults.learnerStats.reg = obj.get('noise');
                if useDataSetWeights
                    testResults.learnerStats.dataSetWeights = undupedWeights;
                    testResults.ID2Labels = train.ID2Labels;
                else
                    testResults.isNoisy = distMat.isNoisy(hasLabel);   
                    testResults.instanceWeights = undupedWeights;
                    %testResults.
                    assert(length(testResults.isNoisy) == length(testResults.instanceWeights));
                end
            end
            Fnormal = M\YtrainMat;
            [~,YpredNormal] = max(Fnormal,[],2);
            accNormal = sum(YpredNormal(isTest) == distMat.trueY(isTest))/sum(isTest);
            display(['Normal Acc: ' num2str(accNormal)])
            if useUnweighted
                testResults.yPred = YpredNormal;
                testResults.dataFU = sparse(Fnormal);                
            end            
            YtrainMat_oracle = YtrainMat;
            if useDataSetWeights
                YtrainMat_oracle(instanceIDs > 1,:) = 0;
            else
                YtrainMat_oracle(distMat.isNoisy,:) = 0;
            end
            Foracle = M\YtrainMat_oracle;
            [~,YpredOracle] = max(Foracle,[],2);
            accJustOracle = sum(YpredOracle(isTest) == distMat.trueY(isTest))/sum(isTest);
            display(['Oracle Acc: ' num2str(accJustOracle)])
            if useOracle
                testResults.yPred = YpredOracle;
                testResults.dataFU = sparse(Foracle);                
            end  
            if useRobustLoss
                %reg = obj.get('reg');
                reg = obj.get('alpha');
                FRobust = obj.LLGCRobust(Wrbf,YtrainMat,reg);
                [~,YpredRobust] = max(FRobust,[],2);
                accRobust = sum(YpredRobust(isTest) == distMat.trueY(isTest))/sum(isTest);
                display(['Robust Acc: ' num2str(accRobust)])
                testResults.yPred = YpredRobust;
                testResults.dataFU = sparse(FRobust);
            end
            if useDataSetWeights                
                YtrainMat_justTarget = YtrainMat;
                YtrainMat_justTarget(instanceIDs ~= 0,:) = 0;
                FjustTarget = M\YtrainMat_justTarget;
                [~,YpredJustTarget] = max(FjustTarget,[],2);
                accJustTarget = sum(YpredJustTarget(isTest) == distMat.trueY(isTest))/sum(isTest);
                display(['Just Target Acc: ' num2str(accJustTarget)])
                
                if useJustTarget || useJustTargetNoSource
                    testResults.yPred = YpredJustTarget;
                    testResults.dataFU = sparse(FjustTarget);
                end
                
                YtrainMat_source = YtrainMat;
                YtrainMat_source(instanceIDs <= 1,:) = 0;
                Fsource = M\YtrainMat_source;
                [~,YpredSource] = max(Fsource,[],2);
                accSource = sum(YpredSource(isTest) == distMat.trueY(isTest))/sum(isTest);
                display(['Source Acc: ' num2str(accSource)])
            end
        end                
        
        function [M, L] = makeM(obj,W)
            pc = ProjectConfigs.Create();
            W(logical(speye(size(W)))) = 0;
            Disq = diag(sum(W).^-.5);
            WN = Disq*W*Disq;
            alpha = pc.alpha;                                
            I = eye(size(WN,1));
            %M = (1/(1-alpha))*(I-alpha*WN);
            L = I-WN;
            M = (I-WN+alpha*I);
        end
        
        function [F] = LLGCRobust(obj,W,Y,reg)
            [~,L] = obj.makeM(W);
            F = zeros(size(Y));
            L = L + 1e-6*eye(size(L));
            for i=1:size(F,2)
                Y_i = Y(:,i);
                warning off
                cvx_begin quiet
                    variable F_i(size(F,1))
                    variable D(size(F,1))
                    variable t(size(F,1))
                    minimize(F_i'*L*F_i + reg*norm(D,1))
                    %minimize(F_i'*L*F_i + reg*norm(D,1))
                    subject to
                        D == F_i-Y_i
                        t = 1/(1+exp(-D))
                cvx_end  
                warning on
                F(:,i) = F_i;
            end
        end
        
        function [a,undupedWeights] = solveForNodeWeights(obj,A,Y,instanceIDs)
            numLabels = size(Y,2);          
            pc = ProjectConfigs.Create();
            A = pc.alpha*A;
            percNoisy = obj.get('noise');
            reg = obj.get('reg');
            if obj.get('dataSetWeights')
                dataSets = unique(instanceIDs);
                numDataSets = length(dataSets);
                numInstances = length(instanceIDs);
                dataSetOffset = 1 - min(dataSets);                
                isTarget = instanceIDs == min(dataSets);
                numTarget = sum(isTarget);
                Ytarget = Y(isTarget,:);
                numUniqueLabels = length(find(sum(Y)));
                warning off
                cvx_begin quiet
                    variable a(numDataSets)
                    variable aDup(numInstances)
                    variable AaSub(numTarget,numLabels)
                    variable Aa(numInstances,numLabels)                   
                    %minimize(norm(vec(AaSub-Ytarget),2)/numUniqueLabels + reg*norm(a(2:end),1))
                    minimize(norm(vec(AaSub-Ytarget),2)/numUniqueLabels)
                    subject to             
                        norm(a(2:end),1) <= reg
                        AaSub == Aa(isTarget,:);
                        Aa == A*(Y.*repmat(aDup,1,numLabels))
                        aDup == a(instanceIDs+dataSetOffset)
                        a(1) == 1
                        a >= 0
                        a <= 1               
                cvx_end  
                a                
                warning on                 
                undupedWeights = a;
                %[norm(vec(AaSub-Y),2)/numel(find(Y)) reg*norm(a,1)]
                a = aDup;
            elseif obj.get('sort')
                numLabeled = size(Y,1);
                a = ones(numLabeled,1);
                F = A*Y;
                v = zeros(numLabeled,1);                
                for i=1:length(v)
                    v(i) = norm(Y(i,:) - F(i,:),1);
                end
                [sortedV,inds] = sort(v,'descend');
                if obj.get('useOracleNoise')
                    percNoisy = pc.classNoise;
                end
                numNoisy = floor(percNoisy*numLabeled);
                a(inds(1:numNoisy)) = 0;
                undupedWeights = a;
            else
                error('Why are we using this?');
                numLabeled = size(Y,1);
                                
                %I think this is the correct problem to solve
                ny = numLabels;
                warning off
                cvx_begin quiet
                    variable a(numLabeled)
                    variable aDup(numLabeled,numLabels)                                        
                    minimize((1/numLabels)*norm(vec((A*Y-Y).*aDup),2) + reg*norm(a-1,1))
                    subject to
                        aDup == repmat(a,1,numLabels)
                        a >= 0
                        a <= 1
                cvx_end  
                (1/ny)*norm(vec(A*(Y.*repmat(a,1,numLabels))-Y),1) 
                reg*norm(a-1,1)
                reg
                warning on   
            end
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {};
            if obj.get('dataSetWeights')
                nameParams{end+1} = 'dataSetWeights';
                if obj.has('justTarget') && obj.get('justTarget');
                    nameParams{end+1} = 'justTarget';
                end
                if obj.has('justTargetNoSource') && obj.get('justTargetNoSource')
                    nameParams{end+1} = 'justTargetNoSource';
                end
            else
                if obj.get('sort')
                    %nameParams{end+1} = 'sort';
                end
                if obj.get('useOracleNoise')
                    nameParams{end+1} = 'useOracleNoise';
                end
                if obj.has('classNoise')
                    nameParams{end+1} = 'classNoise';
                end
            end
            if obj.get('unweighted')
                nameParams{end+1} = 'unweighted';
            end
            if obj.get('oracle')
                nameParams{end+1} = 'oracle';                
            end
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'LLGC-Weighted';
        end
    end
    
end

