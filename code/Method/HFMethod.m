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
            
            W = Helpers.CreateDistanceMatrix(Xall);            
            distMat = DistanceMatrix(W,Y,type);
        end
        
        function [fu, fu_CMN,sigma] = runHarmonicFunction(obj,distMat)
            error('Make Sure this still works!');
            [distMat,Y,isTest,type] = distMat.prepareForHF();
            Y_testCleared = Y;
            Y_testCleared(isTest) = -1;
            if isKey(obj.configs,'sigma')
                sigma = obj.configs('sigma');
            else
                sigma = GraphHelpers.autoSelectSigma(distMat,Y_testCleared,~isTest,obj.configs('useMeanSigma'),useHF,type);
            end
            distMat = Helpers.distance2RBF(distMat,sigma);
            isTrainLabeled = Y > 0 & ~isTest;
            assert(~issorted(isTrainLabeled));
            YTrain = Y(isTrainLabeled);
            YLabelMatrix = Helpers.createLabelMatrix(YTrain);
            addpath(genpath('libraryCode'));
            [fu, fu_CMN] = harmonic_function(distMat, YLabelMatrix);
        end
        
        function [fu,savedData,sigma] = runLLGC(obj,distMat,savedData)
            isTest = distMat.type == Constants.TARGET_TEST;
            Y_testCleared = distMat.Y;
            Y_testCleared(isTest) = -1;
            Ymat = full(Helpers.createLabelMatrix(Y_testCleared));
            useHF = false;
            if isKey(obj.configs,'sigma')
                sigma = obj.configs.get('sigma');
            elseif isKey(obj.configs,'sigmaScale')
                sigma = obj.configs.get('sigmaScale')*distMat.meanDistance;
            else
                WtestCleared = DistanceMatrix(distMat.W,Y_testCleared,distMat.type);
                sigma = GraphHelpers.autoSelectSigma(WtestCleared, ...
                    obj.configs.get('useMeanSigma'),useHF);
            end
            distMat = Helpers.distance2RBF(distMat.W,sigma);
            distMat = Helpers.SparsifyDistanceMatrix(distMat,obj.get('k'));
            if exist('savedData','var') && isfield(savedData,'invM')
                error('TODO');
                [fu] = LLGC.llgc(distMat, Ymat,savedData.invM);
            else
                [fu] = LLGC.llgc_LS(distMat, Ymat);
                if exist('savedData','var')
                    error('TODO!');
                    savedData.invM = invM;
                    savedData.W = distMat;
                    savedData.Ymat = Ymat;
                else
                    savedData = [];
                end
            end
            fu(isnan(fu(:))) = .5;
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
                error('Make sure this works!');
                [fu, fu_CMN,sigma] = runHarmonicFunction(obj,distMat);
            else
                if exist('savedData','var') && isfield(savedData,'invM')
                    [fu,savedData,sigma] = runLLGC(obj,distMat,savedData);
                else
                    [fu,~,sigma] = runLLGC(obj,distMat);
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
                testResults.trainFU = sparse(fu(~isYTest,:));
                testResults.testFU = sparse(fu(isYTest,:));
                error('Update for unlabeled source, make sure indices are correct!');
            else
                isYTest = distMat.Y > 0 & distMat.type == Constants.TARGET_TEST;
                YTest = distMat.Y(isYTest);
                predicted = predicted(isYTest);
                testResults.dataFU = sparse([fu(~isYTest,:) ; fu(isYTest,:)]);
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

