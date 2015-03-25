classdef HFMethod < Method
    %SCMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = HFMethod(configs)
            obj = obj@Method(configs);
        end
        
        function [distMat,savedData,Xall] = createDistanceMatrix(obj,train,test,useHF,learnerConfigs,makeRBF,savedData,V)
            if useHF    
                error('Caching assumes ordering doesn''t change');
                trainLabeled = train.Y > 0;
            else
                %TODO: Ordering doesn't matter for LLGC - maybe rename
                %variable to make this code more clear?
                trainLabeled = true(length(train.Y),1);
            end            
            Y = [train.Y(trainLabeled) ; ...
                train.Y(~trainLabeled) ; ...
                test.Y];
            type = [train.type(trainLabeled);...
                train.type(~trainLabeled);...
                test.type];                                
            trueY = [train.trueY(trainLabeled) ; ...
                train.trueY(~trainLabeled) ; ...
                test.trueY];
            instanceIDs = [train.instanceIDs(trainLabeled) ; ...
                train.instanceIDs(~trainLabeled) ; ...
                test.instanceIDs];
            if obj.has('sigmaScale')
                sigmaScale = obj.get('sigmaScale');
            end
            if exist('savedData','var') && isfield(savedData,'W')
                W = savedData.W;
            else
                XLabeled = train.X(trainLabeled,:);
                XUnlabeled = [train.X(~trainLabeled,:) ; test.X];
                Xall = [XLabeled ; XUnlabeled];                  
                if learnerConfigs.get('zscore')
                    Xall = zscore(Xall);
                end   
                %TODO: I turned this off because it was causing bugs elsewhere
                if size(Xall,2) == 1 && false
                    [Xall,inds] = sort(Xall,'ascend');
                    Y = Y(inds);
                    type = type(inds);
                    trueY = trueY(inds);
                    instanceIDs = instanceIDs(inds);       
                    if exists('V','var')
                        error('');
                    else
                        W = Helpers.CreateDistanceMatrix(Xall);
                    end
                    error('check makeRBF');
                elseif obj.has('useSeparableDistanceMatrix') && ...
                        obj.get('useSeparableDistanceMatrix')
                    assert(makeRBF);
                    W = zeros(size(Xall,1));
                    for featureIdx=1:size(Xall,2)
                        W_i = full(Helpers.CreateDistanceMatrix(Xall(:,featureIdx)));
                        sigma_i = sigmaScale*mean(W_i(:));          
                        if sigma_i == 0
                            continue;
                        end
                        a = Helpers.distance2RBF(W_i,sigma_i)./size(Xall,2);
                        %a = W_i.^2;
                        %a = -a ./ (2*sigma_i^2);
                        assert(all(~isnan(a(:))));
                        assert(all(~isinf(a(:))));
                        W = W + a;
                    end
                    %W = exp(W);
                else
                    if exist('V','var')
                        WDist = Helpers.CreateDistanceMatrixMahabolis(Xall,V);
                    else
                        WDist = Helpers.CreateDistanceMatrix(Xall);
                    end
                    if makeRBF
                        sigma = sigmaScale*mean(WDist(:));
                        W = Helpers.distance2RBF(WDist,sigma);
                    else
                        W = WDist;
                    end
                    
                    if any(isnan(W(:)))
                        warning('');
                    end
                    %{
                    if obj.has('Wsparsity')
                        W = Helpers.SparsifyDistanceMatrix(W,obj.get('Wsparsity'));
                    end
                    %}
                end    
                if exist('savedData','var')
                    savedData.W = W;
                end
            end
            distMat = DistanceMatrix(W,Y,type,trueY,instanceIDs);
        end
        
        function [fu, fu_CMN,sigma] = runHarmonicFunction(obj,distMat)
            %error('Make Sure this still works!');
            [W,Y,isTest,type,perm] = distMat.prepareForHF();
            assert(issorted(perm));
            Y_testCleared = Y;
            Y_testCleared(isTest) = -1;
            if isKey(obj.configs,'sigma')
                sigma = obj.configs('sigma');
            elseif obj.has('sigmaScale')
                sigma = distMat.meanDistance * obj.get('sigmaScale');
            else
                sigma = GraphHelpers.autoSelectSigma(W,Y_testCleared,~isTest,obj.configs('useMeanSigma'),useHF,type);
            end
            W = Helpers.distance2RBF(W,sigma);
            isTrainLabeled = Y > 0 & ~isTest;
            assert(~issorted(isTrainLabeled));
            YTrain = Y(isTrainLabeled);
            YLabelMatrix = Helpers.createLabelMatrix(YTrain);
            addpath(genpath('libraryCode'));
            [fu, fu_CMN] = harmonic_function(W, YLabelMatrix);
            fu = [YLabelMatrix ; fu];
            fu_CMN = [YLabelMatrix ; fu_CMN];
        end
        
        function [Wrbf,YtrainMat,sigma,Y_testCleared,instanceIDs] = makeLLGCMatrices(obj,distMat)
            isTest = distMat.type == Constants.TARGET_TEST;
            Y_testCleared = distMat.Y;
            Y_testCleared(isTest) = -1;
            YtrainMat = full(Helpers.createLabelMatrix(Y_testCleared));
            useHF = false;
            if isKey(obj.configs,'sigma')
                sigma = obj.configs.get('sigma');
            elseif isKey(obj.configs,'sigmaScale')
                sigma = obj.configs.get('sigmaScale')*distMat.meanDistance;
            else
                WtestCleared = DistanceMatrix(distMat.W,Y_testCleared,...
                    distMat.type,distMat.trueY,distMat.instanceIDs);
                sigma = GraphHelpers.autoSelectSigma(WtestCleared, ...
                    obj.configs.get('useMeanSigma'),useHF);
            end
            Wrbf = Helpers.distance2RBF(distMat.W,sigma);
            if any(isnan(Wrbf))
                warning('Nan in Wrbf');
            end
            %Wrbf = Helpers.SparsifyDistanceMatrix(Wrbf,obj.get('k'));
            instanceIDs = distMat.instanceIDs;
        end
        
        function [score,percCorrect,Ypred,Yactual,labeledTargetScores,savedData] ...
                = LOOCV(similarityDistMat,useHF,savedData)
            if ~exist('useHF','var')
                useHF = false;
            end
            if exist('savedData','var')
                [score,percCorrect,Ypred,Yactual,labeledTargetScores,savedData] ...
                = GraphHelpers.LOOCV(similarityDistMat,useHF,savedData);
            else
                [score,percCorrect,Ypred,Yactual,labeledTargetScores,savedData] ...
                = GraphHelpers.LOOCV(similarityDistMat,useHF);
            end
        end
        
        function [fu,savedData,sigma] = runBandedLLGC(obj,distMat,savedData)
            [Wrbf,YtrainMat,sigma] = makeLLGCMatrices(obj,distMat);
            
            n = size(Wrbf,1);
            s = ceil(sqrt(n));            
            diagonals = spdiags(Wrbf,-s:s);
            WrbBanded = spdiags(diagonals,-s:s,n,n);            
            %{
            tic
            [fu] = LLGC.llgc_LS(Wrbf, YtrainMat,obj.get('alpha'));
            toc
            tic
            [fu] = LLGC.llgc_LS(WrbBanded, YtrainMat,obj.get('alpha'));
            toc
            %}
            [fu] = LLGC.llgc_LS(WrbBanded, YtrainMat,obj.get('alpha'));
            fu(isnan(fu(:))) = 0;
            assert(isempty(find(isnan(fu))));
        end
        
        function [fu,savedData,sigma] = runLLGC(obj,distMat,makeRBF,savedData)

            [Wrbf,YtrainMat,sigma] = makeLLGCMatrices(obj,distMat);
            if makeRBF
                Wrbf = distMat.W;
            end
            alpha = obj.get('alpha');
            alphaScores = zeros(size(alpha));
            numFolds = 10;
            isLabeled = distMat.isLabeledTarget() & distMat.isTargetTrain();
            labeledInds = find(isLabeled);
            Ytrain = distMat.Y(isLabeled);
            if length(alpha) > 1
                folds = {};
                for foldIdx=1:numFolds
                    folds{foldIdx} = DataSet.generateSplit([.8 .2],Ytrain) == 1;
                end       
                savedData = [];
                %WN = LLGC.make_WN(Wrbf);
                %[V,D,U] = svd(WN);            
                %{
                L = LLGC.make_L(Wrbf);
                [V,D,U] = svd(L);
                %Code from https://www.mathworks.com/matlabcentral/newsreader/view_thread/312556
                d=diag(V'*L*V);
                D=D*spdiags(sign(d.*diag(D)),0,size(V,2),size(V,2));
                %L_recon = U*D*U';
                
                I = eye(size(L));
                %}
                for alphaIdx=1:length(alpha)
                    currAlpha = alpha(alphaIdx);                    
                    %invM = currAlpha*U*inv(D + currAlpha*I)*U';
                    for foldIdx=1:numFolds                        
                        isTrain = folds{foldIdx};
                        isTest = ~isTrain;
                        %isTrainInds = labeledInds(isTrain);
                        testInds = labeledInds(~isTrain);
                        YtrainCurr = distMat.Y;
                        YtrainCurr(testInds) = -1;
                        YtrainCurr(~isLabeled) = -1;
                        YtrainMatCurr = Helpers.createLabelMatrix(YtrainCurr);
                        
                        if exist('savedData','var') && isfield(savedData,'invM')
                            [fu] = LLGC.llgc_inv(Wrbf, YtrainMatCurr, currAlpha, savedData.invM);
                            %fu2 = LLGC.llgc_inv(Wrbf, YtrainMatCurr, currAlpha, invM2);
                            %[fu(:,2) fu2(:,2)]
                        else
                            [fu] = LLGC.llgc_LS(Wrbf, YtrainMatCurr, currAlpha);                            
                            if exist('savedData','var')
                                savedData.invM = LLGC.makeInvM(Wrbf,currAlpha);
                            else
                                savedData = [];
                            end
                        end
                        
                        
                        %fu = LLGC.llgc_inv(Wrbf, YtrainMatCurr, currAlpha, invM);
                        fuTest = fu(testInds,:);
                        if size(fuTest,2) > 1
                            fuTest = Helpers.RemoveNullColumns(fuTest);
                        end
                        %[~,yPred] = max(fuTest,[],2);                        
                        classes = distMat.classes;
                        if size(fuTest,2) > length(classes)
                            classes = 1:max(distMat.classes);
                        end
                        yPred = LLGC.getPrediction(fuTest,classes);
                        yActual = Ytrain(isTest);
                        accVec = yPred == yActual;
                        alphaScores(alphaIdx) = alphaScores(alphaIdx) + mean(accVec);                        
                    end
                    %norm(savedData.invM - invM2)                    
                    %norm(invM2 - invM)/norm(invM)
                    if exist('savedData','var') && isfield(savedData,'invM')
                        savedData = rmfield(savedData,'invM');
                    end
                end
                alphaScores = alphaScores ./ numFolds;
                alpha = alpha(argmax(alphaScores));
            end
            %{
            if exist('savedData','var') && isfield(savedData,'invM')
                [fu] = LLGC.llgc_inv(Wrbf, YtrainMat, alpha, savedData.invM);
            else
                [fu] = LLGC.llgc_LS(Wrbf, YtrainMat, alpha);
                if exist('savedData','var')
                    savedData.invM = LLGC.makeInvM(Wrbf,alpha);
                else
                    savedData = [];
                end
            end
            %}
            savedData.invM = LLGC.makeInvM(Wrbf,alpha);
            [fu] = LLGC.llgc_inv([], YtrainMat, alpha,savedData.invM);
            
            savedData.alpha = alpha;
            savedData.featureSmoothness = LLGC.smoothness(Wrbf,distMat.trueY);
            savedData.cvAcc = max(alphaScores);
            fu(isnan(fu(:))) = 0;

            assert(isempty(find(isnan(fu))));
        end
        
        function [testResults,savedData] = ...
                trainAndTestGraphMethod(obj,input,useHF,savedData)
            train = input.train;
            test = input.test;   
            %learner = input.configs.learner;
            testResults = FoldResults();   
            makeRBF = true;
            if isfield(input,'distanceMatrix')
                distMat = input.distanceMatrix;
                error('Possible bug - is this taking advantage of source data?');
            else                
                %[distMat] = createDistanceMatrix(obj,train,test,useHF,makeRBF,learner.configs);
                if exist('savedData','var')
                    [distMat,savedData] = createDistanceMatrix(obj,train,test,useHF,obj.configs,makeRBF,savedData);
                else
                    [distMat] = createDistanceMatrix(obj,train,test,useHF,obj.configs,makeRBF);
                end
                testResults.dataType = distMat.type;
            end
            if useHF
                error('Is distMat a distanceMatrix or Wrbf?');
                [fu, fu_CMN,sigma] = runHarmonicFunction(obj,distMat);
            else
                if exist('savedData','var')
                    [fu,savedData,sigma] = runLLGC(obj,distMat, makeRBF, savedData);
                else
                    [fu,savedData,sigma] = runLLGC(obj,distMat, makeRBF);
                end
            end
            predicted = LLGC.getPrediction(fu,distMat.classes);
            %{
            [maxVal,predicted] = max(fu,[],2);
            
            %Sometimes fu(i,:) will be all 0, resulting in '1' always being
            %predicted
            %Replace invalid predictions with random value
            invalidPrediction = maxVal == 0;
            
            %Hackish - need to know which classes are allowed
            actualClasses = unique(predicted(~invalidPrediction));
            predicted(maxVal == 0) = randsample(actualClasses,nnz(invalidPrediction),true);
            
            numNan = sum(isnan(fu(:)));
            if numNan > 0
                display(['numNan: ' num2str(numNan)]);
            end
            %}
            %{
            if useHF
                %distMat entries should be sorted properly
                isYTest = distMat.Y > 0 & distMatisTest;
                YTest = Y(isYTest);            
                numTrainLabeled = sum(isTrainLabeled);
                predicted = predicted(isYTest(numTrainLabeled+1:end));    
                testResults.trainFU = sparse(fu(~isYTest,:));
                testResults.testFU = sparse(fu(isYTest,:));
                error('Update for unlabeled source, make sure indices are correct!');
            else
                isYTest = distMat.Y > 0 & distMat.type == Constants.TARGET_TEST;
                YTest = distMat.Y(isYTest);
                predicted = predicted(isYTest);
                testResults.dataFU = sparse([fu(~isYTest,:) ; fu(isYTest,:)]);
            end
            %}
            isYTest = distMat.Y > 0 & distMat.type == Constants.TARGET_TEST;
            
            %test instances should be last
            assert(issorted(isYTest));
            YTest = distMat.Y(isYTest);
            predicted = predicted(isYTest);
            testResults.dataFU = sparse(fu);
            %testResults.dataFU = sparse([fu(~isYTest,:) ; fu(isYTest,:)]);
            val = sum(predicted == YTest)/...
                    length(YTest);
            if ~obj.configs.get('quiet')
                if useHF
                    display(['HFMethod Acc: ' num2str(val)]);
                else
                    display(['LLGCMethod Acc: ' num2str(val)]);
                end
            end            
            testResults.yPred = [train.Y; predicted];
            testResults.yActual = [train.Y; YTest];
            testResults.learnerMetadata.sigma = sigma;
            testResults.learnerStats.featureSmoothness = savedData.featureSmoothness;
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            useHF = true;
            [testResults] = ...
                trainAndTestGraphMethod(obj,input,useHF);
        end
        function [] = updateConfigs(obj, newConfigs)
            %keys = {'sigma', 'sigmaScale','k','alpha'};
            keys = {'sigmaScale','alpha'};
            obj.updateConfigsWithKeys(newConfigs,keys);
        end
        function [prefix] = getPrefix(obj)
            prefix = 'HF';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end        
    
end

