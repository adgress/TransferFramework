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
            
            for i=1:numFolds
                regParms = [.1 .001 .0001 .00001];
                split = distMatRBF.generateSplitArray(.8,.2);
                hasLabel = sum(YtrainMat > 0,2) > 0;
                %hasLabelMat = repmat(hasLabel,1,size(YtrainMat,2));
                n = length(hasLabel);
                                                   
                numLabels = 2;
                YtrainMatCurr = YtrainMat;
                YtrainMatCurr(split==2,:) = 0;
                
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
                reg = .0;
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
                Y1 = Ypred;
                Ypred = sign(Ypred);
                Ypred(Ypred==1) = label1;
                Ypred(Ypred==-1) = label2;
                
                YpredNormal = M\(Y);
                Y2 = YpredNormal;
                YpredNormal = sign(YpredNormal);
                YpredNormal(YpredNormal==1) = label1;
                YpredNormal(YpredNormal==-1) = label2;
                
                Yactual = distMat.Y;
                percSame = sum(Ypred==YpredNormal)/length(Ypred);
                isLabeledTest = Y_testCleared > 0 & split == 2;
                display(['Percent identical: ' num2str(percSame)]);
                display(['Unrounded vec difference: ' num2str(norm(Y1-Y2,1))]);
                acc = sum(Yactual(isLabeledTest) == Ypred(isLabeledTest))/sum(isLabeledTest);
                accNormal = sum(Yactual(isLabeledTest) == YpredNormal(isLabeledTest))/sum(isLabeledTest);
                display(['Accuracy: ' num2str(acc)]);
                display(['Accuracy Normal: ' num2str(accNormal)]);
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

