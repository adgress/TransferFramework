classdef HP < CCA
    %HP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function [obj] = HP(configs)
            obj = obj@CCA(configs);
        end
        function [modData,metadata] = performDR(obj,data)
            train = data.train;
            test = data.test;
            validate = data.validate;
            
            setsToUse = obj.configs('setsToUse');
            trainX = train.X(setsToUse);
            assert(length(setsToUse) == 2);            
                        
            X1 = trainX{setsToUse(1)};
            X2 = trainX{setsToUse(2)};   
            Wij = train.getSubW(setsToUse(1),setsToUse(2));
            
            reg = obj.configs('reg');
            numVecs = obj.configs('numVecs');
            centerData = true;
            options = struct();
            options.reg = reg;
            
            if centerData
                [X1,X1mean] = Helpers.CenterData(X1);
                [X2,X2mean] = Helpers.CenterData(X2);
            else
                X1mean = zeros(size(X1,2),1);
                X2mean = zeros(size(C2,2),1);
            end
            
            
            [K_21,C_22] = obj.computeK(X1,X2,Wij,options);
            [Q_12] = obj.computeQ(X1,X2,Wij,K_21);
            Q = Q_12;
            
            B = eye(size(Q));
            [v1,vals1] = eig(Q,B);
            [sortedVals,I] = sort(diag(vals1),'ascend');
            v1 = v1(:,I);
            
            for i=1:size(v1,2)
                vi = v1(:,i);
                d = sqrt(vi'*B*vi);
                v1(:,i) = vi/d;
            end
            
            v2 = K_21*v1;
            modData = struct();
            
            projections = {v1(:,1:numVecs), v2(:,1:numVecs)};
            means = {X1mean,X2mean};
            modData.train = obj.applyProjection(train,setsToUse,projections,means);
            modData.validate = obj.applyProjection(validate,setsToUse,projections,means);
            modData.test = obj.applyProjection(test,setsToUse,projections,means);
            
            metadata = struct();
            metadata.numVecs = numVecs;
            metadata.reg = reg;
            metadata.projections = projections;
        end         

        function [K,C22] = computeK(obj,X1,X2,W,options)
            C22 = X2'*diag(sum(W))*X2;
            C21 = X2'*W'*X1;
            %This assumes Wmt_train(i,j) \in {0,1}
            %{
            C22_2 = zeros(size(X2,2));
            C21_2 = zeros(size(X2,2),size(X1,2));
            for i=1:size(W,1)
                for j=1:size(W,2)
                    if W(i,j) == 0
                        continue;
                    end
                    x1 = X1(i,:)';
                    y2 = X2(j,:)';
                    C22_2 = C22_2 + y2*y2';
                    C21_2 = C21_2 + y2*x1';
                end
            end            
            %}
            %{
            errYY = (C22_2-Cyy_2)./C22_2;
            max(errYY(:))
            errYX = (C21_2-Cyx_2)./C21_2;
            max(errYX(:))
            %}
            %%Should we regularize here?
            if options.reg == 0 || size(C22,1) == 2
                C22_inv = pinv(C22);
            else
                C22_inv = inv(C22+(options.reg)*eye(size(C22)));
            end
            K = C22_inv*C21;
        end
        
        function [Q] = computeQ(obj,X1,X2,W,K)
            Q = zeros(size(X1,2));
            for i=1:size(W,1)
                for j=1:size(W,2)
                    if W(i,j) == 0
                        continue;
                    end
                    x1 = X1(i,:)';
                    x2 = X2(j,:)';
                    p = x1 - K'*x2;
                    Q = Q + p*p'*W(i,j);
                end
            end
        end
        
        function [C] = computeC(obj,X,W,options)
            error('Update!');
            C = zeros(size(X,2));
            for i=1:size(W,1)
                for j=1:size(W,2)
                    if W(i,j) == 0
                        continue;
                    end
                    xi = X(i,:);
                    xj = X(j,:);
                    p = xi-xj;
                    C = C + p*p';
                end
            end
        end
        
        
        function [C] = computeIntraViewMatrix(obj,K_view,K_matrix,W,options)
            error('Update!');
            C = zeros(size(K_matrix,2));
            for i=1:size(W,1)
                for j=1:size(W,2)
                    wij = W(i,j);
                    if wij == 0
                        continue;
                    end
                    xi = K_view(i,:)';
                    xj = K_view(j,:)';
                    p = K_matrix'*(xi-xj)*wij;
                    C = C + p*p';
                end
            end
        end
        
        function [prefix] = getPrefix(obj)
            prefix = 'HP';
        end
        
        function [d] = getDirectory(obj)
            d = 'HP';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
    end
    
end

