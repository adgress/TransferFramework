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
            if nargin >= 4 && isfield(input,'distanceMatrix')
                W = input.distanceMatrix;
            else
                trainLabeled = train.Y > 0;
                XLabeled = train.X(trainLabeled,:);
                XUnlabeled = [train.X(~trainLabeled,:) ; test.X];
                Xall = [XLabeled ; XUnlabeled];                
                Y = [train.Y(trainLabeled) ; ...
                    train.Y(~trainLabeled) ; ...
                    test.Y];
                type = [ones(size(XLabeled,1),1)*DistanceMatrix.TYPE_TARGET_TRAIN ;...
                    ones(size(train.X(~trainLabeled,:),1),1)*DistanceMatrix.TYPE_TARGET_TRAIN ; ...
                    ones(size(test.X,1),1)*DistanceMatrix.TYPE_TARGET_TEST];                                
                W = Helpers.CreateDistanceMatrix(Xall);
                W = DistanceMatrix(W,Y,type);
            end     
            [W,YTrainLabeled,YTest,isTest] = W.prepareForHF();
            useCV = 1;
            useHF = false;
            display('HFMethod: Not using HF to select sigma');
            sigma = Helpers.autoSelectSigma(W,YTrainLabeled,YTest,~isTest,useCV,useHF);
            %W = W.getRBFKernel(sigma);
            W = Kernel.RBFKernel(W,sigma);
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
            end
        end
    end
    
end

