classdef InequalityTransfer < Method
    %INEQUALITYTRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nwTarget
        nwSource
        %X
        %Y
        %sigma
    end
    
    methods
        function obj = InequalityTransfer(configs)            
            obj = obj@Method(configs); 
            
            obj.configs.set('noTransfer',false);
            
            obj.configs.set('classification',false);
            obj.configs.set('zscore',false);            
            configs.set('classification',false);
            configs.set('zscore',false);
            obj.nwSource = NWMethod(configs);
            obj.nwTarget = NWMethod(configs);
        end
        
        function [] = train(obj,X,Y)
            reg = obj.get('reg');
            sigma = obj.get('sigma');
            
            isLabeled = ~isnan(Y);
            nl = sum(isLabeled);            
            n = size(X,1);
            W = Helpers.CreateDistanceMatrix(X);
            Wrbf = Helpers.distance2RBF(W,sigma);          
            Wsub = Wrbf(:,isLabeled);
            Dinv = diag(1./sum(Wsub,2));
            S = Dinv*Wsub;
            Ysub = Y(isLabeled);
            SY = S*Ysub;
            YpredSource = obj.nwSource.predict(X(isLabeled));
            [~,I] = sort(YpredSource,'ascend');
            
            Ilow = I(1:n-1);
            Ihigh = I(2:n);
            useCVX = 1;
            %useL1General = 1;
            if reg == 0
                b = SY;
            elseif useCVX
                %tic
                warning off
                cvx_begin quiet
                variable b(n)
                variable t(n-1)
                minimize(sum_square(SY - b) - reg*sum(t))
                %minimize(sum_square(SY - b))
                subject to
                    b(Ihigh) - b(Ilow) >= t
                cvx_end  
                warning on                            
                %toc
            end 
            %[SY b Y [0 ; t]]
            obj.nwTarget.set('sigma',sigma);
            obj.nwTarget.train(X,b);
        end
        function [y] = predict(obj,X)
            y = obj.nwTarget.predict(X);
        end
        function [testResults,savedData] = runMethod(obj,input,savedData)
            train = input.train;
            test = input.test;
                        
            allData = DataSet.Combine(train,test);
            I = allData.isLabeledTargetTrain();
            obj.train(allData.X(I,:),allData.Y(I));    
                        
            [y] = obj.predict(allData.X);
            
            testResults = FoldResults(); 
            testResults.dataType = allData.type;
            testResults.yActual = allData.trueY;
            testResults.yPred = y;
            a = obj.configs.get('measure').evaluate(testResults);
            savedData.val = a.learnerStats.valTest;
            %[allData.Y y]   
            %[obj.beta train.savedFields.beta]
            
        end
        function [testResults,savedData] = trainAndTest(obj,input,savedData)   
            if ~exist('savedData','var')
                savedData = struct();
            end
            train = input.train;
            if isfield(input.originalSourceData{1}.savedFields,'learner')
                obj.nwSource = input.originalSourceData{1}.savedFields.learner;
            else
                inputSource = input();
                inputSource.train = input.originalSourceData{1}.copy();
                inputSource.train.setTargetTrain();
                inputSource.configs = input.configs;
                inputSource.test = inputSource.train.copy();
                inputSource.test.setTargetTest();
                inputSource.learner = obj.nwSource;

                sourceCVParams = struct('key','values');
                sourceCVParams(1).key = 'sigma';
                sourceCVParams(1).values = num2cell(obj.get('cvSigma'));

                obj.nwSource.set('cvParameters',sourceCVParams);
                obj.nwSource.set('measure',obj.get('measure'));
                obj.nwSource.trainAndTest(inputSource);
            end
            targetTrain = train.copy();
            targetTrain.keep(targetTrain.isLabeled());
            cvParams = struct('key','values');            
            
            cvParams(1).key = 'sigma';
            cvParams(1).values = num2cell(obj.get('cvSigma'));
            if obj.get('noTransfer')
                obj.nwTarget.set('reg',0);
                obj.set('reg',0);
            else
                cvParams(2).key = 'reg';
                cvParams(2).values = num2cell(obj.get('cvReg'));
            end
            cv = CrossValidation();
            
            numSplits = 10;
            splits = {};
            percArray = [.8 .2 0];
            Y = targetTrain.Y;
            Y(targetTrain.isTargetTest()) = nan;
            I = targetTrain.instanceIDs == 0;
            c = Configs();
            c.set('regProb',true);
            for idx=1:numSplits
                s = LabeledData.generateSplit(...
                    percArray,Y(I),c);
                split = ones(size(Y));
                split(I) = s;
                assert(all(split(~I) == 1));
                splits{idx} = split;
            end
            cv.splits = splits;            
            cv.trainData = targetTrain.copy();
            cv.methodObj = obj;
            cv.parameters = cvParams;
            cv.measure = obj.get('measure');
            tic
            [bestParams,acc] = cv.runCV();
            toc
            obj.setParams(bestParams);
            [testResults,savedData] = obj.runMethod(input,savedData);
            
            if ~obj.configs.get('quiet')
                display([ obj.getPrefix() ' Acc: ' num2str(savedData.val)]);                                
            end
        end        
        function [s] = getPrefix(obj)
            s = 'InequalityTransfer';
            if obj.get('noTransfer')
                s = 'NW';
            end
        end
    end
    
end

