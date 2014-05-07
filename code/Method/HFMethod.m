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
                error('Possible bug - is this taking advantage of source data?');
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
            useHF = true;
            if ~useHF
                display('HFMethod: Not using HF to select sigma');
            end
            usesSourceData = 0;
            if ~usesSourceData
                sigma = obj.chooseBestSigma(train,test,input.originalSourceData,useHF);
            else
                sigma = Helpers.autoSelectSigma(W,YTrainLabeled,YTest,~isTest,useCV,useHF);
            end
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
        
        function [sigma] = chooseBestSigma(obj,train,test,source,useHF)
            %{
            source.X = zeros(0,size(source.X,2));
            source.Y = [];
            Xall = [source.X ; train.X ; test.X];
            Y = [source.Y ; train.Y ; -1*ones(size(test.Y))];
            type = [ones(numel(source.Y),1)*DistanceMatrix.TYPE_SOURCE ;...
                ones(length(train.Y)+length(test.Y),1)*DistanceMatrix.TYPE_TARGET_TRAIN];
            W = Kernel.Distance(Xall);
            W = DistanceMatrix(W,Y,type);
            [W,Ys,Yt,isTarget] = W.prepareForSourceHF();
            useCV = true;
            sigma = Helpers.autoSelectSigma(W,Ys,Yt,~isTarget,useCV,useHF);
            %}
            Xall = [train.X ; test.X];
            Y = [train.Y ; -1*ones(size(test.Y))];
            type = DistanceMatrix.TYPE_TARGET_TRAIN*ones(size(Y));
            W = Kernel.Distance(Xall);
            W = DistanceMatrix(W,Y,type);
            isTarget = ones(size(type));
            useCV = true;
            sigma = Helpers.autoSelectSigma(W,Y,[],isTarget,useCV,useHF);
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

