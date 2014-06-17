classdef HFMethod < Method
    %SCMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = HFMethod(configs)
            obj = obj@Method(configs);
        end
        
        function [testResults,metadata,savedData] = ...
                trainAndTestGraphMethod(obj,input,useHF,savedData)
            train = input.train;
            test = input.test;
            %validate = input.validate;
            experiment = input.configs;            
            
            testResults = struct();   
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
                if input.sharedConfigs('zscore')
                    Xall = zscore(Xall);
                end
                Y = [train.Y(trainLabeled) ; ...
                    train.Y(~trainLabeled) ; ...
                    test.Y];
                %{
                type = [ones(size(XLabeled,1),1)*Constants.TARGET_TRAIN ;...
                    ones(size(train.X(~trainLabeled,:),1),1)*Constants.TARGET_TRAIN ; ...
                    ones(size(test.X,1),1)*Constants.TARGET_TEST];                                
                    %}
                type = [train.type(trainLabeled);...
                    train.type(~trainLabeled);...
                    test.type];                
                testResults.trainType = type(1:length(train.type));
                testResults.testType = type(length(train.type)+1:end);
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
                    sigma = obj.configs('sigma');
                else
                    sigma = GraphHelpers.autoSelectSigma(W.W,...
                        Y_testCleared,...
                        ~isTest,...
                        obj.configs('useMeanSigma'),useHF,type);
                end
                numSourceLabeled = sum(type == Constants.SOURCE & Y > 0);
                display(['NumSourceLabeled: ' num2str(numSourceLabeled)]);
                W = Helpers.distance2RBF(W.W,sigma);
                isSource = type == Constants.SOURCE;
                isTrain = type == Constants.TARGET_TRAIN;
                numSource = sum(isSource);
                numTrain = sum(isTrain);
                source2test = W(isSource,isTest);
                train2test = W(isTrain,isTest);
                mean(source2test(:))
                mean(train2test(:))
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
            metadata = struct();
            metadata.sigma = sigma;
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
                testResults.trainFU = fu(~isYTest,:);
                testResults.testFU = fu(isYTest,:);
            end
            val = sum(predicted == YTest)/...
                    length(YTest);
            if useHF
                display(['HFMethod Acc: ' num2str(val)]);
            else
                display(['LLGCMethod Acc: ' num2str(val)]);
            end
            testResults.testPredicted = predicted;
            testResults.testActual = YTest;
            testResults.trainPredicted = train.Y;
            testResults.trainActual = train.Y; 
            testResults.sigma = sigma;
        end
        
        function [testResults,metadata] = ...
                trainAndTest(obj,input)
            useHF = true;
            [testResults,metadata] = ...
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

