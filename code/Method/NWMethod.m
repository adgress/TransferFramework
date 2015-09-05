classdef NWMethod < HFMethod
    %NWMETHOD Nadaraya-Watson Estimator
    %   Detailed explanation goes here
    
    properties
        X
        Y
        sigma
    end
    
    methods
        function obj = NWMethod(configs)
            if ~exist('configs','var')
                configs = Configs();
            end
            obj = obj@HFMethod(configs);
            obj.method = HFMethod.NW;
            if ~obj.has('classification')
                obj.set('classification',true);
            end
        end
        
        
        
        function [] = train(obj,X,Y)
            X = zscore(X);
            if all(Y == 0)
                obj.X = [];
                obj.Y = [];
                return;
            end
            sig = obj.get('sigma');
            assert(~isempty(sig));
            if length(sig) == 1                
                obj.sigma = sig;
            else
                cv = CrossValidation();
                cv.setData(X,Y);
                cv.methodObj = obj;
                cv.measure = obj.get('measure');
                cvParams = Helpers.vector2cvParams(sig,'sigma');
                cv.parameters = cvParams;
                [bestParams,acc] = cv.runCV();                
                obj.sigma = bestParams.value;
            end            
            isLabeled = ~isnan(Y);
            obj.X = X(isLabeled,:);
            obj.Y = Y(isLabeled,:);
        end
        
        function [y,fu] = predict(obj,X)
            if isempty(obj.Y)
                y = zeros(size(X,1),1);
                if obj.get('classification')
                    y(:) = nan;
                end
                return;
            end
            nl = size(obj.X,1);            
            Xall = [obj.X ; X];
            W = Helpers.CreateDistanceMatrix(Xall);
            W = W(nl+1:end,1:nl);
            W = Helpers.distance2RBF(W,obj.sigma);   
            d = sum(W,2);
            d(d < 1e-8) = 1;
            D = diag(d);
            warning off;
            S = inv(D)*W;
            warning on;
            if obj.get('classification')
                classes = unique(obj.Y);
                fu = zeros(size(X,1),max(classes));
                for idx=1:max(classes)
                    I = obj.Y == idx;
                    Si = S(:,I);
                    Yi = ones(sum(I),1);
                    fu(:,idx) = Si*Yi;
                end
                assert(all(fu(:) >= 0));       
                I = find(sum(fu,2) == 0);
                if ~isempty(I)
                    fu(I,:) = rand(length(I),size(fu,2));
                end
                fu = Helpers.NormalizeRows(fu);                
                
                Helpers.AssertInvalidPercent(fu);
                [~,y] = max(fu,[],2);
            else
                y = S*obj.Y;            
            end
        end
        
        function [fu,savedData,sigma] = runNW(obj,distMat,makeRBF,savedData)
            assert(makeRBF);

            distMat.W = Helpers.distance2RBF(distMat.W,obj.get('sigma'));
            I = distMat.isLabeledTargetTrain();            

            if distMat.isRegressionData && ~obj.get('classification')
                Wlabeled = distMat.W(:,I);
                D = diag(sum(Wlabeled,2));
                fu = zeros(size(distMat.Y));
                assert(size(fu,2) == 1);
                warning off;
                fu = inv(D)*Wlabeled*distMat.Y(I);
                warning on;                
            else
                Wlabeled = distMat.W(I,:);
                fu = zeros(length(I),distMat.numClasses);
                for labelIdx=1:distMat.numClasses
                    currY = distMat.classes(labelIdx);
                    currTrain = distMat.Y == currY & I;
                    Wsub = distMat.W(currTrain,:);
                    conf = sum(Wsub);
                    fu(:,labelIdx) = conf';
                end
                Izero = sum(fu,2) == 0;
                fu(Izero,:) = rand([sum(Izero) 2]);
                fu = Helpers.NormalizeRows(fu);

                [~,fu] = max(fu,[],2);
                fu = distMat.classes(fu);
            end
            isInvalid = isnan(fu) | isinf(fu);
            if any(isInvalid(:))
                %display('LLGC:llgc_ls : inf or nan - randing out');
                r = rand(size(fu));
                fu(isInvalid) = r(isInvalid);
            end
            savedData.predicted = fu;
            savedData.cvAcc = [];
            sigma = obj.get('sigma');
        end
        function [s] = getPrefix(obj)
            s = 'NW';
        end
        function [nameParams] = getNameParams(obj)
            %nameParams = {'sigma','sigmaScale','k','alpha'};            
            nameParams = {'sigmaScale'};
            if obj.has('sigma') && length(obj.get('sigma')) == 1
                nameParams{end+1} = 'sigma';
            end
        end   
    end
    
end

