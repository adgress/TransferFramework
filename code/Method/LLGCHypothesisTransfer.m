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
            makeRBF = false;
            [Wrbf,~,~,Y_testCleared,~] = obj.makeLLGCMatrices(distMat,~makeRBF);
            Y = Y_testCleared;
            numLabels = max(Y);
            n = size(Wrbf,1);
            alpha = obj.get('alpha');
            L = LLGC.make_L(Wrbf);
            reg = obj.get('reg');                        
            
            [ySource,fuSource] = obj.getSourcePredictions(distMat.X);
            
            numSources = length(obj.sourceHyp);
            
            
            fuCombined = zeros(n,numLabels*numSources);
            betaIndex = ones(size(fuSource{1},2),1);
            for j=1:numLabels
                f = zeros(n,numSources);
                for idx=1:length(fuSource)
                    f(:,idx) = fuSource{idx}(:,j);                    

                end
                
                rows = n*(j-1)+1:n*j;                
                cols = numSources*(j-1)+1:numSources*j;
                fuCombined(:,cols) = f;
                %fuCombined = [fuCombined fuSource{idx}];
                %betaIndex = [betaIndex ; idx*ones(size(fuSource{idx},2),1)];
            end
            
            
            I = ~isnan(Y);
            Ymat = Helpers.createLabelMatrix(Y);
            invL = inv(L + (alpha+numSources)*eye(size(L)));
            mask = ones(n);
            mask = mask - diag(diag(mask));
            mask = logical(mask);

            warning off
            cvx_begin quiet
                variable F(n,numLabels)             
                variable FbTemp(n,numLabels)
                variable b(numSources,1)
                variable bRep(length(betaIndex)*numSources,numLabels)
                variable c
                minimize(norm(F(I,[10 15])-Ymat(I,[10 15]) + c,1))
                subject to
                    b >= 0
                    b <= 1
                    norm(b,1) <= reg
                    %bRep == repmat(b(betaIndex),1,numLabels)
                    bRep == blkdiag(b,b,b,b,b,b,b,b,b,b,b,b,b,b,b)
                    for idx=1:n                        
                        F(idx,:) == invL(idx,mask(idx,:))*(alpha*Ymat(mask(idx,:),:)) + ...
                            invL(idx,:)*fuCombined*bRep;
                    end
            cvx_end  
            warning on
            %fuCombined(:,10)
            %b
            obj.set('beta',b);
            obj.set('c',c);
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
            L = LLGC.make_L(Wrbf);
            beta = obj.get('beta');
            alpha = obj.get('alpha');
            M = L + eye(size(L))*(sum(beta) + alpha);
            Y = alpha*Helpers.createLabelMatrix(Y_testCleared);
            for idx=1:length(obj.sourceHyp)
                assert(~isempty(distMat.X));
                Yi = obj.sourceHyp{idx}.predict(distMat.X);
                Y = Y + beta(idx)*Helpers.createLabelMatrix(Yi);
            end
            fu = M\Y;
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
            nwSigmas = 4;
            
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
            targetTrain = train.copy();
            targetTrain.remove(targetTrain.instanceIDs ~= 0);
            input.train = targetTrain;
            
            llgcSigma = 10;
            llgcSigmaScale = .01;
            alpha = .9;
            reg = 1;
            cvParams = struct('key','values');
            cvParams(1).key = 'reg';
            %cvParams(1).values = num2cell([0 10.^(-1:3)]);
            cvParams(1).values = num2cell(0:3);
            
            obj.set('alpha',alpha);
            %obj.set('reg',reg);
            %obj.set('sigma',llgcSigma);  
            obj.delete('sigma');
            obj.set('sigmaScale',llgcSigmaScale);
            
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
            %nameParams = {'sigma','sigmaScale','k','alpha'};            
            %nameParams = {'sigma'};
            nameParams = {};
            if length(obj.get('alpha')) == 1
                nameParams{end+1} = 'alpha';
            end
        end 
    end
    
end

