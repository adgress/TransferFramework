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
            useSorted = obj.get('sort');
            assert(~(useOracle && useUnweighted));            
            if useOracle && ~useDataSetWeights
                a = zeros(size(M,1),1);
                a(~distMatRBF.isNoisy & Y_testCleared > 0) = 1;
                a = repmat(a,1,max(labels));                
            elseif useUnweighted && ~useDataSetWeights
                a = ones(size(M,1),max(labels));
            else
                regParams = pc.regParams;
                numFolds = pc.numFolds;
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
                        %Msub = M(hasLabel,hasLabel);
                        Msub = M_inv(hasLabel,hasLabel);

                        Y = YtrainMatCurr;                
                        Ysub = Y(hasLabel,:);

                        %A = Msub*Ysub;
                        A = Msub;
                        instanceIDsSub = instanceIDs(hasLabel);
                        if useDataSetWeights
                            
                        else
                            [a] = obj.solveForNodeWeights(A,Ysub,Ysub,reg,instanceIDsSub);
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
                        
                        display(['Accuracy: ' num2str(acc)]);
                        accNormal = sum(Yactual(isLabeledTest) == Y2(isLabeledTest))/sum(isLabeledTest);
                        display(['Accuracy Normal: ' num2str(accNormal)]);
                                                
                        aOracle = zeros(size(M,1),1);
                        aOracle(hasLabel) = 1;
                        aOracle(distMat.isNoisy) = 0;
                        aOracle = repmat(aOracle,1,max(labels));
                        YpredOracle = M\(YtrainMatCurr.*aOracle);
                        [~,Y3] = max(YpredOracle,[],2);
                        accOracle = sum(Yactual(isLabeledTest) == Y3(isLabeledTest))/sum(isLabeledTest);
                        display(['Accuracy Oracle: ' num2str(accOracle)]);
                        
                        regAcc(regIdx,foldIdx) = acc;
                    end
                end
                if pc.numFolds > 0
                    meanRegAcc = mean(regAcc,2);
                    [~,maxIdx] = max(meanRegAcc);
                    reg = regParams(maxIdx);
                else
                    reg = pc.reg;
                end
                
                hasLabel = Y_testCleared > 0;     
                Msub = M_inv(hasLabel,hasLabel);
                Ysub = YtrainMat(hasLabel,:);
                A = Msub;
                if useDataSetWeights
                    isTarget = instanceIDs == min(instanceIDs);
                    isTargetSub = isTarget(hasLabel);
                    instanceIDsSub = instanceIDs(hasLabel);
                    Ysub = Ysub(isTargetSub,:);
                else
                    instanceIDsSub = instanceIDs(hasLabel);
                end
                [aSub] = obj.solveForNodeWeights(A,Ysub,YtrainMat(hasLabel,:),reg,instanceIDsSub);
                a = zeros(size(M,1),1);
                a(hasLabel) = aSub;
                a = repmat(a,1,max(labels));
            end
            
            testResults = FoldResults();
            testResults.yActual = distMat.trueY;
            testResults.learnerMetadata.sigma = sigma;
            testResults.dataType = distMat.type;
            isTest = distMat.isTargetTest();
            if ~useOracle && ~useUnweighted
                F = M\(YtrainMat.*a);
                [~,Ypred] = max(F,[],2);                                
                testResults.yPred = Ypred;                        
                testResults.dataFU = sparse(F);                            
                acc = sum(Ypred(isTest) == distMat.trueY(isTest))/sum(isTest);
                display(['LLGCMethod Acc: ' num2str(acc)]);
            end
            Fnormal = M\YtrainMat;
            [~,YpredNormal] = max(Fnormal,[],2);
            accNormal = sum(YpredNormal(isTest) == distMat.trueY(isTest))/sum(isTest);
            display(['Normal Acc: ' num2str(accNormal)])
            if useUnweighted
                testResults.yPred = YpredNormal;
                testResults.dataFU = sparse(Fnormal);                
            end            
            if useDataSetWeights
                YtrainMat_justTarget = YtrainMat;
                YtrainMat_justTarget(instanceIDs ~= 0,:) = 0;
                FjustTarget = M\YtrainMat_justTarget;
                [~,YpredJustTarget] = max(FjustTarget,[],2);
                accJustTarget = sum(YpredJustTarget(isTest) == distMat.trueY(isTest))/sum(isTest);
                display(['Just Target Acc: ' num2str(accJustTarget)])
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
            if useDataSetWeights
                YtrainMat_source = YtrainMat;
                YtrainMat_source(instanceIDs <= 1,:) = 0;
                Fsource = M\YtrainMat_source;
                [~,YpredSource] = max(Fsource,[],2);
                accSource = sum(YpredSource(isTest) == distMat.trueY(isTest))/sum(isTest);
                display(['Source Acc: ' num2str(accSource)])
            end
        end                
        
        function [M] = makeM(obj,W)
            pc = ProjectConfigs.Create();
            W(logical(speye(size(W)))) = 0;
            Disq = diag(sum(W).^-.5);
            WN = Disq*W*Disq;
            alpha = pc.alpha;                                
            I = eye(size(WN,1));
            %M = (1/(1-alpha))*(I-alpha*WN);
            M = (I-alpha*WN);
        end
        
        function [a] = solveForNodeWeights(obj,A,Y,Yfull,reg,instanceIDs)                        
            numLabels = size(Y,2);          
            pc = ProjectConfigs.Create();
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
                    minimize(norm(vec(AaSub-Y),2)/numel(find(Y)) + reg*norm(a(2:end),1))
                    subject to             
                        AaSub == (1-pc.alpha)*Aa(isTarget,:);
                        Aa == A*(Yfull.*repmat(aDup,1,numLabels))
                        aDup == a(instanceIDs+dataSetOffset)
                        a >= 0
                        a <= 1               
                cvx_end  
                a
                warning on                 
                %[norm(vec(AaSub-Y),2)/numel(find(Y)) reg*norm(a,1)]
                a = aDup;
            elseif obj.get('sort')
                numLabeled = size(Y,1);
                A = (1-pc.alpha)*A;
                a = ones(numLabeled,1);
                F = A*Yfull;
                v = zeros(numLabeled,1);                
                for i=1:length(v)
                    v(i) = norm(Yfull(i,:) - F(i,:),1);
                end
                [sortedV,inds] = sort(v,'descend');
                numNoisy = floor(ProjectConfigs.Create().classNoise*numLabeled);
                a(inds(1:numNoisy)) = 0;
            else
                numLabeled = size(Y,1);
                                
                %I think this is the correct problem to solve
                A = (1-pc.alpha)*A;
                ny = numLabeled*numLabels;
                warning off
                cvx_begin quiet
                    variable a(numLabeled)
                    variable aDup(numLabeled,numLabels)                                        
                    minimize((1/numLabels)*norm(vec((A*Yfull-Y).*aDup),2) + reg*norm(a-1,1))
                    subject to
                        aDup == repmat(a,1,numLabels)
                        a >= 0
                        a <= 1
                cvx_end  
                (1/ny)*norm(vec(A*(Yfull.*repmat(a,1,numLabels))-Y),1) 
                reg*norm(a-1,1)
                reg
                warning on   
            end
        end
        
        function [nameParams] = getNameParams(obj)
            %nameParams = {'sigma','sigmaScale','k','alpha'};
            nameParams = {'dataSetWeights','noise','oracle','unweighted','sort'};
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'LLGC-Weighted';
        end
    end
    
end

