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
            %display('Not calling zscore');
        end
        
        
        
        function [] = train(obj,X,Y)
            if ~obj.get('newZ')
                %X = zscore(X);
            end
            if all(isnan(Y))
                obj.X = [];
                obj.Y = [];
                return;
            end
            sig = obj.get('sigma',[]);
            if isempty(sig)
                sig = obj.get('cvSigma',[]);
            end
            assert(~isempty(sig));
            if length(sig) == 1                
                obj.sigma = sig;
            else
                cv = CrossValidation();
                cv.set('print',false);
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
        function [y,fu] = getLOOestimates(obj,X,Y)
            W = Helpers.CreateDistanceMatrix(X);
            W = Helpers.distance2RBF(W,obj.sigma); 
            W = W - diag(diag(W));
            [y,fu] = obj.doPredict(W,Y);
        end
        
        function [y,fu] = doPredict(obj,W,Y)
            if ~exist('Y','var')
                Y = obj.Y;
            end
            d = sum(W,2);
            d(d < 1e-8) = 1;
            D = diag(d);
            warning off;
            S = inv(D)*W;
            warning on;
            if obj.get('classification')
                classes = unique(obj.Y);
                fu = zeros(size(W,1),max(classes));
                for idx=1:max(classes)
                    I = Y == idx;
                    Si = S(:,I);
                    Yi = ones(sum(I),1);
                    fu(:,idx) = Si*Yi;
                end
                assert(all(fu(:) >= 0));       
                I = find(sum(fu,2) == 0);
                if ~isempty(I)
                    randPredictions = rand(length(I),length(classes));
                    %fu(I,:) = rand(length(I),size(fu,2));
                    fu(I,classes) = randPredictions;
                end
                fu = Helpers.NormalizeRows(fu);                
                
                Helpers.AssertInvalidPercent(fu);
                [~,y] = max(fu,[],2);
            else
                y = S*Y;            
                fu = y;
            end
        end
        
        function [y,fu] = predict(obj,X)
            if isempty(obj.Y)                
                y = zeros(size(X,1),1);
                if obj.get('classification')
                    y(:) = nan;
                end
                fu = y;
                return;
            end
            %{
            y = X;
            fu = X;
            return;
            %}
            nl = size(obj.X,1);            
            Xall = [obj.X ; X];
            W = Helpers.CreateDistanceMatrix(Xall);
            W = W(nl+1:end,1:nl);
            W = Helpers.distance2RBF(W,obj.sigma);   
            [y,fu] = obj.doPredict(W);
        end
        
        function [fu,savedData,sigma] = runNW(obj,distMat,makeRBF,savedData)            
            assert(makeRBF);
            I = distMat.isLabeledTargetTrain();
            obj.train(distMat.X(I,:),distMat.Y(I));
            [y,fu] = obj.predict(distMat.X);   
            savedData.predicted = y;
            savedData.cvAcc = [];
            sigma = obj.sigma;
        end
        function [s] = getPrefix(obj)
            s = 'NW';
        end
        function [nameParams] = getNameParams(obj)
            %nameParams = {'sigma','sigmaScale','k','alpha'};  
            nameParams = getNameParams@HFMethod(obj);
            nameParams{end+1} = 'sigmaScale';
            if obj.has('sigma') && length(obj.get('sigma')) == 1
                nameParams{end+1} = 'sigma';
            end
        end   
    end
    
end

