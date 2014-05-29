classdef MetricLearning < DRMethod
    %METRICLEARNING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function [obj] = MetricLearning(configs)
            obj = obj@DRMethod(configs);
        end

        function [modData,metadata] = performDR(obj,data)
            metadata = struct();    
            train = data.train;
            test = data.test;
            validate = data.validate;
            
            setsToUse = obj.configs('setsToUse');
            trainX = train.X(setsToUse);
            assert(length(setsToUse) == 2);            
                        
            X1 = full(trainX{setsToUse(1)});
            X2 = full(trainX{setsToUse(2)});
            Wij = train.getSubW(setsToUse(1),setsToUse(2));
            
                              
            addBias = obj.configs('addBias');
            X1dupe = Helpers.DupeRows(X1,sum(Wij,2));
            X2dupe = Helpers.DupeRows(X2,sum(Wij,1));
            components = eye(size(X1,2));
            X1mean = zeros(1,size(X1,2));
            X2mean = zeros(1,size(X2,2));
            %{
            if obj.configs('useNewCentering')
                [~,X1mean] = Helpers.CenterData(X1);
                [COEFF, SCORE, LATENT] = princomp(X1,'econ');
                numComponents = min(find(cumsum(LATENT) >= .9));
                MAX_COMPONENTS = obj.configs('maxComponents');
                numComponents = min(numComponents,MAX_COMPONENTS);
                components = COEFF(:,1:numComponents);
                
                X1 = SCORE(:,1:numComponents);
                
                X2mean = zeros(1,size(X2,2));
                if obj.configs('centerData')
                    [X2,X2mean] = Helpers.CenterData(X2);
                end                
                X1dupe = full(Helpers.DupeRows(X1,sum(Wij,2)));
                if addBias
                    X1dupe = Helpers.AddBias(X1dupe);
                end
                X2dupe = full(Helpers.DupeRows(X2,sum(Wij,1)));
            else
                X1dupe = full(Helpers.DupeRows(X1,sum(Wij,2)));
                X2dupe = full(Helpers.DupeRows(X2,sum(Wij,1)));
                [~,X1mean] = Helpers.CenterData(X1dupe);
                [COEFF, SCORE, LATENT] = princomp(X1dupe,'econ');
                numComponents = min(find(cumsum(LATENT) >= .9));
                MAX_COMPONENTS = obj.configs('maxComponents');
                numComponents = min(numComponents,MAX_COMPONENTS);
                components = COEFF(:,1:numComponents);
                X1dupe = SCORE(:,1:numComponents);
                X2mean = zeros(1,size(X2,2));
                if obj.configs('centerData')
                    [X2dupe,X2mean] = Helpers.CenterData(X2dupe);
                end
            end
            %}
                   
            
            Wvec = Wij(:);
            Wvec = Wvec(Wvec ~= 0);
            
            Wij_CL = (Wij == 0);
            
            reg = obj.configs('reg');            
            if obj.configs('useSim')
                hinge = @(x) sum(max(0,square(1-x)));
                if obj.configs('useHinge')
                    cvx_begin quiet
                        variable W(size(X1dupe,2),size(X2dupe,2))
                        %minimize(sum(sum(W.^2,2)) + reg*pow_pos(hinge(diag(X1dupe*W*X2dupe')),2))
                        minimize(sum(sum(W.^2,2)) + reg*hinge(Wvec.*diag(X1dupe*W*X2dupe')))
                        subject to
                    cvx_end
                else
                    cvx_begin quiet
                        variable W(size(X1dupe,2),size(X2dupe,2))
                        minimize(sum(sum(W.^2,2)) + reg*(sum(Wvec.*diag(X1dupe*W*X2dupe').^2)))
                        subject to
                    cvx_end
                end
            else
                cvx_begin quiet
                    variable W(size(X1dupe,2),size(X2dupe,2))
                    minimize(sum(sum((X1dupe*W-X2dupe).^2,2)))
                    subject to
                        sum(sum(W.^2,2)) <= reg
                cvx_end
            end
            
            %display(['Primal Value: ' num2str(sum(sum((X1dupe*W-X2dupe).^2)))]);
            projections = {W, eye(size(X2))};
            means = {X1mean, X2mean};
            
            projMeta = struct();
            projMeta.pcaProj = cell(length(setsToUse));
            projMeta.pcaProj{1} = components;
            projMeta.pcaProj{2} = eye(size(X2));
            projMeta.addBias = [addBias false];
            modData = struct();
            modData.train = obj.applyProjection(train,setsToUse,projections,means,projMeta);
            modData.validate = obj.applyProjection(validate,setsToUse,projections,means,projMeta);
            modData.test = obj.applyProjection(test,setsToUse,projections,means,projMeta);
            

            centerData = obj.configs('centerData');            
            metadata.reg = reg;
            metadata.centerData = centerData;
        end   
        
        function [prefix] = getPrefix(obj)
            prefix = 'ML';
        end
        
        function [d] = getDirectory(obj)
            d = 'ML';
        end
        
        function [nameParams] = getNameParams(obj)
            nameParams = {'maxComponents','centerData','addBias'};
        end  
    end
    
end

