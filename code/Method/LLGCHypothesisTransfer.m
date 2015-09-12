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
            pc = ProjectConfigs.Create();
            if ~obj.has('noTransfer')
                obj.set('noTransfer',0);
            end
            if ~obj.has('useNW')
                obj.set('useNW',1);
            end
            if ~obj.has('useBaseNW')
                obj.set('useBaseNW',0);
            end
            %{
            if ~obj.has('newZ')
                obj.set('newZ',1);
            end
            %}
            obj.set('newZ',pc.dataSet ~= Constants.NG_DATA);
            obj.set('hinge',0);
            if ~obj.has('oracle')
                obj.set('oracle',false);
            end
            obj.set('useOrig',0);
        end
        
        function [v] = evaluate(obj,L,y,sourceY,alpha,reg,beta)
            error('Is this used?');
            invM = inv(L + eye(size(L))*(alpha+sum(beta)));
            I = ~isnan(y);
            v = reg*norm(beta,1);
            for idx=1:size(Y,2)
                Yi = alpha*y(:,idx) + sourceY{idx}*beta;
                v = v + norm(Yi(I) - y(I),1);
            end
        end
        
        function [] = train(obj,distMat)
            useOrig = obj.get('useOrig');
            reg = obj.get('reg');     
            if useOrig
                numSources = length(unique(distMat.instanceIDs))-1;                 
                if obj.get('oracle')
                    beta = zeros(numSources+1,1);
                    beta(1:2) = reg;
                    obj.set('beta',beta);
                    return;
                end                     
                if reg == 0
                    beta = zeros(numSources+1,1);
                    beta(1) = 1;
                    obj.set('beta',beta);
                    return;
                end   
            else
                numSources = length(obj.sourceHyp);
                if obj.get('oracle')
                    beta = zeros(numSources,1);
                    beta(1) = reg;
                    obj.set('beta',beta);
                    return;
                end                     
                if reg == 0
                    obj.set('beta',zeros(numSources,1));
                    return;
                end   
            end
                      
                            
            useNW = obj.get('useNW');
            makeRBF = false;
            [Wrbf,~,~,Y_testCleared,~] = obj.makeLLGCMatrices(distMat,~makeRBF);
            Y = Y_testCleared;
            numLabels = max(Y);
            n = size(Wrbf,1);
            alpha = obj.get('alpha');
            if useNW
                L = LLGC.make_L(Wrbf);
            end            
            
            if ~useOrig
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
            end
            
            I = ~isnan(Y);
            Ymat = Helpers.createLabelMatrix(Y);            
            
            if useNW
                Wrbf = Wrbf - diag(diag(Wrbf));
                Wrbf = Wrbf(:,I);
                d = sum(Wrbf,2);
                J = d < 1e-8;
                d(J) = 1;
                M = diag(1 ./ d) * Wrbf;
                invL = eye(size(M,1));
                if ~useOrig
                    Ftarget = M*Ymat(I,:);
                    pc = ProjectConfigs.Create();
                    assert(pc.dataSet == Constants.TOMMASI_DATA);
                    Ftarget(J,[10 15]) = .5;
                    Ftarget = (1-reg)*Ftarget;
                end
                targetInds = find(distMat.isLabeled() & distMat.instanceIDs == 0 ...
                    & distMat.isTargetTrain());
                numTarget = length(targetInds);
                dataSetOffset = 1;
                instanceIDs = distMat.instanceIDs;
                Ytarget = Ymat(targetInds,:);
            else                
                %invL = inv(L + (alpha+numSources)*eye(size(L)));
                invL = inv(L + alpha*eye(size(L)));    
                invL = invL - diag(diag(invL));
                if ~useOrig
                    Ftarget = invL*alpha*Ymat;
                end
            end    
            hinge = @(x) sum(sum(max(0,1-x)));
            if useOrig
                assert(~obj.get('hinge'));
                warning off
                cvx_begin quiet
                    variable b(numSources+1)
                    variable bDup(n)
                    variable F(numTarget,numLabels)
                    variable Yb(n,numLabels)
                    minimize(norm(vec(F-Ytarget),1))
                    subject to             
                        b >= 0
                        b(1) == 1 - reg
                        b <= 1
                        norm(b(2:end),1) <= reg                                

                        bDup == b(instanceIDs+dataSetOffset)
                        Yb == Ymat.*repmat(bDup,1,numLabels)                            

                        for idx=1:numTarget                                
                            F(idx,:) == M(targetInds(idx),:)*Yb(I,:);
                        end
                cvx_end  
                warning on
            else
                warning off
                cvx_begin quiet
                    variable F(n,numLabels)             
                    variable FbTemp(n,numLabels)
                    variable b(numSources,1)
                    variable bRep(numLabels*numSources,numLabels)
                    %variable c
                    %minimize(norm(F(I,[10 15])-Ymat(I,[10 15]) + c,1))
                    %minimize(norm(F(I,:)-Ymat(I,:),1))
                    if obj.get('hinge')
                        %minimize(hinge(F(I,:)-Ymat(I,:)))
                        minimize(norm(F(I,:)-Ymat(I,:),1))
                    else
                        minimize(norm(F(I,:)-10*Ymat(I,:),1))                       
                    end
                    subject to
                        b >= 0
                        %b <= 1
                        norm(b,1) <= reg
                        %sum(b) == reg
                        bRep == sparse(betaRowIdx,betaColIdx,b(betaIdx))                    
                        F == Ftarget + invL*fuCombined*bRep
                cvx_end  
                warning on
            end
            %fuCombined(:,10)
            %full(F(:,[10 15]))
            b
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
            if obj.get('useBaseNW')
                nwMethod = NWMethod(obj.configs);
                assert(obj.get('noTransfer') ~= 0);
                Y = distMat.Y;
                Y(distMat.isTargetTest) = nan;
                nwMethod.train(distMat.X,Y);
                [y,fu] = nwMethod.predict(distMat.X);
                return;
            end
            useOrig = obj.get('useOrig');
            makeRBF = false;
            [Wrbf,~,~,Y_testCleared,~] = obj.makeLLGCMatrices(distMat,~makeRBF);
            beta = obj.get('beta');
            Y = Helpers.createLabelMatrix(Y_testCleared);
            numLabels = max(distMat.classes);
            if useOrig
                I = ~isnan(Y_testCleared);
                Wrbf = Wrbf(distMat.instanceIDs==0,I);
                dinv = 1 ./ sum(Wrbf,2);
                M = diag(dinv)*Wrbf;
                instanceIDs = distMat.instanceIDs(I) + 1;
                Y = Y(I,:);
                fu = M*(Y .* repmat(beta(instanceIDs),1,numLabels));
            else
                if obj.get('useNW')
                    isLabeled = ~isnan(Y_testCleared);
                    Wrbf = Wrbf(:,isLabeled);
                    M = diag(1 ./ sum(Wrbf,2))*Wrbf;
                    fu = (1-obj.get('reg'))*M * Y(isLabeled,:);
                else
                    L = LLGC.make_L(Wrbf);
                    alpha = obj.get('alpha');
                    M = L + eye(size(L))*(sum(beta) + alpha);
                    fu = Y*alpha;
                end
                for idx=1:length(obj.sourceHyp)
                    assert(~isempty(distMat.X));
                    [Yi,FUi] = obj.sourceHyp{idx}.predict(distMat.X);
                    %Y = Y + beta(idx)*Helpers.createLabelMatrix(Yi,size(Y,2));
                    fu = fu + beta(idx)*FUi;
                end
                if ~obj.get('useNW')
                    error('is this the right place for this?');
                    fu = M\Y;
                end                
            end    
            I = ~(fu(:) >= 0);
            if any(I)
                fu(I);
                fu(I) = rand(sum(I),1);
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
            useOrig = obj.get('useOrig');
            testResults = FoldResults(); 
            if useOrig
                I = distMat.instanceIDs == 0;
                testResults.dataType = distMat.type(I);
                testResults.yActual = distMat.trueY(I);
            else
                testResults.dataType = distMat.type;
                testResults.yActual = distMat.trueY;
            end
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
            %nwSigmas = .03;            
            nwSigmas = obj.get('cvSigma');
            %nwSigmas = 4;
            
            if obj.get('newZ')
                n = size(train.X,1);
                Xall = zscore([train.X ; test.X]);
                train.X = Xall(1:n,:);
                test.X = Xall(n+1:end,:);
            end

            if isempty(obj.sourceHyp) && ~obj.get('useBaseNW') && ...
                    ~obj.get('noTransfer') && ~obj.get('useOrig');
                for idx=1:length(sourceDataSetIDs)
                    nwObj = NWMethod();
                    nwObj.set('sigma',nwSigmas);
                    nwObj.set('measure',Measure());
                    nwObj.set('classification',true);
                    nwObj.set('newZ',obj.get('newZ'));
                    I = train.instanceIDs == sourceDataSetIDs(idx);
                    X = train.X(I,:);
                    Y = train.Y(I,:);
                    nwObj.train(X,Y);
                    obj.sourceHyp{idx} = nwObj;
                end
            end
            targetTrain = train.copy();
            if ~obj.get('useOrig')
                targetTrain.remove(targetTrain.instanceIDs ~= 0);
            end
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
            if obj.get('oracle')
                cvParams(1).values = {.5};
                if pc.dataSet == Constants.NG_DATA
                    cvParams(1).values = {0};
                end
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
            if obj.get('useOrig')
                numSplits = 10;
                splits = {};
                percArray = [.8 .2 0];
                Y = targetTrain.Y;
                Y(targetTrain.isTargetTest()) = nan;
                I = targetTrain.instanceIDs == 0;
                for idx=1:numSplits
                    s = LabeledData.generateSplit(...
                        percArray,Y(I));
                    split = ones(size(Y));
                    split(I) = s;                    
                    assert(all(split(~I) == 1));
                    splits{idx} = split;
                end
                cv.splits = splits;
            end
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
            beta = obj.get('beta');
            testResults.learnerStats.dataSetWeights = beta;
        end
        function [prefix] = getPrefix(obj)
            prefix = 'HypTran';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
            if obj.get('noTransfer',false)
                nameParams{end+1} = 'noTransfer';
            end
            if length(obj.get('cvAlpha')) == 1 && ~obj.get('useNW')
                nameParams{end+1} = 'alpha';
            end
            if length(obj.get('cvSigma')) == 1
                nameParams{end+1} = 'sigma';
            end
            if length(obj.get('cvReg')) == 1
                nameParams{end+1} = 'reg';
            end
            if obj.get('useNW',0)
                nameParams{end+1} = 'useNW';
            end
            if obj.get('useBaseNW',0)
                nameParams{end+1} = 'useBaseNW';
            end
            if obj.get('newZ',0)
                nameParams{end+1} = 'newZ';
            end
            if obj.get('oracle',0)
                nameParams{end+1} = 'oracle';
            end
            if obj.get('useOrig',0)
                nameParams{end+1} = 'useOrig';
            end
            if obj.get('hinge',0)
                nameParams{end+1} = 'hinge';
            end
        end 
    end
    
end

