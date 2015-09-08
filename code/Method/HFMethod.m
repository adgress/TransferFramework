classdef HFMethod < Method
    %SCMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        LLGC = 1
        HFGF = 2
        NW = 3
    end
    properties
        method
    end
    
    methods
        function obj = HFMethod(configs)
            obj = obj@Method(configs);
            obj.method = HFMethod.HFGF;
            if ~obj.has('makeRBF')
                obj.set('makeRBF',true);
            end
            if ~obj.has('zscore')
                obj.set('zscore',false);
            end
            if ~obj.has('newZ')
                obj.set('newZ',false);
            end
        end
        
        function [distMat,savedData,Xall] = createDistanceMatrix(obj,train,test,learnerConfigs,makeRBF,savedData,V)
            if obj.method == HFMethod.HFGF
                error('Caching assumes ordering doesn''t change');
                trainLabeled = train.isLabeled()
            else
                %TODO: Ordering doesn't matter for LLGC - maybe rename
                %variable to make this code more clear?
                trainLabeled = true(length(train.Y),1);
            end            
            if isempty(test)
                test = DataSet();
                test.X = zeros(0,size(train.X,2));
            end
            WNames = [];
            WIDs = [];
            Y = [train.Y(trainLabeled,:) ; ...
                train.Y(~trainLabeled,:) ; ...
                test.Y];
            type = [train.type(trainLabeled);...
                train.type(~trainLabeled);...
                test.type];                                
            trueY = [train.trueY(trainLabeled,:) ; ...
                train.trueY(~trainLabeled,:) ; ...
                test.trueY];
            instanceIDs = [train.instanceIDs(trainLabeled) ; ...
                train.instanceIDs(~trainLabeled) ; ...
                test.instanceIDs];
            objectType = [];
            labelSets = train.labelSets;
            YNames = train.YNames;
            instancesToInfer = [];
            if obj.has('sigmaScale')
                sigmaScale = obj.get('sigmaScale');
            end
            if ~isempty(train.W)
                assert(isempty(train.X));      
                %combined = DataSet.Combine(train,test);                
                combined = train.copy();
                %combined.W = train.W;
                I1 = combined.isLabeled;
                I2 = combined.isTargetTrain();
                %perm = [find(I1 & I2) ; find(~I1 & I2) ; find(~I2)];                
                %combined.applyPermutation(perm);
                f = obj.configs.get('combineGraphFunc',[]);
                if ~isempty(f)                    
                    combined = f(combined);
                    W = combined.W;
                else
                    assert(length(combined.W) == 1);
                    W = combined.W{1};
                end
                
                
                %if makeRBF && obj.get('makeRBF',true);
                %{
                    sigma = obj.get('sigma');
                    W2 = W;
                    W = Helpers.distance2RBF(W,sigma);
                %}
                %end
                
                Y = combined.Y;
                type = combined.type;
                trueY = combined.trueY;
                instanceIDs = combined.instanceIDs;                                                
                WIDs = combined.WIDs;
                WNames = combined.WNames;
                labelSets = combined.labelSets;
                objectType = combined.objectType;
                YNames = combined.YNames;
                instancesToInfer = combined.instancesToInfer;
            elseif exist('savedData','var') && isfield(savedData,'W')
                W = savedData.W;
                error('Data ordering issue with caching?');
            else
                %warning('Data ordering issue with caching?');
                XLabeled = train.X(trainLabeled,:);
                XUnlabeled = [train.X(~trainLabeled,:) ; test.X];
                Xall = [XLabeled ; XUnlabeled];                  
                if learnerConfigs.get('zscore') && ~obj.get('newZ');
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
                    error('');
                    error('Don''t make RBF here?');
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
                    %warning('Don''t make RBF here?');
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
                %warning('Applying sigma twice?');
            end
            
            distMat = DistanceMatrix(W,Y,type,trueY,instanceIDs);
            distMat.X = Xall;
            distMat.WNames = WNames;
            distMat.WIDs = WIDs;
            distMat.labelSets = labelSets;
            if isempty(objectType)
                assert(isempty(train.objectType));
            end
            distMat.objectType = objectType;
            distMat.YNames = YNames;
            distMat.instancesToInfer = instancesToInfer;
        end
        
        function [fu, fu_CMN,sigma] = runHarmonicFunction(obj,distMat)
            %error('Make Sure this still works!');
            [W,Y,isTest,type,perm] = distMat.prepareForHF();
            assert(issorted(perm));
            Y_testCleared = Y;
            Y_testCleared(isTest) = nan;
            if isKey(obj.configs,'sigma')
                sigma = obj.configs('sigma');
            elseif obj.has('sigmaScale')
                sigma = distMat.meanDistance * obj.get('sigmaScale');
            else
                sigma = GraphHelpers.autoSelectSigma(W,Y_testCleared,~isTest,obj.configs('useMeanSigma'),type);
            end
            W = Helpers.distance2RBF(W,sigma);
            isTrainLabeled = ~isnan(Y) & ~isTest;
            assert(~issorted(isTrainLabeled));
            YTrain = Y(isTrainLabeled);
            YLabelMatrix = Helpers.createLabelMatrix(YTrain);
            addpath(genpath('libraryCode'));
            [fu, fu_CMN] = harmonic_function(W, YLabelMatrix);
            fu = [YLabelMatrix ; fu];
            fu_CMN = [YLabelMatrix ; fu_CMN];
        end
        
        function [Wrbf,YtrainMat,sigma,Y_testCleared,instanceIDs] = makeLLGCMatrices(obj,distMat,makeRBF)
            isReg = distMat.isRegressionData;
            %error('What if sigma has already been selected?');
            isTest = distMat.type == Constants.TARGET_TEST;
            Y_testCleared = distMat.Y;
            Y_testCleared(isTest) = nan;
            if isReg
                YtrainMat = full(Y_testCleared);
                YtrainMat(isnan(YtrainMat(:))) = 0;
            else
                YtrainMat = full(Helpers.createLabelMatrix(Y_testCleared));
            end
            if makeRBF
                if isKey(obj.configs,'sigma') && ~isempty(obj.configs.get('sigma'))
                    sigma = obj.configs.get('sigma');
                elseif isKey(obj.configs,'sigmaScale')
                    sigma = obj.configs.get('sigmaScale')*distMat.meanDistance;
                else
                    WtestCleared = DistanceMatrix(distMat.W,Y_testCleared,...
                        distMat.type,distMat.trueY,distMat.instanceIDs);
                    sigma = GraphHelpers.autoSelectSigma(WtestCleared, ...
                        obj.configs.get('useMeanSigma'),obj.method == HFMethod.HFGF);
                end
                Wrbf = Helpers.distance2RBF(distMat.W,sigma);
            else 
                Wrbf = distMat.W;
                sigma = [];
            end
            if any(isnan(Wrbf))
                warning('Nan in Wrbf');
            end
            %Wrbf = Helpers.SparsifyDistanceMatrix(Wrbf,obj.get('k'));
            instanceIDs = distMat.instanceIDs;
        end
        
        function [score,percCorrect,Ypred,Yactual,labeledTargetScores,savedData] ...
                = LOOCV(similarityDistMat,savedData)
            useHF = obj.method == HFMethod.HFGF;
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
            hasInvM = exist('savedData','var') && isfield(savedData,'invM');
            if obj.get('useInv') && hasInvM
                %{
                isTest = distMat.type == Constants.TARGET_TEST;
                Y_testCleared = distMat.Y;
                Y_testCleared(isTest) = nan;
                YtrainMat = full(Helpers.createLabelMatrix(Y_testCleared));
                %}
                sigma = obj.get('sigma');
            else
                isZero = distMat.W(:) == 0;
                a = distMat.W;
                %distMat.W = Helpers.SimilarityToDistance(distMat.W);                                    
                [Wrbf,YtrainMat,sigma] = makeLLGCMatrices(obj,distMat,makeRBF);            
                %Wrbf = a;
                Wrbf(isZero) = 0;
            end
            isTest = distMat.type == Constants.TARGET_TEST;
            Y_testCleared = distMat.Y;
            Y_testCleared(isTest) = nan;
            YtrainMat = Y_testCleared;
            useAlt = obj.get('useAlt');
            alpha = obj.get('alpha');
            isReg = distMat.isRegressionData;
            if useAlt
                [fu, savedData.invM] = LLGC.llgc_inv_alt(Wrbf, YtrainMat, alpha);
            else
                if obj.get('useInv')
                    if ~hasInvM
                        savedData.invM = LLGC.makeInvM(Wrbf,alpha);            
                    end
                    [fu] = LLGC.llgc_inv([], YtrainMat, alpha,savedData.invM,isReg);
                else
                    assert(~isReg);
                    if obj.get('inferSubset')
                        assert(~isempty(distMat.instancesToInfer));
                        [fu] = LLGC.llgc_LS(Wrbf, YtrainMat, alpha,distMat.instancesToInfer);
                    else
                        [fu] = LLGC.llgc_LS(Wrbf, YtrainMat, alpha);
                    end
                end
            end
            I = sum(fu,2) == 0;
            fu(I,:) = .5;
            savedData.alpha = alpha;
            %savedData.featureSmoothness = LLGC.smoothness(Wrbf,distMat.trueY);         
            if ~exist('classes','var')
                classes = distMat.classes;
            end
            labelSets = distMat.labelSets;
            if distMat.isRegressionData
                savedData.predicted = fu;
            else
                savedData.predicted = LLGC.getPrediction(fu,classes,YtrainMat,labelSets);
            end
            fu(isnan(fu(:))) = .5;
            assert(isempty(find(isnan(fu))));
        end
        
        function [testResults,savedData] = runMethod(obj,input,savedData)
            train = input.train;
            test = input.test;   
            %learner = input.configs.learner;
            testResults = FoldResults();   
            makeRBF = obj.get('makeRBF');
            if ~exist('savedData','var')
                savedData = struct();
            end
            if isfield(input,'distanceMatrix')
                distMat = input.distanceMatrix;
                error('Possible bug - is this taking advantage of source data?');
            else               
                [distMat,savedData] = createDistanceMatrix(obj,train,test,obj.configs,~makeRBF,savedData);
            end
            distMatOrig = distMat.copy();
            switch obj.method
                case HFMethod.HFGF
                    error('Is distMat a distanceMatrix or Wrbf?');
                    [fu, fu_CMN,sigma] = runHarmonicFunction(obj,distMat);
                case HFMethod.LLGC
                    [fu,savedData,sigma] = runLLGC(obj,distMat, makeRBF, savedData);
                case HFMethod.NW
                    [fu,savedData,sigma] = runNW(obj,distMat,makeRBF,savedData);
                otherwise
                    error('unknown method');
            end
            predicted = savedData.predicted;     
            isYTest = distMat.isLabeled & distMat.type == Constants.TARGET_TEST;
            
            %test instances should be last
            %assert(issorted(distMat.type == Constants.TARGET_TEST));
            YTest = distMatOrig.Y(isYTest);
            testResults.dataFU = sparse(fu);
            testResults.labelSets = distMatOrig.labelSets;
            testResults.dataType = distMatOrig.type;
            %testResults.dataFU = sparse([fu(~isYTest,:) ; fu(isYTest,:)]);
            assert(~isempty(YTest));
            if ~isempty(YTest)
                f = obj.get('evaluatePerfFunc',[]);
                if ~isempty(f)                    
                    [val,yPred,yActual] = f(distMatOrig,fu,savedData.predicted);
                else               
                    %{
                    yTestPred = predicted(isYTest);
                    val = sum(yTestPred == YTest)/...
                            length(YTest);
                    %}
                    yPred = predicted;
                    yActual = distMatOrig.Y;
                    
                end                
                         
            end
            testResults.yPred = yPred;
            testResults.yActual = yActual;
            testResults.learnerMetadata.sigma = sigma;
            a = obj.configs.get('measure').evaluate(testResults);
            savedData.val = a.learnerStats.valTest;
            assert(~isnan(savedData.val));
        end
        
        function [testResults,savedData] = ...
                trainAndTestGraphMethod(obj,input,savedData)
            cv = CrossValidation();
            cv.trainData = input.train.copy();
            cv.parameters = obj.get('cvParameters');
            cv.methodObj = obj;
            cv.measure = obj.get('measure');
            tic
            [bestParams,acc] = cv.runCV();
            toc
            obj.setParams(bestParams);
            [testResults,savedData] = obj.runMethod(input);
            if ~obj.configs.get('quiet')
                display([ obj.getPrefix() ' Acc: ' num2str(savedData.val)]);
            end
            %testResults.learnerStats.featureSmoothness = savedData.featureSmoothness;            
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            [testResults] = ...
                trainAndTestGraphMethod(obj,input);
        end
        function [] = updateConfigs(obj, newConfigs)
            %keys = {'sigma', 'sigmaScale','k','alpha'};
            keys = {'sigmaScale','alpha','sigma'};
            obj.updateConfigsWithKeys(newConfigs,keys);
        end
        function [prefix] = getPrefix(obj)
            prefix = 'HF';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = getNameParams@Method(obj);
        end
        function [d] = getDirectory(obj)
            error('Do we save based on method?');
        end
    end        
    
end

