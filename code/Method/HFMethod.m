classdef HFMethod < Method
    %SCMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = HFMethod
            %obj = obj@Method();
        end
        function [testResults,metadata] = ...
                trainAndTest(obj,input)
            train = input.train;
            test = input.test;
            %validate = input.validate;
            experiment = input.configs;
            metadata = input.metadata;                                   
            
            testResults = struct();   
            if isfield(input,'distanceMatrix')
                W = input.distanceMatrix;
                error('Possible bug - is this taking advantage of source data?');
            else
                trainLabeled = train.Y > 0;
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
                W = Helpers.CreateDistanceMatrix(Xall);
                W = DistanceMatrix(W,Y,type);
            end
            [W,Y,isTest,type] = W.prepareForHF();
            useCV = true;
            useHF = true;
            if ~useHF
                display('HFMethod: Not using HF to select sigma');
            end
            Y_testCleared = Y;
            Y_testCleared(isTest) = -1;
            sigma = GraphHelpers.autoSelectSigma(W,Y_testCleared,~isTest,useCV,useHF,type);
            W = Kernel.RBFKernel(W,sigma);
            isTrainLabeled = Y > 0 & ~isTest;
            assert(~issorted(isTrainLabeled));
            YTrain = Y(isTrainLabeled);
            YLabelMatrix = Helpers.createLabelMatrix(YTrain);
            addpath(genpath('libraryCode'));
            [fu, fu_CMN] = harmonic_function(W, YLabelMatrix);
            [~,predicted] = max(fu,[],2);
            %[~,predicted] = max(fu_CMN,[],2);
            numNan = sum(isnan(fu(:)));
            if numNan > 0
                display(['numNan: ' num2str(numNan)]);
            end
            isYTest = Y > 0 & isTest;
            YTest = Y(isYTest);            
            numTrainLabeled = sum(isTrainLabeled);
            predicted = predicted(isYTest(numTrainLabeled+1:end));
            val = sum(predicted == YTest)/...
                length(YTest);
            display(['HFMethod Acc: ' num2str(val)]);
            testResults.testPredicted = predicted;
            testResults.testActual = YTest;
            testResults.trainActual = train.Y;
            testResults.trainPredicted = train.Y;
            metadata = {};
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

