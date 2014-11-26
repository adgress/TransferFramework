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
            [Wrbf,YtrainMat,sigma,Y_testCleared] = makeLLGCMatrices(obj,distMat);
            labels = ProjectConfigs.labelsToUse; 
                        
            YtrainMat = Helpers.createLabelMatrix(Y_testCleared);
            
            M = obj.makeM(Wrbf);
            distMatRBF = DistanceMatrix(M,Y_testCleared,distMat.type,distMat.trueY);            
            useOracle = obj.get('oracle');
            useUnweighted = obj.get('unweighted');
            assert(~(useOracle && useUnweighted));
            if useOracle
                a = zeros(size(M,1),1);
                a(~distMatRBF.isNoisy & Y_testCleared > 0) = 1;
                a = repmat(a,1,length(labels));                
            elseif useUnweighted
                a = ones(size(M,1),length(labels));
            else
                regParams = [.1 1 10 100];
                numFolds = 3;
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

                        [a] = obj.solveForNodeWeights(A,Ysub,reg);                    

                        aAll = zeros(size(M,1),1);
                        aAll(hasLabel) = a;
                        aOracleAll = zeros(size(M,1),1);
                        aOracleAll(~distMat.isNoisy & hasLabel) = 1;
                        aAll = repmat(aAll,1,length(labels));
                        aOracleAll = repmat(aOracleAll,1,length(labels));
                        Ypred = M\(YtrainMatCurr.*aAll);
                        [~,Y1] = max(Ypred,[],2);

                        YpredNorm = M\YtrainMatCurr;
                        [~,Y2] = max(YpredNorm,[],2);                                

                        YpredOracle = M\(YtrainMatCurr.*aOracleAll);
                        [~,Y3] = max(YpredOracle,[],2);

                        isLabeledTest = Y_testCleared > 0 & split == 2;
                        Yactual = distMat.Y;
                        %Yactual = distMat.trueY;
                        acc = sum(Yactual(isLabeledTest) == Y1(isLabeledTest))/sum(isLabeledTest);
                        %{
                        display(['Accuracy: ' num2str(acc)]);
                        accNormal = sum(Yactual(isLabeledTest) == Y2(isLabeledTest))/sum(isLabeledTest);
                        display(['Accuracy Normal: ' num2str(accNormal)]);
                        accOracle = sum(Yactual(isLabeledTest) == Y3(isLabeledTest))/sum(isLabeledTest);
                        display(['Accuracy Oracle: ' num2str(accOracle)]);
                        %}
                        regAcc(regIdx,foldIdx) = acc;
                    end
                end
                meanRegAcc = mean(regAcc,2);
                [~,maxIdx] = max(meanRegAcc);
                reg = regParams(maxIdx);
                
                hasLabel = Y_testCleared > 0;
                Msub = M(hasLabel,hasLabel);
                Ysub = YtrainMat(hasLabel,:);
                A = Msub*Ysub;               
                [aSub] = obj.solveForNodeWeights(A,Ysub,reg);
                a = zeros(size(M,1),1);
                a(hasLabel) = aSub;
                a = repmat(a,1,length(labels));
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
        end
        
        function [M] = makeM(obj,W)
            W(logical(speye(size(W)))) = 0;
            Disq = diag(sum(W).^-.5);
            WN = Disq*W*Disq;
            alpha = ProjectConfigs.alpha;                                
            I = eye(size(WN,1));
            M = (1/(1-alpha))*(I-alpha*WN);
        end
        
        function [a] = solveForNodeWeights(obj,A,Y,reg)
            %numLabeled = sum(hasLabel);
            numLabeled = size(Y,1);
            numLabels = size(Y,2);
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
        
        function [nameParams] = getNameParams(obj)
            %nameParams = {'sigma','sigmaScale','k','alpha'};
            nameParams = {'noise','oracle','unweighted'};
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'LLGC-Weighted';
        end
    end
    
end

