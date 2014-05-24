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
                        
            X1 = trainX{setsToUse(1)};
            X2 = trainX{setsToUse(2)};   
            Wij = train.getSubW(setsToUse(1),setsToUse(2));
            
            reg = obj.configs('reg');
            centerData = obj.configs('centerData');            
            
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
            
            %{
            cvx_begin quiet
                variable W(size(X2dupe,2),size(X1dupe,2))
                minimize(sum(sum((X1dupe-X2dupe*W).^2,2)))
                subject to
                    sum(sum(W.^2,2)) <= reg
            cvx_end
            r = sum(sum(W.^2))
            display(['Primal Value: ' num2str(sum(sum((X1dupe-X2dupe*W).^2)))]);
            projections = {components, W};
            means = {X1mean, zeros(1,size(X2,2))};

            modData = struct();
            modData.train = obj.applyProjection(train,setsToUse,projections,means);
            modData.validate = obj.applyProjection(validate,setsToUse,projections,means);
            modData.test = obj.applyProjection(test,setsToUse,projections,means);
            %}
            if obj.configs('useSim')
                %{
                cvx_begin quiet
                    variable W(size(X1dupe,2),size(X2dupe,2))
                    minimize(trace(X1dupe*W*X2dupe'))
                    subject to
                        sum(sum(W.^2,2)) <= reg
                cvx_end
                r = sum(sum(W.^2));
                %primValue = sum(sum(X1dupe*W*X2dupe'));
                %[r reg]
                if r+.1 < reg
                    metadata.keepTuningReg = false;
                end
                %}
                hinge = @(x) sum(max(0,square(1-x)));
                if obj.configs('useHinge')
                    cvx_begin quiet
                        variable W(size(X1dupe,2),size(X2dupe,2))
                        %minimize(sum(sum(W.^2,2)) + reg*pow_pos(hinge(diag(X1dupe*W*X2dupe')),2))
                        minimize(sum(sum(W.^2,2)) + reg*hinge(diag(X1dupe*W*X2dupe')))
                        subject to
                    cvx_end
                else
                    cvx_begin quiet
                        variable W(size(X1dupe,2),size(X2dupe,2))
                        minimize(sum(sum(W.^2,2)) + reg*(sum(diag(X1dupe*W*X2dupe').^2)))
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
            projections = {components*W, eye(size(X2))};
            means = {X1mean, X2mean};

            modData = struct();
            modData.train = obj.applyProjection(train,setsToUse,projections,means);
            modData.validate = obj.applyProjection(validate,setsToUse,projections,means);
            modData.test = obj.applyProjection(test,setsToUse,projections,means);
            
            %modData.train.X{1}(1:10,1:3)
            %X1dupe(1:10,1:3)                    
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
            nameParams = {'maxComponents','useSim','useHinge','centerData'};
        end  
    end
    
end

