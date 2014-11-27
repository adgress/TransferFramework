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
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
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
            labels = ProjectConfigs.labelsToUse; 
            if isempty(labels)
                labels = distMat.classes;
            end
            YtrainMat = Helpers.createLabelMatrix(Y_testCleared);
            
            M = obj.makeM(Wrbf);
            distMatRBF = DistanceMatrix(M,Y_testCleared,distMat.type,distMat.trueY,distMat.instanceIDs);            
            useOracle = obj.get('oracle');
            useUnweighted = obj.get('unweighted');
            useDataSetWeights = obj.get('dataSetWeights');
            assert(~(useOracle && useUnweighted));
            assert(~(useDataSetWeights && (useOracle || useUnweighted)));
            if useOracle
                a = zeros(size(M,1),1);
                a(~distMatRBF.isNoisy & Y_testCleared > 0) = 1;
                a = repmat(a,1,max(labels));                
            elseif useUnweighted
                a = ones(size(M,1),max(labels));
            else
                regParams = [.1 1 10 100];
                numFolds = ProjectConfigs.numFolds;
                regAcc = zeros(length(regParams),numFolds);
                splits = cell(numFolds,1);
                for foldIdx=1:numFolds
                    splits{foldIdx} = distMatRBF.generateSplitArray(.8,.2);
                end                
                for regIdx = 1:length(regParams)
                    reg = regParams(regIdx);
                    for foldIdx=1:numFolds
                        split = splits{foldIdx};

                        YtrainMatCurr = YtrainMat;
                        YtrainMatCurr(split==2,:) = 0;
                        Y_testClearedCurr = Y_testCleared;
                        Y_testClearedCurr(split==2) = -1;

                        hasLabel = Y_testClearedCurr > 0;
                        Msub = M(hasLabel,hasLabel);

                        Y = YtrainMatCurr;                
                        Ysub = Y(hasLabel,:);

                        A = Msub*Ysub;
                        if useDataSetWeights
                            
                        else
                            [a] = obj.solveForNodeWeights(A,Ysub,reg);                    
                        end
                        aAll = zeros(size(M,1),1);
                        aAll(hasLabel) = a;                        
                        aAll = repmat(aAll,1,max(labels));
                        Ypred = M\(YtrainMatCurr.*aAll);
                        [~,Y1] = max(Ypred,[],2);

                        YpredNorm = M\YtrainMatCurr;
                        [~,Y2] = max(YpredNorm,[],2);                                
                        isLabeledTest = Y_testCleared > 0 & split == 2;
                        Yactual = distMat.Y;
                        %Yactual = distMat.trueY;
                        acc = sum(Yactual(isLabeledTest) == Y1(isLabeledTest))/sum(isLabeledTest);
                        %{
                        display(['Accuracy: ' num2str(acc)]);
                        accNormal = sum(Yactual(isLabeledTest) == Y2(isLabeledTest))/sum(isLabeledTest);
                        display(['Accuracy Normal: ' num2str(accNormal)]);
                        %}
                        regAcc(regIdx,foldIdx) = acc;
                    end
                end
                if ProjectConfigs.numFolds > 0
                    meanRegAcc = mean(regAcc,2);
                    [~,maxIdx] = max(meanRegAcc);
                    reg = regParams(maxIdx);
                else
                    reg = ProjectConfigs.reg;
                end
                
                hasLabel = Y_testCleared > 0;                
                Msub = M(hasLabel,hasLabel);
                Ysub = YtrainMat(hasLabel,:);
                %instanceIDsSub = instanceIDs(hasLabel);
                A = Msub*Ysub;               
                if obj.get('dataSetWeights')
                    isTarget = instanceIDs == min(instanceIDs);
                    %hasLabel = hasLabel & isTarget;
                    isTargetSub = isTarget(hasLabel);
                    instanceIDsSub = instanceIDs(hasLabel);
                    Ysub = Ysub(isTargetSub,:);
                end 
                [aSub] = obj.solveForNodeWeights(A,Ysub,reg,instanceIDsSub);
                a = zeros(size(M,1),1);
                a(hasLabel) = aSub;
                a = repmat(a,1,max(labels));
            end
            
            F = M\(YtrainMat.*a);
            [~,Ypred] = max(F,[],2);
            testResults = FoldResults();
            testResults.yPred = Ypred;
            testResults.yActual = distMat.trueY;
            testResults.learnerMetadata.sigma = sigma;
            testResults.dataFU = sparse(F);
            testResults.dataType = distMat.type;
            isTest = distMat.isTargetTest();
            acc = sum(Ypred(isTest) == distMat.trueY(isTest))/sum(isTest);
            display(['LLGCMethod Acc: ' num2str(acc)]);
            
            Fnormal = M\YtrainMat;
            [~,YpredNormal] = max(Fnormal,[],2);
            accNormal = sum(YpredNormal(isTest) == distMat.trueY(isTest))/sum(isTest);
            display(['Normal Acc: ' num2str(accNormal)])
            
            YtrainMat_justTarget = YtrainMat;
            YtrainMat_justTarget(instanceIDs ~= 0,:) = 0;
            FjustTarget = M\YtrainMat_justTarget;
            [~,YpredJustTarget] = max(FjustTarget,[],2);
            accJustTarget = sum(YpredJustTarget(isTest) == distMat.trueY(isTest))/sum(isTest);
            display(['Just Target Acc: ' num2str(accJustTarget)])
            
            YtrainMat_oracle = YtrainMat;
            YtrainMat_oracle(instanceIDs > 1,:) = 0;
            Foracle = M\YtrainMat_oracle;
            [~,YpredOracle] = max(Foracle,[],2);
            accJustOracle = sum(YpredOracle(isTest) == distMat.trueY(isTest))/sum(isTest);
            display(['Oracle Acc: ' num2str(accJustOracle)])
            
            YtrainMat_source = YtrainMat;
            YtrainMat_source(instanceIDs <= 1,:) = 0;
            Fsource = M\YtrainMat_source;
            [~,YpredSource] = max(Fsource,[],2);
            accSource = sum(YpredSource(isTest) == distMat.trueY(isTest))/sum(isTest);
            display(['Source Acc: ' num2str(accSource)])
        end                
        
        function [M] = makeM(obj,W)
            W(logical(speye(size(W)))) = 0;
            Disq = diag(sum(W).^-.5);
            WN = Disq*W*Disq;
            alpha = ProjectConfigs.alpha;                                
            I = eye(size(WN,1));
            M = (1/(1-alpha))*(I-alpha*WN);
        end
        
        function [a] = solveForNodeWeights(obj,A,Y,reg,instanceIDs)                        
            numLabels = size(Y,2);            
            if obj.get('dataSetWeights')
                dataSets = unique(instanceIDs);
                numDataSets = length(dataSets);
                numInstances = length(instanceIDs);
                dataSetOffset = 1 - min(dataSets);                
                isTarget = instanceIDs == min(dataSets);
                numTarget = sum(isTarget);
                warning off
                cvx_begin quiet
                    variable a(numDataSets)
                    variable aDup(numInstances)
                    variable AaSub(numTarget,numLabels)
                    variable Aa(numInstances,numLabels)
                    %minimize(norm(vec(A.*repmat(aDup,1,numLabels)-Y),1) + reg*norm(a-1,1))
                    minimize(norm(vec(AaSub-Y),1)/numel(find(Y)) + reg*norm(a(2:end),1))
                    subject to             
                        AaSub == Aa(isTarget,:);
                        Aa == A.*repmat(aDup,1,numLabels)
                        aDup == a(instanceIDs+dataSetOffset)
                        a >= 0
                        a <= 1
                        a(1) == 0                        
                        %sum(a) == 1
                cvx_end  
                warning on                 
                a(1) = 1;
                aDup(instanceIDs == 0) = 1;
                a
                [norm(vec(AaSub-Y),2)/numel(find(Y)) reg*norm(a,1)]
                a = aDup;
            else        
                numLabeled = size(Y,1);
                warning off
                cvx_begin quiet
                    variable a(numLabeled)
                    %minimize(norm(A*a-Ysub,'fro') + reg*norm(a-1))
                    minimize(norm(vec(A.*repmat(a,1,numLabels)-Y),1) + reg*norm(a-1,1))
                    %minimize(norm(vec(A.*repmat(a,1,numLabels)-Ysub),'fro') + reg*norm(a-1,1))
                    subject to
                        a >= 0
                cvx_end  
                warning on   
            end
        end
        
        function [nameParams] = getNameParams(obj)
            %nameParams = {'sigma','sigmaScale','k','alpha'};
            nameParams = {'dataSetWeights','noise','oracle','unweighted'};
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'LLGC-Weighted';
        end
    end
    
end

