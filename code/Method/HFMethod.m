classdef HFMethod < Method
    %SCMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = HFMethod(configs)
            obj = obj@Method(configs);
        end
        
        function [distMat] = createDistanceMatrix(obj,train,test,useHF,learnerConfigs)            
            if useHF                
                trainLabeled = train.Y > 0;
            else
                %TODO: Ordering doesn't matter for LLGC - maybe rename
                %variable to make this code more clear?
                trainLabeled = true(length(train.Y),1);
            end
            XLabeled = train.X(trainLabeled,:);
            XUnlabeled = [train.X(~trainLabeled,:) ; test.X];
            Xall = [XLabeled ; XUnlabeled];                  
            if learnerConfigs.get('zscore')
                Xall = zscore(Xall);
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
            
            %TODO: I turned this off because it was causing bugs elsewhere
            if size(Xall,2) == 1 && false
                [Xall,inds] = sort(Xall,'ascend');
                Y = Y(inds);
                type = type(inds);
                trueY = trueY(inds);
                instanceIDs = instanceIDs(inds);                
                W = Helpers.CreateDistanceMatrix(Xall);
            else
                W = Helpers.CreateDistanceMatrix(Xall);
                %{
                if obj.has('Wsparsity')
                    W = Helpers.SparsifyDistanceMatrix(W,obj.get('Wsparsity'));
                end
                %}
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
        
        function [fu,savedData,sigma] = runLLGC(obj,distMat,savedData)
            [Wrbf,YtrainMat,sigma] = makeLLGCMatrices(obj,distMat);
            alpha = obj.get('alpha');
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
            fu(isnan(fu(:))) = 0;
            assert(isempty(find(isnan(fu))));
        end
        
        function [testResults,savedData] = ...
                trainAndTestGraphMethod(obj,input,useHF,savedData)
            train = input.train;
            test = input.test;   
            %learner = input.configs.learner;
            testResults = FoldResults();   
            if isfield(input,'distanceMatrix')
                distMat = input.distanceMatrix;
                error('Possible bug - is this taking advantage of source data?');
            else                
                %[distMat] = createDistanceMatrix(obj,train,test,useHF,learner.configs);
                [distMat] = createDistanceMatrix(obj,train,test,useHF,obj.configs);
                testResults.dataType = distMat.type;
            end
            if useHF
                %error('Make sure this works!');
                [fu, fu_CMN,sigma] = runHarmonicFunction(obj,distMat);
            else
                if exist('savedData','var')
                    [fu,savedData,sigma] = runLLGC(obj,distMat,savedData);
                else
                    [fu,~,sigma] = runLLGC(obj,distMat);
                end
            end
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

