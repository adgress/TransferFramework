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
                %obj.set('useAlt',2);
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
            obj.set('useAlt',0);
            obj.set('useGrad',1);
            obj.set('gradCheck',0);
            obj.set('gradTest',0);
        end
        
        function [V,F] = solveForV(obj,X,V0,Y,F,reg,sigma,alpha,useL1,distMats,trueY,options)
            llgcMethod = LLGCMethod(obj.configs);
            llgcMethod.set('alpha',alpha);
            llgcMethod.set('sigma',sigma);
            useHF = false;
            makeRBF = false;
            maxIters = 1;
            if obj.get('useAlt') == 1
                maxIters = 30;
            end
            useHessian = 0;
            V = V0;
            V2 = V0;
            numIters = 0;            
  
            tolFun = 1e-6;
            tolX = 1e-10;
            if obj.get('smallTol')
                tolFun = 1e-6;
                tolX = 1e-5;
            end            
            useGrad = obj.get('useGrad');
            while true
                Vold = V;
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
                 
                [V,fx,exitflag,output,lambda,grad] = fmincon(func,V,A,B,Aeq,Beq,LB,UB,[],options);
                toc
                F = obj.runLLGC(X,V,Y,alpha,sigma);
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
            V0 = 1*ones(size(train.X,2),1);            
            %V0 = 0*V0;
            regs = fliplr(10.^(-8:4));
            %regs = 10^3;
            if obj.get('useL1')
                regs = fliplr(regs);
            end
            
            cvPerf = zeros(size(regs));
            testPerf = cvPerf;
            trainPerf = cvPerf;
            numFolds = 1;
            alpha = 1;
            sigma = -1;
            LB = 0*ones(size(V0));
            %V = 100*rand(size(V));
            %V = 10*V;
            UB = [];
            Aeq = [];
            Beq = [];

            A = [];
            B = [];     
            
            tolFun = 1e-6;
            tolX = 1e-10;
            useGrad = obj.get('useGrad');
            if obj.get('smallTol')
                tolFun = 1e-6;
                tolX = 1e-5;
            end
            if useGrad
                if obj.get('gradCheck')                                    
                    options = optimset('GradObj','on','Algorithm','interior-point',...
                        'Display', 'iter-detailed','TolFun',tolFun,...
                        'TolX',tolX,'DerivativeCheck','on');
                else
                    options = optimset('GradObj','on','Algorithm','interior-point',...
                        'Display', 'off','TolFun',tolFun,...
                        'TolX',tolX);
                end
            else
                options = optimset('Algorithm','interior-point',...
                    'Display', 'off','TolFun',tolFun,...
                    'TolX',tolX);
            end
            
            if obj.get('useAlt')
                llgcMethod = LLGCMethod(obj.configs);
                for foldIdx=1:numFolds                    
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
                        distMat.W = exp(sigma*distMat.W);
                        F = LLGC.llgc_LS(distMat.W,Y,alpha);                                                
                        
                        useL1 = obj.get('useL1');
                        [V,F] = obj.solveForV(X,V0,Y,F,reg,sigma,alpha,useL1,distMats,distMat.trueY,options);
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
                            [Vnew,F] = obj.solveForV(X(:,toUse),V0(toUse),Y,F,1e-6,sigma,alpha,false,distMats(toUse),options);
                            V = zeros(size(V));
                            V(toUse) = Vnew;
                        end
                        yPred = LLGC.getPrediction(F,classes);
                        accVec = yPred == distMat.trueY;
                        testPerf(regIdx) = testPerf(regIdx) + mean(accVec(distMat.isTargetTest()));
                        trainPerf(regIdx) = trainPerf(regIdx) + mean(accVec(labeledInds(splitTrain)));
                        cvPerf(regIdx) = cvPerf(regIdx) + mean(accVec(labeledInds(splitTest)));
                        [V./ max(V) (1:length(V))']
                        %[V (1:length(V))']
                    end
                end
                cvPerf = cvPerf / numFolds;
                testPerf = testPerf / numFolds;
                trainPerf = trainPerf / numFolds;
                
                useSameY = -1;
                reg = regs(argmax(cvPerf));

                [distMat,~,X] = llgcMethod.createDistanceMatrix(train,test,...
                    useHF,obj.configs,makeRBF,struct(),diag(V));
                distMats = cell(size(V,1),1);
                for featIdx=1:length(V)
                    distMats{featIdx} = Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),1);
                end
                [V,F] = obj.solveForV(X,V0,Y,F,reg,sigma,alpha,useL1,distMats,distMat.trueY,options);
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
                yBinary = Helpers.MakeLabelsBinary(y);                

                isLabeledTrain = find(isLabeled & isTrain);                
                for foldIdx=1:numFolds
                    split = DataSet.generateSplit([.8 .2], trueY(isLabeledTrain),Configs());
                    %split = DataSet.generateSplit([1 0], trueY(isLabeledTrain),Configs());
                    %splitTrain = split >= 1;
                    %splitTest = false(size(split));
                    splitTrain = split == 1;
                    splitTest = split == 2;            

                    distMats = cell(size(V0,1),1);
                    for featIdx=1:length(V0)
                        distMats{featIdx} = Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),1);
                    end
                    yTrain = yBinary;  
                    yTrain(isLabeledTrain(splitTest)) = 0;

                    fu = obj.runLLGC(X,V0,yTrain,alpha,sigma);
                                                                             
                    tolFun = 1e-6;
                    tolX = 1e-10;
                    if obj.get('smallTol')
                        tolFun = 1e-6;
                        tolX = 1e-5;
                    end                    
                    for regIdx=1:length(regs)
                        reg = regs(regIdx);                
                        l2Reg = reg;
                        if obj.get('useL1')
                            A = ones(1,size(V0,1));
                            B = reg;
                            l2Reg = 0;
                        end
                        func = makeOptimHandle(obj,X,V0,yTrain,alpha,l2Reg,sigma,distMats,useGrad);
                        tic
                        [V,g] = fmincon(func,V0,A,B,Aeq,Beq,LB,UB,[],options);
                        toc
                        fu = obj.runLLGC(X,V,yTrain,alpha,sigma);
                        Ypred = LLGC.getPrediction(fu,train.classes);
                        accVec = trueY == Ypred;

                        trainPerf(regIdx) = mean(accVec(isLabeledTrain(splitTrain)));
                        testPerf(regIdx) = mean(accVec(~isTrain));
                        cvPerf(regIdx) = cvPerf(regIdx) + mean(accVec(isLabeledTrain(splitTest)));
                        V
                    end
                end
                cvPerf = cvPerf ./ numFolds;
                reg = regs(argmax(cvPerf));
                display(['Best reg: ' num2str(reg)]);

                l2Reg = reg;
                if obj.get('useL1')
                    A = ones(1,size(V,1));
                    B = reg;
                    l2Reg = 0;
                end
                if obj.get('useLOO')
                    yTrain = zeros(size(yBinary));
                    yTrain(isLabeledTrain) = yBinary(isLabeledTrain);
                end
%{
                i = 1;
                fu = obj.runLLGC(X,V,yTrain,alpha,sigma);
                Ypred = LLGC.getPrediction(fu,train.classes);
                accVec = trueY == Ypred;            
                trainPerf(i) = mean(accVec(isLabeled));
                testPerf(i) = mean(accVec(~isTrain));
                cvPerf(i) = mean(accVec(isLabeledTrain(splitTest)));
                fx(i) = obj.evaluate(X,V,V0,yTrain,alpha,l2Reg,S,yTest,sigma);
%}
                distMats = cell(size(V,1),1);
                for featIdx=1:length(V)
                    distMats{featIdx} = Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),1);
                end
                func = makeOptimHandle(obj,X,V0,yTrain,alpha,l2Reg,sigma,distMats,useGrad);
                tic
                [V,g] = fmincon(func,V0,A,B,Aeq,Beq,LB,UB,[],options);
                toc

                fu = obj.runLLGC(X,V,yTrain,alpha,sigma);
                Ypred = LLGC.getPrediction(fu,train.classes);
                accVec = trueY == Ypred;
%{
                i = 2;
                trainPerf(i) = mean(accVec(isLabeled));
                testPerf(i) = mean(accVec(~isTrain));
                cvPerf(i) = mean(accVec(isLabeledTrain(splitTest)));
                fx(i) = obj.evaluate(X,V,V0,yTrain,alpha,l2Reg,S,yTest,sigma);
%}

                vals = [V V0 V*sigma V0*sigma];
                %{
                perf = [trainPerf' cvPerf' testPerf'];
                vals
                perf            
                fx
                %}
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
            gradTest = obj.get('gradTest');
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
            nll = size(Wll,1);
            Ill = spdiags(true(nll,1),0,nll,nll);
            Wll(Ill) = 0;
            Yl = y(isLabeled);
            Dl = diag(sum(Wll,2));
            Dl = Dl + 1e-6*eye(size(Dl));
            Ll = Dl-Wll;            
            
            
            if gradTest
                fx = Yl'*inv(Dl)*Wll*Yl;
                return
            end
            
            fx = norm(inv(Dl)*Wll*Yl - Yl)^2 + reg*norm(V)^2;
            %fx = Yl'*Ll*Yl + reg*norm(V)^2;
            %fx = norm(inv(Dl)*Wll*Yl - Yl)^2 + reg*norm(V)^2;
            
        end
        
         function [g] = gradient_alt2(obj,X,V,V0,y,F,reg,sigma,alpha,distMats,W)
             gradTest = obj.get('gradTest');
            %{
            distMats = cell(size(V));
            for i=1:length(V)
                distMats{i} = sigma*Helpers.CreateDistanceMatrixMahabolis(X(:,i),1);
            end
            %}
            useSpeedOptims = true;
            if ~useSpeedOptims
                W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));
                W = exp(W*sigma);
            end
            %This saves needing to multiple by sigma each iteration
            %W = W*sigma;
            n = size(W,1);
            isLabeled = y ~= 0;            
            Wll = W(isLabeled,isLabeled);
            nll = size(Wll,1);
            Ill = spdiags(true(nll,1),0,nll,nll);
            Wll(Ill) = 0;            
            Dll = diag(sum(Wll));
            Dll = Dll + 1e-6*eye(size(Dll));
            warning off;
            Dll2_inv = inv(Dll*Dll);
            warning on;
            yl = y(isLabeled);
            for featIdx=1:length(V)
                if useSpeedOptims && ~isempty(distMats)
                    W_Vi = sigma*W .* distMats{featIdx};
                else
                    W_Vi = sigma*W .* Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),1);
                end
                                
                W_Vii_ll = W_Vi(isLabeled,isLabeled);
                D_Vii_ll = diag(sum(W_Vii_ll,2));
                if gradTest
                    g(featIdx) = yl'*Dll2_inv*(Dll*W_Vii_ll - D_Vii_ll*Wll)*yl;
                    continue;
                end
                %Wp = (W_Vii_ll*Dll + Wll*D_Vii_ll)*Dll2_inv
                d = 0;
                for k=1:length(yl)
                    D_k = Dll(k,k);
                    W_k = Wll(k,:);
                    y_k = yl(k);
                    Wp_k = W_Vii_ll(k,:);
                    Dp_k = D_Vii_ll(k,k);
                    D2inv_k = Dll2_inv(k,k);                    
                    dk = 2*(inv(D_k)*W_k*yl - y_k);
                    dk = dk + (D_k*Wp_k - Dp_k*W_k)*D2inv_k*yl;
                    d = d + dk;
                end
                g(featIdx) = d;
                
                %g(featIdx) = y'*L*y + 2*reg*V(featIdx);
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
        
        function [fx,W] = evaluate(obj, X, V, V0, y, alpha, reg,sigma,distMats)
            gradTest = obj.get('gradTest');
            W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));            
            W = exp(W*sigma);            
            D = diag(sum(W,2));
            %L = (1+alpha)*D - W;
            L = D - W + alpha*eye(size(D));
            if gradTest
                
                fx = 0;
                isLabeled = find(y);
                invL = inv(L);
                for idx=isLabeled'
                    yCopy = y;
                    yCopy(idx) = 0;
                    I = zeros(size(yCopy));
                    I(idx) = 1;
                    S = obj.makeSelectionMatrix(I);
                    %fx = fx + (alpha^2)*yCopy'*invL*invL*yCopy;
                    %fx = fx - 2*alpha*yCopy'*invL*Scurr'*y(idx);
                    fx = fx + (alpha^2) * yCopy'*invL*S'*S*invL*yCopy;
                end
                
                %fx = reg*norm(V)^2;
                %{
                invL = inv(L);
                fx = y'*invL*invL*y;
                %}
                %fx = y'*inv(L)*y;
                %fx = y'*L*y;                
                %fx = y'*W*y;
                return;
            end
            invL = inv(L);
            %fx = norm(alpha*invL*y - y)^2 + reg*norm(V - V0)^2;
            if obj.get('useLOO')
                fx = 0;
                isLabeled = find(y);
                for idx=isLabeled'
                    yCopy = y;
                    yCopy(idx) = 0;
                    fu = alpha*invL*yCopy;
                    r = (fu(idx)- y(idx))^2;
                    fx = fx + r;
                end                
            else
                error('');
            end
            fx = fx + reg*norm(V)^2;
            
        end
        
        function [g] = gradient(obj, X, V, V0, y, alpha, reg, sigma,distMats,W)
            gradTest = obj.get('gradTest');
            
            
            useSpeedOptims = true;
            useSlow = false;
            checkSlow = false;
            if ~useSpeedOptims
                clear W;
                distMats = [];
            end
            assert(size(V,2) == 1);
            assert(size(V0,2) == 1);
            
            if ~exist('W','var')
                W = Helpers.CreateDistanceMatrixMahabolis(X,diag(V));
                W = exp(W*sigma);
            end
            D = diag(sum(W,2));
            D = D + alpha*eye(size(D));
            %L = (1+alpha) * D - W;
            L = D - W;
            invL = inv(L);
            invL2 = invL*invL;
            g = zeros(size(V,1),1);
            
            testG = [];
            for featIdx=1:size(V,1)
                if useSpeedOptims && ~isempty(distMats)
                    W_Vi = sigma*W .* distMats{featIdx};
                else
                    W_Vi = sigma*W .* Helpers.CreateDistanceMatrixMahabolis(X(:,featIdx),1);
                end
                %dW_Vii = W .* W_Vi;
                dW_Vii = W_Vi;
                
                
                %testG(featIdx) = y(1)'*dW_Vii(1,2)*y(2);

                dD_Vii = diag(sum(dW_Vii,2));    
                dL_Vii = dD_Vii - dW_Vii;                
                g1 = 0;
                g2 = 0;
                g1Slow = 0;
                g2Slow = 0;
                isLabeled = find(y);

                M1 = invL2*dL_Vii;
                M2 = dL_Vii*invL2;
                M3 = invL*dL_Vii*invL;
                if gradTest
                    
                    for idx=isLabeled'
                        yCurr = y;
                        yCurr(idx) = 0;
                        yCurrTest = y(idx);
                        
                        I = zeros(size(yCurr));
                        I(idx) = 1;
                        S = obj.makeSelectionMatrix(I);
                        
                        M1S = M1(:,idx);
                        SIL = invL(idx,:);
                        SM2 = M2(idx,:);
                        SM3 = M3(idx,:);
                        %g1 = g1 + -alpha^2 * yCurr' * (M1S*SIL + SIL'*SM2) * yCurr;
                        %g1 = g1 - alpha^2*yCurr'*(invL2*dL_Vii*invL + invL*dL_Vii*invL2)*yCurr;
                        %g2 = g2 + 2*alpha*yCurr'*(invL*dL_Vii*invL)*Scurr'*yCurrTest;
                        g1 = g1 - (alpha^2)*yCurr'*(invL*dL_Vii*invL*S'*S*invL + invL*S'*S*invL*dL_Vii*invL)*yCurr;
                    end
                    testG(featIdx) = g1;
                    %testG(featIdx) = 2*reg*V(featIdx);
                    %testG(featIdx) = -alpha^2 * y' * (invL2*dL_Vii*invL + invL*dL_Vii*invL2) * y;
                    %testG(featIdx) = -y'*invL*dL_Vii*invL*y;
                    %testG(featIdx) = y'*dL_Vii*y;
                    %testG(featIdx) = y'*dW_Vii*y;
                end
                
                for idx=isLabeled'
                    yCurr = y;
                    yCurr(idx) = 0;
                    yCurrTest = y(idx);
                    if checkSlow || useSlow
                        I = zeros(size(yCurr));
                        I(idx) = 1;
                        S = obj.makeSelectionMatrix(I);
                        g1Slow = g1Slow + -alpha^2 * yCurr' * (invL*dL_Vii*invL*S'*S*invL + invL*S'*S*invL*dL_Vii*invL) * yCurr;
                        g2Slow = g2Slow + 2*alpha*yCurrTest'*S*invL*dL_Vii*invL*yCurr;
                    end                        
                    invL_idx = invL(idx,:);
                    g1 = g1 - (alpha^2)*( yCurr'*invL*dL_Vii*invL_idx'*invL_idx*yCurr + yCurr'*invL_idx'*invL_idx*dL_Vii*invL*yCurr);
                    g2 = g2 + 2*alpha*yCurrTest*invL_idx*dL_Vii*invL*yCurr;
                    if useSlow
                        g1 = g1Slow;
                        g2 = g2Slow;
                    end
                end
                g3 = 2*reg*V(featIdx);
                g(featIdx) = g1 + g2 + g3;
                if checkSlow
                    %[g1 g1Slow ; g2 g2Slow]                    
                    if abs(g1 - g1Slow)/abs(g1) > 1e-7
                        display('');
                        assert(g1 == g1Slow);
                    end
                    if abs(g2 - g2Slow)/abs(g2) > 1e-7
                        display('');
                        assert(g2 == g2Slow);
                    end
                    
                end
            end
            if gradTest
                g = testG;
            end
            %g
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

