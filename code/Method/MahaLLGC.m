classdef MahaLLGC < LLGCMethod
    %MAHALLGC Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = MahaLLGC(configs)
            obj = obj@LLGCMethod(configs);
            if ~obj.has('useLOO')
                obj.set('useLOO',1);
            end
            if ~obj.has('useAlt')
                obj.set('useAlt',1);
            end
            if ~obj.has('useL1')
                obj.set('useL1',0);
            end
            if ~obj.has('smallTol')
                obj.set('smallTol',1);
            end
            if ~obj.has('redoLLGC')
                obj.set('redoLLGC',0);
            end
            obj.set('useAlt',1);
            obj.set('useGrad',1);
        end
        
        function [V,F] = solveForV(obj,X,V0,Y,F,reg,sigma,alpha,useL1,distMats,trueY)
            llgcMethod = LLGCMethod(obj.configs);
            llgcMethod.set('alpha',alpha);
            llgcMethod.set('sigma',sigma);
            useHF = false;
            makeRBF = false;
            maxIters = 10;
            useHessian = 0;
            V = V0;
            V2 = V0;
            numIters = 0;            
            
            %{
            alpha = 1;
            f = zeros(size(V));
            fy = f;
            meanDist = f;
            %sigma = sigma/1000;
            accVec = f;
            trueYBinary = Helpers.MakeLabelsBinary(trueY);
            for i=1:size(X,2)
                currV = zeros(size(V));
                currV(i) = 1;
                currF = obj.runLLGC(X,currV,Y,alpha,sigma);
                accVec(i) = mean(sign(currF) == trueYBinary);
                %currF = F;
                currF = sign(currF);
                currY = Y;
                %currY(Y == 0) = currF(Y == 0);
                f(i) = obj.evaluate_alt(X,currV,V0,currY,currF,reg,sigma,alpha);
                fy(i) = obj.evaluate_alt(X,currV,V0,currY,currY,reg,sigma,alpha);
                Wi = Helpers.CreateDistanceMatrixMahabolis(X,diag(currV));
                meanDist(i) = mean(Wi(:));
            end
            a = [f fy 10000000*accVec 100000*(1:length(f))'];
            a
            %}
            useGrad = obj.get('useGrad');
            while true
                Vold = V;
                %[F,savedData,sigma] = llgcMethod.runLLGC(distMat,makeRBF,struct());
                
                
                %yTrain = mean(abs(F))*yTrain;
                
                tic
                A = []; B = []; Aeq = []; Beq = [];
                func = makeOptimHandle_alt(obj,X,V0,Y,F,reg,sigma,alpha,distMats,useGrad);
                hessianFunc = makeHessianHandle_alt(obj,X,V0,Y,F,reg,sigma,alpha);
                if useL1
                    %l2Reg = 1e-6;
                    l2Reg = 0;
                    func = makeOptimHandle_alt(obj,X,V0,Y,F,l2Reg,sigma,alpha,distMats,useGrad);
                    hessianFunc = makeHessianHandle_alt(obj,X,V0,Y,F,l2Reg,sigma,alpha);
                    A = ones(1,length(V));
                    B = reg;
                end
                LB = zeros(size(V)); UB = [];
                tolFun = 1e-6;
                tolX = 1e-10;
                if obj.get('smallTol')
                    tolFun = 1e-6;
                    tolX = 1e-5;
                end
                if useHessian
                    options = optimset('GradObj','on',...
                        'Algorithm','interior-point',...
                        'Hessian','user-supplied',...
                        'HessFcn',hessianFunc,...
                        'TolFun',tolFun,...
                        'TolX',tolX);
                else
                    %{
                    options = optimset('GradObj','on','Algorithm','interior-point',...
                        'Display', 'off','TolFun',tolFun,...
                        'TolX',tolX,...
                        'DerivativeCheck','on');
                    %}                    
                    if useGrad
                        options = optimset('GradObj','on','Algorithm','interior-point',...
                            'Display', 'off','TolFun',tolFun,...
                            'TolX',tolX);
                    else
                        options = optimset('Algorithm','interior-point',...
                            'Display', 'off','TolFun',tolFun,...
                            'TolX',tolX);
                    end
                end
                [V,fx,exitflag,output,lambda,grad] = fmincon(func,V,A,B,Aeq,Beq,LB,UB,[],options);
                toc
                %{
                options = optimset('GradObj','on','Algorithm','interior-point',...
                    'Display', 'off','TolX',1e-10,'TolFun',1e-6);
                tic
                [V2,fx,exitflag,output,lambda,grad] = fmincon(func,V2,A,B,Aeq,Beq,LB,UB,[],options);
                toc
                %}
                %{
                options = optimset('GradObj','on','Algorithm','interior-point',...
                    'Display', 'off','TolFun',1e-6);
                tic
                [V2,fx,exitflag,output,lambda,grad] = fmincon(func,V2,A,B,Aeq,Beq,LB,UB,[],options);
                toc
                %}
                F = obj.runLLGC(X,V,Y,alpha,sigma);
                %display(norm(Vold-V));
                numIters = numIters + 1;
                if norm(Vold - V)/norm(V) < 1e-4
                    display(['Converged: ' num2str(norm(Vold-V)) ]);
                    break;
                end
                if numIters >= maxIters
                    display('Stopping - Max Iterations exceeded...');
                    break;
                end
            end                                              
            %[V V2]
            %V
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            train = input.train;
            test = input.test;
            useHF = false;
            makeRBF = false;            
            V0 = ones(size(train.X,2),1);
            V = V0;
            if obj.get('useAlt')                

                %reg = 1e-3;
                 
                regs = fliplr(10.^(-8:1:4));
                %regs = fliplr(10.^(-8:2:4));
                if obj.get('useL1')
                    %regs = fliplr(regs);
                    regs = 10.^(-8:4);
                end
                %regs = fliplr(10.^(-8:-4));
                cvPerf = zeros(size(regs));
                testPerf = cvPerf;
                trainPerf = cvPerf;
                numFolds = 10;
                
                for foldIdx=1:numFolds
                    llgcMethod = LLGCMethod(obj.configs);
                    [distMat,~,X] = llgcMethod.createDistanceMatrix(train,test,...
                        useHF,obj.configs,makeRBF,struct(),diag(V));
                    
                    classes = distMat.classes;                    
                    distMat.Y(distMat.isTargetTest()) = -1;
                    labeledInds = find(distMat.isLabeled());
                    split = DataSet.generateSplit([.8 .2],distMat.Y(labeledInds),Configs());                    
                    splitTrain = split == 1;
                    splitTest = split == 2;
                    Y = Helpers.MakeLabelsBinary(distMat.Y);
                    YOrig = Y;
                    Y(labeledInds(splitTest)) = 0;                    
                    
                    distMats = cell(size(V,1),1);
                    for featIdx=1:length(V)
                        distMats{featIdx} = Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),1);
                    end
                    
                    for regIdx=1:length(regs) 
                        reg = regs(regIdx);
                        alpha = 1;
                        sigma = -1/(2);
                        distMat.W = exp(sigma*distMat.W);
                        F = LLGC.llgc_LS(distMat.W,Y,alpha);                                                
                        
                        useL1 = obj.get('useL1');
                        [V,F] = obj.solveForV(X,V0,Y,F,reg,sigma,alpha,useL1,distMats,distMat.trueY);
                        %V
                        if obj.get('redoLLGC')                            
                            [sorted,I] = sort(V,'descend');
                            percVals = cumsum(sorted) ./ sum(sorted);
                            
                            maxPercToUse = .9;
                            toUse = [];
                            for featIdx=1:length(V)
                                 if featIdx == 1 || percVals(featIdx-1) <= maxPercToUse
                                    toUse(end+1) = I(featIdx);
                                 else
                                     break;
                                 end
                            end
                            assert(length(toUse) >= 1);
                            %V = zeros(size(V));
                            %V(toUse) = 1;
                            %V = ones(size(V));
                            %F = obj.runLLGC(X,V,Y,alpha,sigma);
                            [Vnew,F] = obj.solveForV(X(:,toUse),V0(toUse),Y,F,1e-6,sigma,alpha,false,distMats(toUse));
                            V = zeros(size(V));
                            V(toUse) = Vnew;
                        end
                        yPred = LLGC.getPrediction(F,classes);
                        accVec = yPred == distMat.trueY;
                        testPerf(regIdx) = testPerf(regIdx) + mean(accVec(distMat.isTargetTest()));
                        trainPerf(regIdx) = trainPerf(regIdx) + mean(accVec(labeledInds(splitTrain)));
                        cvPerf(regIdx) = cvPerf(regIdx) + mean(accVec(labeledInds(splitTest)));
                        %[V./ max(V) (1:length(V))']
                    end
                end
                cvPerf = cvPerf / numFolds;
                testPerf = testPerf / numFolds;
                trainPerf = trainPerf / numFolds;
                
                useSameY = -1;
                reg = argmax(cvPerf);
                func = makeOptimHandle_alt(obj,X,V0,Y,F,reg,sigma,alpha);
                [V,fx,exitflag,output,lambda,grad] = fmincon(func,V0,A,B,Aeq,Beq,LB,UB,[],options);
                fu = obj.runLLGC(X,V,YOrig,alpha,sigma);
                Ypred = LLGC.getPrediction(fu,classes);
                type = distMat.type;
                trueY = distMat.trueY;
                                
            else
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
                        
                fx = [];  
                trainPerf = [];
                testPerf = [];
                diff = [];

                %regs = fliplr([1e-8 1e-6 1e-4 1e-2 1 1e2 1e4]);
                regs = fliplr(10.^(-8:4));
                %regs = 10.^(-8:4);
                cvPerf = zeros(size(regs));

                isLabeledTrain = find(isLabeled & isTrain);
                numFolds = 10;
                for foldIdx=1:numFolds
                    split = DataSet.generateSplit([.8 .2], trueY(isLabeledTrain),Configs());
                    splitTrain = split == 1;
                    splitTest = split == 2;            

                    useSameY = 1;
                    yTrain = yBinary;  
                    if useSameY                    
                        yTrain(isLabeledTrain(splitTest)) = 0;
                        yTest = yTrain(isLabeledTrain(splitTrain));    
                        I = zeros(size(trueY));
                        I(isLabeledTrain(splitTrain)) = 1;
                        %S = eye(size(yTest,1));
                        S = obj.makeSelectionMatrix(I);
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

                    fu = obj.runLLGC(X,V,yTrain,alpha,sigma);
                    yScale = mean(abs(fu));
                    %yScale = 1;
                    yTrain = yScale*yTrain;
                    yTest = yScale*yTest;                                                

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
                    for regIdx=1:length(regs)
                        reg = regs(regIdx);                
                        func = makeOptimHandle(obj,X,V0,yTrain,alpha,reg,S,yTest,sigma);
                        tic
                        [V,g] = fmincon(func,V0,A,B,Aeq,Beq,LB,UB,[],options);
                        toc
                        fu = obj.runLLGC(X,V,yTrain,alpha,sigma);
                        Ypred = LLGC.getPrediction(fu,train.classes);
                        accVec = trueY == Ypred;

                        trainAcc = mean(accVec(isLabeledTrain(splitTrain)));
                        testAcc = mean(accVec(~isTrain));
                        cvPerf(regIdx) = cvPerf(regIdx) + mean(accVec(isLabeledTrain(splitTest)));
                        %display([num2str(regs(regIdx)) ': ' num2str(regPerf(regIdx))]);
                        %{
                            i = 2;
                            trainPerf(i) = mean(accVec(isLabeled));
                            testPerf(i) = mean(accVec(~isTrain));
                            cvPerf(i) = mean(accVec(isLabeledTrain(splitTest)));
                            fx(i) = obj.evaluate(X,V,V0,yTrain,alpha,reg,S,yTest,sigma);
                        %}
                    end
                end
                cvPerf = cvPerf ./ numFolds;
                reg = regs(argmax(cvPerf));
                display(['Best reg: ' num2str(reg)]);

                if obj.get('useLOO')
                    yTrain = zeros(size(yBinary));
                    yTrain(isLabeledTrain) = yBinary(isLabeledTrain);
                end

                i = 1;
                fu = obj.runLLGC(X,V,yTrain,alpha,sigma);
                Ypred = LLGC.getPrediction(fu,train.classes);
                accVec = trueY == Ypred;            
                trainPerf(i) = mean(accVec(isLabeled));
                testPerf(i) = mean(accVec(~isTrain));
                cvPerf(i) = mean(accVec(isLabeledTrain(splitTest)));
                fx(i) = obj.evaluate(X,V,V0,yTrain,alpha,reg,S,yTest,sigma);

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
                %yScales = [yScale mean(abs(fu))];
                vals
                perf            
                fx
                %yScales
            end
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
            %fu = LLGC.llgc_inv(W,y,alpha);
            if obj.get('useAlt') == 2 && false
                fu = LLGC.llgc_inv_alt(W,y,alpha);
            else
                fu = LLGC.llgc_LS(W,y,alpha);
            end
            %fu = sign(fu);
        end
                        
        function [fx,W] = evaluate_alt2(obj,X,V,V0,y,F,reg,sigma,alpha)
            W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));
            W = exp(W*sigma);                
            useNew = 1;
            d = sum(W,2);
            if useNew
                L = -W;
                n = size(W,1);
                I = spdiags(true(n,1),0,n,n);
                %L(I) = L(I) + d*(1+alpha);
                L(I) = L(I) + d;
                D = spdiags(d,0,n,n);
            else
                D = diag(d);
                %L = (1+alpha)*D - W;
            end                         
            %fx = F'*L*F + F'*D*F + y'*D*y - 2*F'*W*y + alpha*norm(F-y)^2 + reg*norm(V)^2;
            %fx = F'*L*F + alpha*(F'*D*F + y'*D*y - 2*F'*W*y) + reg*norm(V)^2;
            %fx = F'*L*F + y'*L*y + alpha*norm(F-y)^2 + reg*norm(V)^2;
            %fx = y'*L*y + reg*norm(V)^2;
            isLabeled = y ~= 0;
            Wll = W(isLabeled,isLabeled);
            Yl = y(isLabeled);
            Dl = diag(sum(Wll,2));
            Ll = Dl-Wll;
            %fx = Yl'*Ll*Yl + reg*norm(V)^2;
            fx = norm(inv(Dl)*Wll*Yl - Yl)^2 + reg*norm(V)^2;
        end
        
         function [g] = gradient_alt2(obj,X,V,V0,y,F,reg,sigma,alpha,distMats,W)
            %{
            distMats = cell(size(V));
            for i=1:length(V)
                distMats{i} = sigma*Helpers.CreateDistanceMatrixMahabolis(X(:,i),1);
            end
            %}
            useDistMats = true;
            if ~exist('W','var')
                W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));
                W = exp(W*sigma);
            end
            %This saves needing to multiple by sigma each iteration
            W = W*sigma;
            n = size(W,1);
            I = spdiags(true(n,1),0,n,n);
            for featIdx=1:length(V)
                %W_Vi = W .* Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),V(featIdx));
                if useDistMats && ~isempty(distMats)
                    W_Vi = W .* distMats{featIdx};
                    %W_Vi2 = W .* Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),1);
                    %assert(all(W_Vi(:) == W_Vi2(:)));
                else
                    W_Vi = W .* Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),1);
                end
                %W_Vi = W .* distMats{featIdx};
                
                %W_Vi = W_Vi * sigma;
                %d = (1+alpha)*sum(W_Vi,2);
                d = sum(W_Vi,2);
                %D = diag(d);
                %L = D - W_Vi;
                L = -W_Vi;
                L(I) = L(I) + d;
                n = length(d);
                D = spdiags(d,0,n,n);
                %g(featIdx) = F'*L*F + F'*L*y + 2*reg*V(featIdx);
                %g(featIdx) = F'*L*F + F'*D*F + y'*D*y - 2*F'*W*y + 2*reg*V(featIdx);
                g(featIdx) = F'*L*F + y'*L*y + 2*reg*V(featIdx);
            end
        end
        
        function [fx,W] = evaluate_alt(obj,X,V,V0,y,F,reg,sigma,alpha)
            W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));
            W = exp(W*sigma);                
            useNew = 1;
            d = sum(W,2);
            if useNew
                L = -W;
                n = size(W,1);
                I = spdiags(true(n,1),0,n,n);
                %L(I) = L(I) + d*(1+alpha);
                L(I) = L(I) + d;
            else
                D = diag(d);
                L = (1+alpha)*D - W;
            end               
            fx = F'*L*F + alpha*norm(F-y)^2 + reg*norm(V)^2;            
        end
        
        function [g] = gradient_alt(obj,X,V,V0,y,F,reg,sigma,alpha,distMats,W)
            %{
            distMats = cell(size(V));
            for i=1:length(V)
                distMats{i} = sigma*Helpers.CreateDistanceMatrixMahabolis(X(:,i),1);
            end
            %}
            useDistMats = true;
            if ~exist('W','var')
                W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));
                W = exp(W*sigma);
            end
            %This saves needing to multiple by sigma each iteration
            W = W*sigma;
            n = size(W,1);
            I = spdiags(true(n,1),0,n,n);
            for featIdx=1:length(V)
                %W_Vi = W .* Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),V(featIdx));
                if useDistMats && ~isempty(distMats)
                    W_Vi = W .* distMats{featIdx};
                    %W_Vi2 = W .* Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),1);
                    %assert(all(W_Vi(:) == W_Vi2(:)));
                else
                    W_Vi = W .* Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),1);
                end
                %W_Vi = W .* distMats{featIdx};
                
                %W_Vi = W_Vi * sigma;
                %d = (1+alpha)*sum(W_Vi,2);
                d = sum(W_Vi,2);
                %D = diag(d);
                %L = D - W_Vi;
                L = -W_Vi;
                L(I) = L(I) + d;
                g(featIdx) = F'*L*F + 2*reg*V(featIdx);
            end
        end
        
        function [H] = hessian_alt(obj,X,V,V0,y,F,reg,sigma,alpha)
            H = zeros(length(V));
            W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));
            W = exp(W*sigma);
            
            distMats = cell(size(V));
            for i=1:length(V)
                distMats{i} = Helpers.CreateDistanceMatrixMahabolis(X(:,i),V(i));
            end
            for i=1:length(V)
                for j=1:length(V)
                    W_Vij = W.*distMats{i}.*distMats{j}*(sigma^2);
                    D = diag(sum(W_Vij,2));
                    L = (1+alpha)*D - W_Vij;
                    H(i,j) = F'*L*F;
                end
            end
        end
        
        function [fx] = evaluate(obj, X, V, V0, y, alpha, reg, S, yTest,sigma)
            W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));
            Worig = W;
            W = exp(W*sigma);
            D = diag(sum(W,2));
            L = (1+alpha)*D - W;
            invL = inv(L);
            %fx = norm(alpha*invL*y - y)^2 + reg*norm(V - V0)^2;
            if obj.get('useLOO')
                fx = 0;
                isLabeled = find(y);
                for idx=isLabeled'
                    yCopy = y;
                    yCopy(idx) = 0;
                    fu = alpha*invL*yCopy;
                    r = norm(fu(idx)- y(idx));
                    fx = fx + r;
                end                
            else
                fx = norm(alpha*S*invL*y - yTest)^2;
            end
            fx = fx +  + reg*norm(V - V0)^2;
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
                %obj.set('useLOO',0);
                if obj.get('useLOO')
                    g1 = 0;
                    g2 = 0;
                    isLabeled = find(y);    
                    M1 = invL2*dL_Vii;
                    M2 = dL_Vii*invL2;
                    M3 = invL*dL_Vii*invL;
                    for idx=isLabeled'
                        yCurr = y;
                        yCurr(idx) = 0;
                        yCurrTest = y(idx);
                        I = zeros(size(yCurr));
                        I(idx) = 1;
                        Scurr = obj.makeSelectionMatrix(I);
                        %g1 = g1 + -alpha^2 * yCurr' * (invL2*dL_Vii*Scurr'*Scurr*invL + invL*Scurr'*Scurr*dL_Vii*invL2) * yCurr;
                        %g2 = g2 + 2*alpha*yCurrTest'*Scurr*invL*dL_Vii*invL*yCurr;
                        M1S = M1(:,idx);
                        SIL = invL(idx,:);
                        SM2 = M2(idx,:);
                        SM3 = M3(idx,:);
                        %{
                        assert(all(M1S == M1*Scurr'));
                        assert(all(SIL == Scurr*invL));
                        assert(all(SM2 == Scurr*M2));
                        assert(all(SM3 == Scurr*M3));
                        %}
                        %g1_ = g1 + -alpha^2 * yCurr' * (M1*Scurr'*Scurr*invL + invL*Scurr'*Scurr*M2) * yCurr;
                        g1 = g1 + -alpha^2 * yCurr' * (M1S*SIL + SIL'*SM2) * yCurr;
                        %assert(g1 == g1_);
                        %g2_ = g2 + 2*alpha*yCurrTest'*Scurr*M3*yCurr;
                        g2 = g2 + 2*alpha*yCurrTest'*SM3*yCurr;
                        %assert(g2 == g2_);
                    end
                else
                    g1 = -alpha^2 * y' * (invL2*dL_Vii*S'*S*invL + invL*S'*S*dL_Vii*invL2) * y;
                    g2 = 2*alpha*yTest'*S*invL*dL_Vii*invL*y;
                end
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
            %{ 
            f1 = obj.evaluate(X, V, V0, y, alpha, reg, S, yTest,sigma);
            V2 = V - 1*g;
            f2 = obj.evaluate(X, V2, V0, y, alpha, reg, S, yTest,sigma);
            %}
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
            if obj.has('useLOO')
                nameParams{end+1} = 'useLOO';
            end
            if obj.has('useAlt')
                nameParams{end+1} = 'useAlt';
            end
            if obj.has('useL1')
                nameParams{end+1} = 'useL1';
            end
            if obj.has('smallTol')
                nameParams{end+1} = 'smallTol';
            end
            if obj.has('redoLLGC') && obj.get('redoLLGC')
                nameParams{end+1} = 'redoLLGC';
            end    
            if obj.has('useGrad') && obj.get('useGrad')
                nameParams{end+1} = 'useGrad';
            end
        end
    end
    
end

