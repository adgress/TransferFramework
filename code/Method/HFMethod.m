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
            
            sigma = input.sharedConfigs('sigma');
            
            testResults = struct();   
            if nargin >= 4 && isfield(input,'distanceMatrix')
                W = input.distanceMatrix;
                W = W.getRBFKernel(sigma);
            else
                trainLabeled = train.Y > 0;
                XLabeled = train.X(trainLabeled,:);
                XUnlabeled = [train.X(~trainLabeled,:) ; test.X];
                Xall = [XLabeled ; XUnlabeled];
                sigma = sum(var(Xall));
                display(['Empirical sigma: ' num2str(sigma)]);
                Y = [train.Y(trainLabeled) ; ...
                    train.Y(~trainLabeled) ; ...
                    test.Y];
                type = [ones(size(XLabeled,1),1)*DistanceMatrix.TYPE_TARGET_TRAIN ;...
                    ones(size(train.X(~trainLabeled,:),1),1)*DistanceMatrix.TYPE_TARGET_TRAIN ; ...
                    ones(size(test.X,1),1)*DistanceMatrix.TYPE_TARGET_TEST];                                
                W = Kernel.RBFKernel(Xall,sigma);
                W = DistanceMatrix(W,Y,type);
            end            
            [W,YTrainLabeled,YTest,isTest] = W.prepareForHF();
            assert(min(YTrainLabeled) > 0);
            assert(min(YTest) > 0);
            assert(length(YTest) == length(test.Y));
            usellgc = 0;
            if usellgc
                YLabelMatrix = Helpers.createLabelMatrix(YTrainLabeled);
                [fu,fu_CMN] = llgc(W,YLabelMatrix)
            else                
                YLabelMatrix = Helpers.createLabelMatrix(YTrainLabeled);
                addpath(genpath('libraryCode'));
                [fu, fu_CMN] = harmonic_function(W, YLabelMatrix);                                
                [~,predicted] = max(fu,[],2);
                isTest = isTest(size(YTrainLabeled,1)+1:end);
            end
            
            val = sum(predicted(isTest) == YTest)/...
                length(YTest);
            display(['HF Acc: ' num2str(val)]);
            testResults.testPredicted = predicted(isTest);
            testResults.testActual = test.Y;
            testResults.trainActual = train.Y;
            testResults.trainPredicted = train.Y;
            metadata = {};
        end
    end
    
    methods(Static)
        function [name] = getMethodName(configs)
            if nargin < 1
                name = 'HF';
            else
                sigma = configs('sigma');
                name = ['HF, sigma=' num2str(sigma)];                   
            end
        end
    end
    
end

