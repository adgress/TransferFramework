classdef LLGCHypothesisTransfer < LLGCMethod
    %LLGCHYPOTHESISTRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sourceHyp
    end
    
    methods
        function obj = LLGCHypothesisTransfer(configs)
            obj = obj@LLGCMethod(configs);
            obj.sourceHyp = [];
            if ~obj.has('noTransfer')
                obj.set('noTransfer',0);
            end
            if ~obj.has('useNW')
                obj.set('useNW',1);
            end
        end
        
        function [v] = evaluate(obj,L,y,sourceY,alpha,reg,beta)
            invM = inv(L + eye(size(L))*(alpha+sum(beta)));
            I = ~isnan(y);
            v = reg*norm(beta,1);
            for idx=1:size(Y,2)
                Yi = alpha*y(:,idx) + sourceY{idx}*beta;
                v = v + norm(Yi(I) - y(I),1);
            end
        end
        
        function [] = train(obj,distMat)
            numSources = length(obj.sourceHyp);
            reg = obj.get('reg');
            if reg == 0
                obj.set('beta',zeros(numSources,1));
                return;
            end                   
            useNW = obj.get('useNW');
            makeRBF = false;
            [Wrbf,~,~,Y_testCleared,~] = obj.makeLLGCMatrices(distMat,~makeRBF);
            Y = Y_testCleared;
            numLabels = max(Y);
            n = size(Wrbf,1);
            alpha = obj.get('alpha');
            L = LLGC.make_L(Wrbf);
            
            [ySource,fuSource] = obj.getSourcePredictions(distMat.X);

            fuCombined = zeros(n,numLabels*numSources);
            for j=1:numLabels
                f = zeros(n,numSources);
                for idx=1:length(fuSource)
                    f(:,idx) = fuSource{idx}(:,j);                    

                end                              
                cols = numSources*(j-1)+1:numSources*j;
                fuCombined(:,cols) = f;
            end
            betaRowIdx = 1:(numLabels*numSources);
            betaColIdx = zeros(numLabels*numSources,1);
            betaIdx = zeros(numLabels*numSources,1);
            for idx=1:numLabels
                range = numSources*(idx-1)+1:numSources*idx;
                betaColIdx(range) = idx;
                betaIdx(range) = (1:numSources)';
            end
            
            I = ~isnan(Y);
            Ymat = Helpers.createLabelMatrix(Y);            
            
            if useNW
                invL = diag(1 ./ sum(Wrbf,2)) * Wrbf;
                alpha = 1;
            else
                %invL = inv(L + (alpha+numSources)*eye(size(L)));
                invL = inv(L + alpha*eye(size(L)));            
            end
            invL = invL - diag(diag(invL));
            warning off
            cvx_begin quiet
                variable F(n,numLabels)             
                variable FbTemp(n,numLabels)
                variable b(numSources,1)
                variable bRep(numLabels*numSources,numLabels)
                %variable c
                %minimize(norm(F(I,[10 15])-Ymat(I,[10 15]) + c,1))
                minimize(norm(F(I,:)-Ymat(I,:),1))
                subject to
                    b >= 0
                    %b <= 1
                    norm(b,1) <= reg
                    bRep == sparse(betaRowIdx,betaColIdx,b(betaIdx))
                    
                    F == invL*(alpha*Ymat + fuCombined*bRep)
            cvx_end  
            warning on
            %fuCombined(:,10)
            %b
            obj.set('beta',b);
            %obj.set('c',c);
        end
        
        function [y,fu] = getSourcePredictions(obj,X)
            y = cell(size(obj.sourceHyp));
            fu = y;
            for idx=1:length(obj.sourceHyp);
                [y{idx},fu{idx}] = obj.sourceHyp{idx}.predict(X);
            end
        end
        
        function [y,fu] = predict(obj,distMat)
            makeRBF = false;
            [Wrbf,~,~,Y_testCleared,~] = obj.makeLLGCMatrices(distMat,~makeRBF);
            beta = obj.get('beta');
            Y = Helpers.createLabelMatrix(Y_testCleared);
            if obj.get('useNW')
                M = diag(1 ./ sum(Wrbf,2))*Wrbf;
            else
                L = LLGC.make_L(Wrbf);
                alpha = obj.get('alpha');
                M = L + eye(size(L))*(sum(beta) + alpha);
                Y = Y*alpha;
            end
            for idx=1:length(obj.sourceHyp)
                assert(~isempty(distMat.X));
                [Yi,FUi] = obj.sourceHyp{idx}.predict(distMat.X);
                %Y = Y + beta(idx)*Helpers.createLabelMatrix(Yi,size(Y,2));
                Y = Y + beta(idx)*FUi;
            end
            if obj.get('useNW')
                fu = M * Y;
            else
                fu = M\Y;
            end
            I = ~(fu(:) >= 0);
            if any(I)
                fu(I)
            end
            assert(all(fu(:) >= 0));
            I = find(sum(fu,2) == 0);
            if ~isempty(I)
                fu(I,:) = rand(length(I),size(fu,2));
            end
            fu = Helpers.NormalizeRows(fu);
            [~,y] = max(fu,[],2);
        end
        function [testResults,savedData] = runMethod(obj,input,savedData)
            train = input.train;
            test = input.test;
            
            makeRBF = false;
            [distMat] = obj.createDistanceMatrix(train,test,obj.configs,makeRBF);                
            obj.train(distMat);
            [y,fu] = obj.predict(distMat);
            testResults = FoldResults();   
            testResults.dataType = distMat.type;
            testResults.yActual = distMat.trueY;
            testResults.yPred = y;
            a = obj.configs.get('measure').evaluate(testResults);
            savedData.val = a.learnerStats.valTest;
            assert(~isnan(savedData.val));
        end
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            if ~exist('savedData','var')
                savedData = struct();
            end
            pc = ProjectConfigs.Create();
            train = input.train;
            test = input.test;   
            testResults = FoldResults();   
            
            
            if pc.dataSet == Constants.NG_DATA
                C = [train.X ; test.X];
                C = C';
                %[W, idf] = tf_idf_weight(C, 'normalize')
                [W, idf] = tf_idf_weight(double(C));
                W(isnan(W(:))) = 0;
                W = W';
                numTrain = size(train.X,1);
                train.X = W(1:numTrain,:);
                test.X = W(numTrain+1:end,:);
            end
            dataSetIDs = unique(train.instanceIDs);
            sourceDataSetIDs = dataSetIDs(dataSetIDs ~= 0);
            obj.sourceHyp = {};
            %nwSigmas = 2.^(-5:5);
            %nwSigmas = 4;
            %nwSigmas = .03;
            nwSigmas = obj.get('cvSigma');
            %{
            n = size(train.X,1);
            Xall = zscore([train.X ; test.X]);
            train.X = Xall(1:n,:);
            test.X = Xall(n+1:end,:);
            %}
            if isempty(obj.sourceHyp)
                for idx=1:length(sourceDataSetIDs)
                    nwObj = NWMethod();
                    nwObj.set('sigma',nwSigmas);
                    nwObj.set('measure',Measure());
                    nwObj.set('classification',true);
                    I = train.instanceIDs == sourceDataSetIDs(idx);
                    X = train.X(I,:);
                    Y = train.Y(I,:);
                    nwObj.train(X,Y);
                    obj.sourceHyp{idx} = nwObj;
                end
            end
            targetTrain = train.copy();
            targetTrain.remove(targetTrain.instanceIDs ~= 0);
            input.train = targetTrain;
            llgcSigma = obj.get('cvSigma');
            %llgcSigma = 10;
            llgcSigmaScale = .01;
            alpha = .9;
            reg = 1;
            cvParams = struct('key','values');
            cvParams(1).key = 'reg';
            cvParams(1).values = num2cell(obj.get('cvReg'));
            if obj.get('noTransfer')
                cvParams(1).values = {0};
            end            
            cvParams(2).key = 'sigma';
            cvParams(2).values = num2cell(llgcSigma);
            %obj.set('sigma',llgcSigma);  
            if ~obj.get('useNW')
                cvParams(3).key = 'alpha';
                cvParams(3).values = num2cell(obj.get('cvAlpha'));
            end
            %obj.set('alpha',alpha);
            %obj.set('reg',reg);
            %obj.delete('sigma');
            obj.delete('sigmaScale');
            
            
            %obj.set('sigmaScale',llgcSigmaScale);
            
            cv = CrossValidation();
            cv.trainData = targetTrain.copy();
            cv.methodObj = obj;
            cv.parameters = cvParams;
            cv.measure = obj.get('measure');
            tic
            [bestParams,acc] = cv.runCV();
            toc
            obj.setParams(bestParams);
            [testResults,savedData] = obj.runMethod(input,savedData);
            if ~obj.configs.get('quiet')
                display([ obj.getPrefix() ' Acc: ' num2str(savedData.val)]);
            end
        end
        function [prefix] = getPrefix(obj)
            prefix = 'HypTran';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
            if obj.get('noTransfer',false)
                nameParams{end+1} = 'noTransfer';
            end
            if length(obj.get('cvAlpha')) == 1
                nameParams{end+1} = 'alpha';
            end
            if length(obj.get('cvReg')) == 1
                nameParams{end+1} = 'reg';
            end
            if obj.get('useNW',0)
                nameParams{end+1} = 'useNW';
            end
        end 
    end
    
end

