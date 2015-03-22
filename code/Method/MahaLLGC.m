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
            X = X(:,1);
            YBinary = y;
            YBinary(y==8) = -1;
            YBinary(y==-1) = 0;
            y = Helpers.createLabelMatrix(y);
            alpha = 1;
            reg = 1;
            t = .01;
            sigmaScale = obj.get('sigmaScale');
            W = Helpers.CreateDistanceMatrix(X);
            sigmaNormal = sigmaScale*mean(W(:));
            sigma = -2*(sigmaNormal^2);
            V0 = diag(ones(size(X,2),1) ./ sigma);
            V = V0;
            fx = [];  
            trainPerf = [];
            testPerf = [];
            diff = [];
            
            for i=1:10
                %{
                W = Helpers.CreateDistanceMatrix(X);
                Wrbf = Helpers.distance2RBF(W,sigmaNormal);                
                W2 = exp(Helpers.CreateDistanceMatrixMahabolis(X,V));
                fu = LLGC.llgc_inv(Wrbf,y,alpha);
                %}
                fu = obj.runLLGC(X,V,y,alpha);
                Ypred = LLGC.getPrediction(fu,train.classes);
                accVec = trueY == Ypred;
                trainPerf(i) = mean(accVec(isLabeled));
                testPerf(i) = mean(accVec(~isTrain));
                %testPerf(i)
                
                g = obj.gradient(X,V,V0,YBinary,alpha,reg);
                fx(i) = obj.evaluate(X,V,V0,YBinary,alpha,reg);
                fx(i)
                V = V - t*g;
                diff(i) = norm(V - V0);
            end
        end
        
        function [fu] = runLLGC(obj, X, V, y, alpha)
            W = Helpers.CreateDistanceMatrixMahabolis(X,V);
            W = exp(W);
            fu = LLGC.llgc_inv(W,y,alpha);
        end
        
        function [fx] = evaluate(obj, X, V, V0, y, alpha, reg)
            W = Helpers.CreateDistanceMatrixMahabolis(X,V);
            W = exp(W);
            D = diag(sum(W,2));
            L = (1+alpha)*D - W;
            invL = inv(L);
            fx = norm(alpha*invL*y - y)^2 + reg*norm(V - V0)^2;
        end
        
        function [g] = gradient(obj, X, V, V0, y, alpha, reg)
            W = Helpers.CreateDistanceMatrixMahabolis(X,V);
            W = exp(W);
            D = diag(sum(W,2));
            L = (1+alpha) * D - W;
            invL = inv(L);
            invL2 = invL*invL;
            g = zeros(size(V,1),1);
            for i=1:size(V,2)
                Xi = X(:,i);
                Wi = Helpers.CreateDistanceMatrixMahabolis(Xi,1);                
                                
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
                
                Vii_diff = 2 * (V(i,i)-V0(i,i));
                
                g1 = -alpha^2 * y' * (invL2*dL_Vii*invL + invL*dL_Vii*invL2) * y;
                g2 = 2*alpha*y'*invL*dL_Vii*invL*y;
                g3 = 2*reg*Vii_diff;
                g(i) = g1 + g2 + g3;
                
                %f1 = y'*(invL2 + invL)*y
                %{
                g(i) = -alpha^2 * y' * (invL2*dL_Vii*invL + invL*dL_Vii*invL2) * y  ...
                    - 2*alpha*y'*invL*dL_Vii*invL*y  ...
                    + 2*reg*Vii_diff;
                %}
            end
            g = diag(g);
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

