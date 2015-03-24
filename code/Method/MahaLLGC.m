classdef MahaLLGC < LLGCMethod
    %MAHALLGC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = MahaLLGC(configs)
            obj = obj@LLGCMethod(configs);
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            train = input.train;
            test = input.test;
            X = [train.X ; test.X];
            y = [train.Y ; -1*ones(size(test.Y))];
            trueY = [train.trueY ; test.trueY];
            type = [train.type ; test.type];
            isLabeled = y > 0;
            isTrain = type == Constants.TARGET_TRAIN;
            X = zscore(X);
            %X = X(:,1:2);
            yBinary = y;
            yBinary(y > 1) = -1;
            yBinary(y==-1) = 0;
            y = Helpers.createLabelMatrix(y);
            alpha = 1;
            reg = 1e-7;
            %t = .1;
            sigmaScale = obj.get('sigmaScale');
            W = Helpers.CreateDistanceMatrix(X);
            sigmaNormal = sigmaScale*mean(W(:));
            %sigma = -2/(sigmaNormal^2);
            sigma = -1;
            %sigma = sigma*1;
            %sigma = -1;
            %V0 = ones(size(X,2),1) ./ sigma;
            bVal = 1;
            V0 = ones(size(X,2),1);
            %V0 = V0 / (bVal*sum(V0));
            V = V0;                        
            fx = [];  
            trainPerf = [];
            testPerf = [];
            diff = [];
            
            isLabeledTrain = find(isLabeled & isTrain);
            
            split = DataSet.generateSplit([.8 .2], trueY(isLabeledTrain),Configs());
            splitTrain = split == 1;
            splitTest = split == 2;            
            
            useSameY = 0;
            yTrain = yBinary;  
            if useSameY
                yTest = yBinary;
                %yTest(isTrain) = 0;
                %yTest(yTest == 0) = [];                                                
                %S = obj.makeSelectionMatrix(~isTrain);
                S = eye(size(yTest,1));
            else
                yTrain(isLabeledTrain(splitTest)) = 0;
                yTest = trueY;
                yTest(trueY > 1) = -1;
                yTest(trueY == -1) = 0;
                yTest = yTest(isLabeledTrain(splitTest));
                
                I = zeros(size(trueY));
                I(isLabeledTrain(splitTest)) = 1;
                S = obj.makeSelectionMatrix(I);
            end
            
                    
            
            
            i = 1;
            fu = obj.runLLGC(X,V,yTrain,alpha,sigma);
            fuPre = fu;
            yScale = mean(abs(fu));
            %yScale = 1;
            yTrain = yScale*yTrain;
            yTest = yScale*yTest;
            Ypred = LLGC.getPrediction(fu,train.classes);
            accVec = trueY == Ypred;
            trainPerf(i) = mean(accVec(isLabeled));
            testPerf(i) = mean(accVec(~isTrain));
            cvPerf(i) = mean(accVec(isLabeledTrain(splitTest)));
            fx(i) = obj.evaluate(X,V,V0,yTrain,alpha,reg,S,yTest,sigma);
            regs = fliplr([1e-8 1e-6 1e-4 1e-2 1 1e2 1e4]);
            
            %UB = -1e-6*ones(size(V0,1),1);
            LB = 0*ones(size(V0));
            %UB = 1*ones(size(V0));
            UB = [];
            Aeq = [];
            Beq = [];
            %A = ones(1,size(V,1));
            %B = bVal;
            A = [];
            B = [];
            options = optimset('GradObj','on','Algorithm','interior-point');
            regPerf = zeros(size(regs));
            for regIdx=1:length(regs)
                reg = regs(regIdx);                
                func = makeOptimHandle(obj,X,V0,yTrain,alpha,reg,S,yTest,sigma);
                tic
                [V,g] = fmincon(func,V0,A,B,Aeq,Beq,LB,UB,[],options);
                toc
                fu = obj.runLLGC(X,V,yTrain,alpha,sigma);
                Ypred = LLGC.getPrediction(fu,train.classes);
                accVec = trueY == Ypred;
                
                regPerf(regIdx) = regPerf(regIdx) + mean(accVec(isLabeledTrain(splitTest)));
                display([num2str(regs(regIdx)) ': ' num2str(regPerf(regIdx))]);
                %{
                    i = 2;
                    trainPerf(i) = mean(accVec(isLabeled));
                    testPerf(i) = mean(accVec(~isTrain));
                    cvPerf(i) = mean(accVec(isLabeledTrain(splitTest)));
                    fx(i) = obj.evaluate(X,V,V0,yTrain,alpha,reg,S,yTest,sigma);
                %}
            end
            reg = regs(argmax(regPerf));
            display(['Best reg: ' num2str(reg)]);
            func = makeOptimHandle(obj,X,V0,yTrain,alpha,reg,S,yTest,sigma);
            tic
            [V,g] = fmincon(func,V0,A,B,Aeq,Beq,LB,UB,[],options);
            toc
            
            fu = obj.runLLGC(X,V,yTrain,alpha,sigma);
            Ypred = LLGC.getPrediction(fu,train.classes);
            accVec = trueY == Ypred;
            
            i = 2;
            trainPerf(i) = mean(accVec(isLabeled));
            testPerf(i) = mean(accVec(~isTrain));
            cvPerf(i) = mean(accVec(isLabeledTrain(splitTest)));
            fx(i) = obj.evaluate(X,V,V0,yTrain,alpha,reg,S,yTest,sigma);
            
            
            vals = [V V0 V*sigma V0*sigma];
            perf = [trainPerf' cvPerf' testPerf'];
            yScales = [yScale mean(abs(fu))];
            vals
            perf            
            fx
            yScales
            
            testResults = FoldResults();
            testResults.dataFU = sparse(fu);
            testResults.yPred = Ypred;
            testResults.yActual = trueY;
            testResults.dataType = type;
            testResults.learnerMetadata.reg = reg;
            testResults.learnerMetadata.useSameY = useSameY;
            testResults.learnerMetadata.alpha = alpha;
            testResults.learnerMetadata.V0 = V0;
            
            testResults.learnerStats = struct();
            testResults.learnerStats.V = V;
            testResults.learnerStats.trainPerf = trainPerf;
            testResults.learnerStats.testPerf = testPerf;
            testResults.learnerStats.cvPerf = cvPerf;
        end
        
        function [S] = makeSelectionMatrix(obj,I)
            S = zeros(sum(I),length(I));
            inds = find(I);
            for idx=1:length(inds)
                S(idx,inds(idx)) = 1;
            end
        end
        
        function [fu] = runLLGC(obj, X, V, y, alpha,sigma)
            W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));
            W = exp(W*sigma);
            fu = LLGC.llgc_inv(W,y,alpha);
        end
        
        function [fx] = evaluate(obj, X, V, V0, y, alpha, reg, S, yTest,sigma)
            W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));
            Worig = W;
            W = exp(W*sigma);
            D = diag(sum(W,2));
            L = (1+alpha)*D - W;
            invL = inv(L);
            %fx = norm(alpha*invL*y - y)^2 + reg*norm(V - V0)^2;
            fx = norm(alpha*S*invL*y - yTest)^2 + reg*norm(V - V0)^2;
        end
        
        function [g] = gradient(obj, X, V, V0, y, alpha, reg, S, yTest,sigma)
            assert(size(V,2) == 1);
            assert(size(V0,2) == 1);
            W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));
            W = exp(W*sigma);
            D = diag(sum(W,2));
            L = (1+alpha) * D - W;
            invL = inv(L);
            invL2 = invL*invL;
            g = zeros(size(V,1),1);
            S2 = sparse(S'*S);
            for i=1:size(V,1)
                Xi = X(:,i);
                Wi = sigma*Helpers.CreateDistanceMatrixMahabolis(Xi,1);                
                dW_Vii = W .* Wi;
                
                t = 1;
                %{
                fW = y'*W*y;
                gW_Vii = y'*dW_Vii*y;
                V2 = V;
                V2(i,i) = V2(i,i) - t*gW_Vii;                
                W2 = Helpers.CreateDistanceMatrixMahabolis(X,V2);
                W2 = exp(W2);
                fW2 = y'*W2*y;
                display([num2str(fW) ' ' num2str(fW2)]);
                %}
                
                dD_Vii = diag(sum(dW_Vii));
                dL_Vii = (1+alpha)*dD_Vii - dW_Vii;
                %{
                fL = y'*L*y;
                gL_Vii = y'*dL_Vii*y;
                V3 = V;
                V3(i,i) = V3(i,i) - t*gL_Vii;
                W3 = Helpers.CreateDistanceMatrixMahabolis(X,V3);
                W3 = exp(W3);
                D3 = diag(sum(W3,2));
                L3 = (1+alpha)*D3 - W3;
                fL2 = y'*L3*y;                
                display([num2str(fL) ' ' num2str(fL2)]);
                %}
                
                %{
                f1 = y'*invL*y;
                g = -2*y'*invL*dL_Vii*invL*y;
                V2 = V;
                V2(i,i) = V2(i,i) - t*g;
                W2 = Helpers.CreateDistanceMatrixMahabolis(X,V2);
                W2 = exp(W2);
                L2 = (1+alpha)*diag(sum(W2)) - W2;
                f2 = y'*inv(L2)*y;
                display([num2str(f1) ' ' num2str(f2)]);
                %}
                
                %{
                f1 = y'*invL*invL*y;
                g = -y'*(invL2*dL_Vii*invL + invL*dL_Vii*invL2)*y;
                V2 = V;
                V2(i,i) = V2(i,i) - t*g;
                W2 = Helpers.CreateDistanceMatrixMahabolis(X,V2);
                W2 = exp(W2);
                L2 = (1+alpha)*diag(sum(W2)) - W2;
                invL_2 = inv(L2);
                f2 = y'*invL_2*invL_2*y;
                display([num2str(f1) ' ' num2str(f2)]);
                %}
                
                Vii_diff = 2 * (V(i)-V0(i));
                
                g1 = -alpha^2 * y' * (invL2*dL_Vii*S'*S*invL + invL*S'*S*dL_Vii*invL2) * y;
                g2 = 2*alpha*yTest'*S*invL*dL_Vii*invL*y;
                %g3 = 2*reg*Vii_diff;
                g3 = 2*reg*V(i);
                g(i) = g1 + g2 + g3;
                
                %f1 = y'*(invL2 + invL)*y
                %{
                g(i) = -alpha^2 * y' * (invL2*dL_Vii*invL + invL*dL_Vii*invL2) * y  ...
                    - 2*alpha*y'*invL*dL_Vii*invL*y  ...
                    + 2*reg*Vii_diff;
                %}
            end
            %g = diag(g);
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'MahaLLGC';
        end
        function [nameParams] = getNameParams(obj)
            %nameParams = {'sigma','sigmaScale','k','alpha'};            
            nameParams = {'sigmaScale'};
            if length(obj.get('alpha')) == 1
                nameParams{end+1} = 'alpha';
            end
        end
    end
    
end

