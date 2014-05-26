classdef CCA < DRMethod
    %DRCCA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = CCA(configs)
            obj = obj@DRMethod(configs);
        end
        function [modData,metadata] = performDR(obj,data)
            train = data.train;
            test = data.test;
            validate = data.validate;
            
            setsToUse = obj.configs('setsToUse');
            trainX = train.X(setsToUse);
            assert(length(setsToUse) == 2);
            Wij = train.getSubW(setsToUse(1),setsToUse(2));
            
            assert(Helpers.IsBinary(Wij));
            X1 = trainX{setsToUse(1)};
            X2 = trainX{setsToUse(2)};
            X1dupe = Helpers.DupeRows(X1,sum(Wij,2));
            X2dupe = Helpers.DupeRows(X2,sum(Wij,1));
            [X1dupe,X1mean] = Helpers.CenterData(X1dupe);
            [X2dupe,X2mean] = Helpers.CenterData(X2dupe);
            
            reg = obj.configs('reg');
            numVecs = obj.configs('numVecs');
            
            C22 = X2dupe'*X2dupe;
            C22 = C22 + reg*eye(size(C22));
            %C22_inv = inv(C22);
            
            C11 = X1dupe'*X1dupe;
            C11 = C11 + reg*eye(size(C11));
            %C11_inv = inv(C11);
            
            %K = X1dupe*X2dupe'*C22_inv*X2dupe*X1dupe';
            K = X1dupe'*X2dupe*(C22\X2dupe'*X1dupe);
            [vecs,vals] = eig(K,C11);
            vals = diag(vals);
            [sortedVals,I] = sort(vals,'descend');
            v1 = vecs(:,I);
            
            for i=1:size(v1,2)
                ai = v1(:,i);
                v1(:,i) = ai/sqrt(ai'*C11*ai);
            end
            %c = C22_inv*X2dupe*X1dupe'*a;
            v2 = C22\X2dupe'*X1dupe*v1;
            for i=1:size(v2,2)
                ci = v2(:,i);
                v2(:,i) = ci/sqrt(ci'*C22*ci);
            end   
            v1 = v1(:,1:numVecs);
            v2 = v2(:,1:numVecs);
            
            modData = struct();
            
            projections = {v1, v2};
            means = {X1mean,X2mean};
            modData.train = obj.applyProjection(train,setsToUse,projections,means);            
            modData.validate = obj.applyProjection(validate,setsToUse,projections,means);
            modData.test = obj.applyProjection(test,setsToUse,projections,means);
            
            metadata = struct();
            metadata.numVecs = numVecs;
            metadata.reg = reg;
            metadata.projections = projections;
        end         
        
        function [prefix] = getPrefix(obj)
            prefix = 'CCA';
        end
        
        function [d] = getDirectory(obj)
            d = 'CCA';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'numVecs'};
        end                
    end
    
end

