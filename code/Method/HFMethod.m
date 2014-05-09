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
                Y = [train.Y(trainLabeled) ; ...
                    train.Y(~trainLabeled) ; ...
                    test.Y];
                type = [ones(size(XLabeled,1),1)*Constants.TARGET_TRAIN ;...
                    ones(size(train.X(~trainLabeled,:),1),1)*Constants.TARGET_TRAIN ; ...
                    ones(size(test.X,1),1)*Constants.TARGET_TEST];                                
                W = Helpers.CreateDistanceMatrix(Xall);
                W = DistanceMatrix(W,Y,type);
            end
            [W,YTrainLabeled,YTest,isTest] = W.prepareForHF();
            useCV = true;
            useHF = true;
            if ~useHF
                display('HFMethod: Not using HF to select sigma');
            end
            usesSourceData = 0;
            %error('Is type set properly?');
            if ~usesSourceData
                sigma = obj.chooseBestSigma(train,test,input.originalSourceData,useHF);
            else
                sigma = GraphHelpers.autoSelectSigma(W,[YTrainLabeled ; YTest],~isTest,useCV,useHF,type);
            end
            W = Kernel.RBFKernel(W,sigma);
     
            YLabelMatrix = Helpers.createLabelMatrix(YTrainLabeled);
            addpath(genpath('libraryCode'));
            [fu, fu_CMN] = harmonic_function(W, YLabelMatrix);
            [~,predicted] = max(fu,[],2);
            isTest = isTest(size(YTrainLabeled,1)+1:end);
            
            val = sum(predicted(isTest) == YTest)/...
                length(YTest);
            display(['HF Acc: ' num2str(val)]);
            testResults.testPredicted = predicted(isTest);
            testResults.testActual = test.Y;
            testResults.trainActual = train.Y;
            testResults.trainPredicted = train.Y;
            metadata = {};
        end
        
        function [sigma] = chooseBestSigma(obj,train,test,source,useHF)
            Xall = [train.X ; test.X];
            Y = [train.Y ; -1*ones(size(test.Y))];
            W = Kernel.Distance(Xall);
            W = DistanceMatrix(W,Y,[train.type; test.type]);
            isTarget = ones(train.size()+test.size(),1);
            useCV = true;
            %error('Is type set properly?');
            sigma = GraphHelpers.autoSelectSigma(W.W,Y,isTarget,useCV,useHF,W.type);
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

