classdef LLGCWeightedMethod < LLGCMethod
    %LLGCWEIGHTED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LLGCWeightedMethod(configs)
            obj = obj@LLGCMethod(configs);
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
                %[distMat] = createDistanceMatrix(obj,train,test,useHF,learner.configs);
                [distMat] = createDistanceMatrix(obj,train,test,useHF,obj.configs);
                testResults.dataType = distMat.type;
            end
            [Wrbf,YtrainMat,sigma,Y_testCleared] = makeLLGCMatrices(obj,distMat);
            
            %{
            Y_testClearedPerm = Y_testCleared;
            labels = ProjectConfigs.labelsToUse;            
            for i=labels
                isLabeled = find(Y_testCleared == i);
                isLabeledPerm = isLabeled(randperm(length(isLabeled)));
                newClass = labels(labels ~= i);
                numToPerm = floor(length(isLabeledPerm)*ProjectConfigs.classNoise);
                Y_testClearedPerm(isLabeledPerm(1:numToPerm)) = newClass;
            end
            Y_testCleared = Y_testClearedPerm;
            YtrainMat = Helpers.createLabelMatrix(Y_testCleared);
            %}
            Wrbf(logical(speye(size(Wrbf)))) = 0;
            Disq = diag(sum(Wrbf).^-.5);
            WN = Disq*Wrbf*Disq;
            alpha = ProjectConfigs.alpha;                                
            I = eye(size(WN,1));
            M = (1/(1-alpha))*(I-alpha*WN);
            distMatRBF = DistanceMatrix(M,Y_testCleared,distMat.type);
            numFolds = 10;
            label1 = ProjectConfigs.labelsToUse(1);
            label2 = ProjectConfigs.labelsToUse(2);
            originalLabels = ProjectConfigs.labelsToUse;
            for i=1:numFolds
                regParms = [.1 .001 .0001 .00001];
                split = distMatRBF.generateSplitArray(.8,.2);
                hasLabel = sum(YtrainMat > 0,2) > 0;
                %hasLabelMat = repmat(hasLabel,1,size(YtrainMat,2));
                n = length(hasLabel);
                                                   
                YtrainMatCurr = YtrainMat;
                YtrainMatCurr(split==2,:) = 0;
                Y_testClearedCurr = Y_testCleared;
                Y_testClearedCurr(split==2) = -1;
                
                reg = ProjectConfigs.reg;
                if length(originalLabels) == 2 && false
                    Y = YtrainMatCurr(:,label1);
                    Y(YtrainMatCurr(:,label2) > 0) = -1;                
                    labels = [-1 1];
                    Yperm = Y;

                    for j=labels
                        isLabeled = find(Y == j);
                        isLabeledPerm = isLabeled(randperm(length(isLabeled)));
                        newClass = labels(labels ~= j);
                        numToPerm = floor(length(isLabeledPerm)*ProjectConfigs.classNoise);
                        Yperm(isLabeledPerm(1:numToPerm)) = newClass;
                    end
                    Y = Yperm;                
                    DY = diag(Y);

                    hasLabel = Y ~= 0;
                    Ysub = Y(hasLabel);
                    DYsub = DY(hasLabel,hasLabel);
                    Msub = M(hasLabel,hasLabel);

                    numLabels = sum(hasLabel);
                    A = Msub*DYsub;
                    warning off
                    cvx_begin quiet
                        %variable a(n)
                        %minimize(norm((M*YtrainMat*a-Yvec).*hasLabelMat,'fro') + .01*norm(a-1))
                        variable a(numLabels)
                        %minimize(norm(A*a-Ysub,'fro') + reg*norm(a-1))
                        minimize(norm(A*a-Ysub,2) + reg*norm(a-1))
                        subject to
                            a >= 0
                    cvx_end  
                    warning on                    
                    %{
                    a_ls = lsqnonneg(A,Ysub);
                    H = A'*A;
                    H = H + reg*eye(size(H));
                    c = -A'*Ysub;
                    a_ls_reg = quadprog(H,c,[],[],[],[],0,[]);
                    [a a_ls a_ls_reg]
                    %}

                    aAll = zeros(n,1);
                    aAll(hasLabel) = a;

                    %{
                    Y1 = M\YtrainMat;
                    Y2 = M\(YtrainMat.*repmat(aAll,1,size(YtrainMat,2)));
                    [~,Y1pred] = max(Y1,[],2);
                    [~,Y2pred] = max(Y2,[],2);
                    %}
                    Ypred = M\(Y.*aAll);
                    Y1 = sign(Ypred);
                    Y1(Ypred==1) = label1;
                    Y1(Ypred==-1) = label2;

                    YpredNormal = M\(Y);
                    Y2 = sign(YpredNormal);
                    Y2(YpredNormal==1) = label1;
                    Y2(YpredNormal==-1) = label2;
                else
                    hasLabel = Y_testClearedCurr > 0;
                                        
                    Msub = M(hasLabel,hasLabel);
                    
                    YvecPerm = Y_testClearedCurr;
                    isNoisy = false(length(Y_testClearedCurr),1);
                    for j=originalLabels
                        isLabeled = find(Y_testClearedCurr == j);
                        isLabeledPerm = isLabeled(randperm(length(isLabeled)));
                        %newClass = labels(labels ~= j);
                        newClass = datasample(originalLabels,1);
                        numToPerm = floor(length(isLabeledPerm)*ProjectConfigs.classNoise);
                        YvecPerm(isLabeledPerm(1:numToPerm)) = newClass;
                        isNoisy(isLabeledPerm(1:numToPerm)) = true;
                    end
                    Y_testClearedCurr = YvecPerm;
                    YtrainMatCurr = Helpers.createLabelMatrix(Y_testClearedCurr);
                    Y = YtrainMatCurr;
                    Ysub = Y(hasLabel,:);
                    
                    numLabeled = sum(hasLabel);
                    numLabels = size(Ysub,2);
                    A = Msub*Ysub;
                    
                    warning off
                    cvx_begin quiet
                        %variable a(n)
                        %minimize(norm((M*YtrainMat*a-Yvec).*hasLabelMat,'fro') + .01*norm(a-1))
                        variable a(numLabeled)
                        %minimize(norm(A*a-Ysub,'fro') + reg*norm(a-1))
                        minimize(norm(vec(A.*repmat(a,1,numLabels)-Ysub),1) + reg*norm(a-1,1))
                        %minimize(norm(vec(A.*repmat(a,1,numLabels)-Ysub),'fro') + reg*norm(a-1,1))
                        subject to
                            a >= 0
                    cvx_end  
                    warning on  
                                        
                    
                    aAll = zeros(size(M,1),1);
                    aAll(hasLabel) = a;
                    aAll = repmat(aAll,1,numLabels);
                    
                    [a aAll(hasLabel) isNoisy(hasLabel)]
                    
                    Ypred = M\(YtrainMatCurr.*aAll);
                    [~,Y1] = max(Ypred,[],2);

                    YpredNormal = M\(YtrainMatCurr);
                    [~,Y2] = max(YpredNormal,[],2);
                    
                    aAllBest = zeros(size(M,1),1);
                    aAllBest(hasLabel) = 1;
                    aAllBest(isNoisy) = 0;
                    aAllBest = repmat(aAllBest,1,numLabels);
                    
                    yPredBest = M\(YtrainMatCurr.*aAllBest);
                    [~,YBest] = max(yPredBest,[],2);
                end
                

                
                
                Yactual = distMat.Y;
                percSame = sum(Y1==Y2)/length(Y1);
                isLabeledTest = Y_testCleared > 0 & split == 2;
                display(['Percent identical: ' num2str(percSame)]);
                display(['Num different: ' num2str(sum(Y1 ~= Y2))]);
                acc = sum(Yactual(isLabeledTest) == Y1(isLabeledTest))/sum(isLabeledTest);
                accNormal = sum(Yactual(isLabeledTest) == Y2(isLabeledTest))/sum(isLabeledTest);
                display(['Accuracy: ' num2str(acc)]);
                display(['Accuracy Normal: ' num2str(accNormal)]);                
                accBest = sum(Yactual(isLabeledTest) == YBest(isLabeledTest))/sum(isLabeledTest);
                display(['Accuracy Best: ' num2str(accBest)]);
            end
            %{
            m = 16; n = 8;
            A = randn(m,n);
            b = randn(m,1);

            x_ls = A \ b;
            cvx_begin
                variable x(n)
                minimize( norm(A*x-b) )
            cvx_end
            %}
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'LLGC-Weighted';
        end
    end
    
end

