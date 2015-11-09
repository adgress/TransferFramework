classdef SepHypothesisTransfer < LLGCHypothesisTransfer
    %SEPHYPOTHESISTRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bTarget
        bSource
        b0
        labels
    end
    
    methods
        function obj = SepHypothesisTransfer(configs)
            obj = obj@LLGCHypothesisTransfer(configs);
            obj.set('noTransfer',~ProjectConfigs.useTransfer);
            obj.set('cvReg',10.^(-1:10));
            %obj.set('quiet',false);
        end
        function [XS] = sourcePred2Mat(obj,fuSource)
            n = size(fuSource{1},1);
            numLabels = length(obj.labels);
            XS = zeros(n,numLabels*length(fuSource));
            i = 0;
            for idx=1:length(fuSource)
                %{
                XS(:,i+1:i+numLabels) = fuSource{idx}(:,obj.labels);
                i = i + numLabels;
                %}
                XS(:,i+1:i+1) = fuSource{idx}(:,obj.labels(1));
                i = i + 1;
            end
        end
        function [] = train(obj,X,Y)
            reg = obj.get('reg');
            %reg = 1000;
            obj.labels = unique(Y(~isnan(Y)));
            numLabels = length(obj.labels);
            assert(numLabels == 2);
        
            n = size(X,1);
            [ySource,fuSource] = obj.getSourcePredictions(X);
            XS = obj.sourcePred2Mat(fuSource);
            
            I = ~isnan(Y);
            XL = X(I,:);
            YL = Y(I);
            XSL = XS(I,:);
            YL = Helpers.MakeLabelsBinary(YL);
            YL(YL < 0) = 0;
            sig = @(x) 1/(1+exp(-x));
            warning off                
            cvx_begin quiet
                variable bT(size(X,2),1)
                variable bS(length(fuSource)*numLabels,1);
                variable b0
                %minimize(reg*sum( log(1+ exp(-YL.* (XL * bT + b0)) ) ) + 1*(norm(bT,2)))
                
                maximize(YL'*(XL*bT+XSL*bS+b0)-...
                    sum(log_sum_exp([zeros(1,length(YL)); bT'*XL' + bS'*XSL' + b0])))
                
                %minimize(reg*sum( log(1+ exp(-YL.* (XL * bT + b0)) ) ) + norm(bT,2)  + norm(bS,2))                
                %{
                maximize(YL'*(XL*bT + XSL*bS + b0) ...
                    -sum(log_sum_exp([zeros(1,m); x'*U'])))
            %}
                
                subject to                  
                    sum_square(bT) <= reg
                    if obj.get('noTransfer')
                        bS == 0
                    else
                        sum_square(bS) <= reg
                    end
            cvx_end 
            warning on
            %l = LiblinearMethod(obj.configs.copy());
            %l.set('reg',1/reg);
            %l.train(XL,Y(I));
            obj.bTarget = bT;
            obj.bSource = bS;
            obj.b0 = b0;
        end
        function [y,fu] = predict(obj,X)
            %{
            if obj.get('noTransfer')
                [y,fu] = obj.targetHyp.predict(X);
                return;
            end
            %}
            [~,fuSource] = obj.getSourcePredictions(X);
            XS = obj.sourcePred2Mat(fuSource);
            p = X*obj.bTarget + XS*obj.bSource + obj.b0;
            fu = exp(p) ./ (1+exp(p));
            fu = [fu (1 - fu)];
            fu = Helpers.expandMatrix(fu,obj.labels);
            [~,y] = max(fu,[],2);
        end
        function [testResults,savedData] = runMethod(obj,input,savedData)
            train = input.train;
            test = input.test;
            
            obj.train(train.X,train.Y);
            [y,fu] = obj.predict([train.X ; test.X]);     
            toKeep = [train.isLabeled() ; true(size(test.X,1),1)];
            testResults = FoldResults(); 
            isLabeledTrain = train.isLabeled();
            testResults.dataType = [train.type(isLabeledTrain) ; test.type];
            testResults.yActual = [train.trueY(isLabeledTrain) ; test.trueY];
            testResults.yPred = y(toKeep);
            testResults.dataFU = fu(toKeep,:);
            a = obj.configs.get('measure').evaluate(testResults);
            savedData.val = a.learnerStats.valTest;            
            assert(~isnan(savedData.val));
        end
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            if ~exist('savedData','var')
                savedData = struct();
            end
            [testResults,savedData] = trainAndTest@LLGCHypothesisTransfer(obj,input,savedData);
            testResults.learnerStats.b0 = obj.b0;
            testResults.learnerStats.bTarget = obj.bTarget;
            testResults.learnerStats.bSource = obj.bSource;
        end
        function [prefix] = getPrefix(obj)
            prefix = 'SepHypTran';
        end
    end
    
end

