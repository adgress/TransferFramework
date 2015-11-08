classdef HypothesisTransfer < Method
    %HYPOTHESISTRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        beta
        beta0
        betaSource
        transform
    end
    
    methods
        function obj = HypothesisTransfer(configs)
            obj = obj@Method(configs);   
            obj.set('justTarget',0);
            obj.transform = NormalizeTransform();
        end
        function [] = train(obj,X,Y)
            reg = obj.get('reg');
            regTransfer = obj.get('regTransfer');
            I = obj.betaSource == 0;
            isLabeled = ~isnan(Y);
            
            n = size(X,1);
            p = size(X,2);
            obj.transform.learn(X,Y);
            [X,Y] = obj.transform.apply(X(isLabeled,:),Y(isLabeled));
            %regTransfer = 1;
            %reg = 0;
            
            useCVX = 0;
            useL1General = 1;
            if useCVX
                tic
                warning off   
                display('Need to use squared norm?');
                cvx_begin quiet
                    variable b(p)
                    %minimize(norm(X(isLabeled,:)*b + obj.beta0 - Y(isLabeled),2) + ...
                    minimize(sum_square(X(isLabeled,:)*b - Y(isLabeled)) + ...
                        reg*norm(b,1) + regTransfer*reg*norm(b(I),1))
                    subject to
                cvx_end  
                warning on                            
                toc
            end
            if useL1General
                loss = @L2Loss;
                lossArgs = {X(isLabeled,:),Y(isLabeled)};

                b = zeros(p,1);
                lambdaVect = reg*ones(p,1) + regTransfer*I;     

                optimFunc = @L1GeneralPrimalDualLogBarrier;
                %optimFunc = @L1GeneralCoordinateDescent;
                options = [];
                options.verbose = 0;
                %tic
                b = optimFunc(loss,b,lambdaVect,options,lossArgs{:});
                %toc
            end
            b(abs(b) < 1e-8) = 0;
            %norm(wProj-b)/norm(b)
            
            %obj.beta = b;
            %obj.beta = b./obj.transform.stdevs';
            %obj.beta0 = obj.transform.meanY-obj.transform.meanX'*b;
            betaScaled = b./obj.transform.stdevs';
            beta0Scaled = obj.transform.meanY-obj.transform.meanX*b;
            
            obj.beta = betaScaled;
            obj.beta0 = beta0Scaled;
            
            %b
        end
        function [y] = predict(obj,X)
            %[X] = obj.transform.apply(X);
            y = X*obj.beta + obj.beta0;
            %y = obj.transform.invert(y);
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
            pc = ProjectConfigs.Create();
            train = input.train;
            test = input.test;  
            obj.betaSource = train.savedFields.betaSource;
            obj.beta0 = train.savedFields.beta0;
            testResults = FoldResults();   

            targetTrain = train.copy();
            targetTrain.keep(targetTrain.isLabeled());
            cvParams = struct('key','values');
            cvParams(1).key = 'reg';
            cvParams(1).values = num2cell(obj.get('cvReg'));
            if obj.get('justTarget')
                obj.set('regTransfer',0);
            else
                cvParams(2).key = 'regTransfer';
                cvParams(2).values = num2cell(obj.get('cvRegTransfer'));
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
            [obj.beta train.savedFields.beta]
        end        
        function [s] = getPrefix(obj)
            s = 'HypTransfer';
            if obj.get('justTarget',false)
                s = 'Lasso';
            end
        end
    end
    
end

