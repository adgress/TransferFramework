classdef HFMethod < Method
    %SCMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = HFMethod(configs)
            obj = obj@Method(configs);
        end
        
        function [testResults,savedData] = ...
                trainAndTestGraphMethod(obj,input,useHF,savedData)
            train = input.train;
            test = input.test;
            %validate = input.validate;
            experiment = input.configs;            
            learner = input.configs.learner;
            testResults = FoldResults();   
            if isfield(input,'distanceMatrix')
                W = input.distanceMatrix;
                error('Possible bug - is this taking advantage of source data?');
            else
                %Ordering matters for HF - not for LLGC
                if useHF
                    error('Make sure this works properly!');
                    trainLabeled = train.Y > 0;
                else
                    trainLabeled = logical(ones(length(train.Y),1));
                end
                XLabeled = train.X(trainLabeled,:);
                XUnlabeled = [train.X(~trainLabeled,:) ; test.X];
                Xall = [XLabeled ; XUnlabeled];      
                if learner.configs.get('zscore')
                    Xall = zscore(Xall);
                end
                Y = [train.Y(trainLabeled) ; ...
                    train.Y(~trainLabeled) ; ...
                    test.Y];
                type = [train.type(trainLabeled);...
                    train.type(~trainLabeled);...
                    test.type];                                
                testResults.dataType = type;
                W = Helpers.CreateDistanceMatrix(Xall);
                W = DistanceMatrix(W,Y,type);
            end
            if useHF
                [W,Y,isTest,type] = W.prepareForHF();
                Y_testCleared = Y;
                Y_testCleared(isTest) = -1;
                if isKey(obj.configs,'sigma')
                    error('Make sure this is correct!');
                    sigma = obj.configs('sigma');
                else
                    error('Make sure this is correct!');
                    sigma = GraphHelpers.autoSelectSigma(W,Y_testCleared,~isTest,obj.configs('useMeanSigma'),useHF,type);
                end
                W = Helpers.distance2RBF(W,sigma);
                isTrainLabeled = Y > 0 & ~isTest;
                assert(~issorted(isTrainLabeled));
                YTrain = Y(isTrainLabeled);
                YLabelMatrix = Helpers.createLabelMatrix(YTrain);
                addpath(genpath('libraryCode'));
                [fu, fu_CMN] = harmonic_function(W, YLabelMatrix);
            else
                isTest = type == Constants.TARGET_TEST;
                Y_testCleared = Y;
                Y_testCleared(isTest) = -1;
                Ymat = full(Helpers.createLabelMatrix(Y_testCleared));
                if isKey(obj.configs,'sigma')
                    sigma = obj.configs.get('sigma');
                else
                    WtestCleared = DistanceMatrix(W.W,Y_testCleared,type);
                    sigma = GraphHelpers.autoSelectSigma(WtestCleared, ...
                        obj.configs.get('useMeanSigma'),useHF);
                end
                numSourceLabeled = sum(type == Constants.SOURCE & Y > 0);
                %display(['NumSourceLabeled: ' num2str(numSourceLabeled)]);
                W = Helpers.distance2RBF(W.W,sigma);
                isSource = type == Constants.SOURCE;
                isTrain = type == Constants.TARGET_TRAIN;
                numSource = sum(isSource);
                numTrain = sum(isTrain);
                source2test = W(isSource,isTest);
                train2test = W(isTrain,isTest);
                %W = Kernel.RBFKernel(W.W,sigma);
                if exist('savedData','var') && isfield(savedData,'invM');
                    %[fu,invM] = llgc(W, Ymat);
                    %norm(W - savedData.W,inf)
                    %norm(invM - savedData.invM,inf)
                    [fu] = llgc(W, Ymat,savedData.invM);                    
                else
                    [fu,invM] = llgc(W, Ymat);
                    if exist('savedData','var')
                        savedData.invM = invM;
                        savedData.W = W;
                        savedData.Ymat = Ymat;
                    end
                end
            end
            [~,predicted] = max(fu,[],2);
            numNan = sum(isnan(fu(:)));
            if numNan > 0
                display(['numNan: ' num2str(numNan)]);
            end
            if useHF
                isYTest = Y > 0 & isTest;
                YTest = Y(isYTest);            
                numTrainLabeled = sum(isTrainLabeled);
                predicted = predicted(isYTest(numTrainLabeled+1:end));    
                testResults.trainFU = fu(~isYTest,:);
                testResults.testFU = fu(isYTest,:);
                error('Update for unlabeled source, make sure indices are correct!');
            else
                isYTest = Y > 0 & type == Constants.TARGET_TEST;
                YTest = Y(isYTest);
                predicted = predicted(isYTest);
                testResults.dataFU = [fu(~isYTest,:) ; fu(isYTest,:)];
            end
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

