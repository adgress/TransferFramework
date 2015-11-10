classdef LLGCHypothesisTransfer < LLGCMethod
    %LLGCHYPOTHESISTRANSFER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sourceHyp
        targetHyp      
        beta
        beta0
    end
    
    methods
        function obj = LLGCHypothesisTransfer(configs)
            obj = obj@LLGCMethod(configs);
            obj.sourceHyp = [];
            obj.beta0 = 0;
            pc = ProjectConfigs.Create();
            if ~obj.has('noTransfer')
                obj.set('noTransfer',~ProjectConfigs.useTransfer);
            end
            obj.set('hinge',0);
            obj.set('l2',0);
            obj.set('allSource',0);
            if ~obj.has('oracle')
                obj.set('oracle',false);
            end
            obj.set('classification',1);
            
            obj.set('sumConstraint',0);
            obj.set('nonnegativeConstraint',1)
            obj.set('equalConstraint',0);
            obj.set('normConstraint',0);
        end
        
        function [XT,XS,labelIDs] = createTransferFeatures(obj,X)
            n = size(X,1);
            labels = sort(obj.targetHyp.model.Label,'ascend');
            numLabels = max(labels);
            numSources = length(obj.sourceHyp);
            [ySource,fuSource] = obj.getSourcePredictions(X);
            XS = zeros(n,numLabels*numSources);
            labelIDs = zeros(1,numLabels*numSources);
            for j=1:numLabels
                f = zeros(n,numSources);
                for idx=1:length(fuSource)
                    f(:,idx) = fuSource{idx}(:,j);                    
                end                              
                cols = numSources*(j-1)+1:numSources*j;
                XS(:,cols) = f;
                labelIDs(cols) = j;
            end             
            
            [~,XT] = obj.targetHyp.predict(X);
            XT = XT(:,labels);
            XS = XS(:,ismember(labelIDs,labels));
        end
        
        function [XT,XS,labelIDs] = createTransferFeaturesLOO(obj,X,Y,labels)
            I = ~isnan(Y);
            labels = unique(Y(I));            
            n = size(X,1);
            numLabels = max(labels);
            numSources = length(obj.sourceHyp);
            [ySource,fuSource] = obj.getSourcePredictions(X);
            XS = zeros(n,numLabels*numSources);
            labelIDs = zeros(1,numLabels*numSources);
            for j=1:numLabels
                f = zeros(n,numSources);
                for idx=1:length(fuSource)
                    f(:,idx) = fuSource{idx}(:,j);                    
                end                              
                cols = numSources*(j-1)+1:numSources*j;
                XS(:,cols) = f;
                labelIDs(cols) = j;
            end             
            
            [~,XT] = obj.targetHyp.getLOOestimates(X(I,:),Y(I));
            XT = XT(:,labels);
            XS = XS(I,ismember(labelIDs,labels));
        end
        
        function [] = train(obj,X,Y)
            reg = obj.get('reg');    
            numSources = length(obj.sourceHyp);
            obj.beta = zeros(numSources+1,1);
            assert(~obj.get('allSource'));
            assert(~obj.get('oracle'));
            if reg == 0
                obj.beta(1) = 1;
                return;
            end
            I = ~isnan(Y);
            labels = unique(Y(I));
            numLabels = length(labels);
            Ymat = Helpers.createLabelMatrix(Y);            
            targetInds = I;
            Ytarget = Ymat(targetInds,:);
            
            [Ftarget,fuCombined,labelIDs] = obj.createTransferFeaturesLOO(X,Y,labels);
            
            bTarget = 1 - reg;                        
            Ymat = Ymat(I,labels);
            betaRowIdx = 1:(numLabels*numSources);

            betaColIdx = zeros(numLabels*numSources,1);
            betaIdx = zeros(numLabels*numSources,1);
            for idx=1:numLabels
                range = numSources*(idx-1)+1:numSources*idx;
                betaColIdx(range) = idx;
                betaIdx(range) = (1:numSources)';
            end


            warning off                
            cvx_begin quiet
                variable F(sum(I),numLabels)             
                variable b(numSources,1)
                variable bT
                variable b0
                variable bRep(numLabels*numSources,numLabels)
                
                %minimize(norm(F(:,1)-Ymat(:,1),1))
                minimize(norm(F(:,1)-Ymat(:,1) + b0,2))
                
                subject to
                    if obj.get('nonnegativeConstraint')
                        b >= 0
                    end
                    if obj.get('sumConstraint')
                        norm(b,1) <= reg
                    end
                    if obj.get('equalConstraint')
                        bT == bTarget
                    end
                    if obj.get('normConstraint')
                        sum_square([bT ; b]) <= reg
                    end
                    bRep == sparse(betaRowIdx,betaColIdx,b(betaIdx))                    
                    F == Ftarget*bT + fuCombined*bRep
            cvx_end 
            b = [bT ; b];            
            warning on
            %b
            obj.beta = b;
            obj.beta0 = b0;
        end
        
        function [y,fu] = getSourcePredictions(obj,X)
            y = cell(size(obj.sourceHyp));
            fu = y;
            for idx=1:length(obj.sourceHyp);
                [y{idx},fu{idx}] = obj.sourceHyp{idx}.predict(X);
            end
        end
        
        function [y,fu] = predict(obj,X)
            if obj.get('noTransfer')
                [y,fu] = obj.targetHyp.predict(X);
                return;
            end
            [~,targetPred] = obj.targetHyp.predict(X);
            [~,sourcePred] = obj.getSourcePredictions(X);
            fu = obj.beta(1)*targetPred;
            for idx=1:length(sourcePred)
                fu = fu + obj.beta(idx+1)*sourcePred{idx};            
            end
            normalize = obj.get('nonnegativeConstraint');
            fu = fu + obj.beta0;
            [~,y] = max(fu,[],2);
            if normalize
                fu = Helpers.NormalizeRows(fu);
                I = ~(fu(:) >= 0);
                if any(I)
                    error('Is this okay?');
                    %fu(I);
                    %fu(I) = rand(sum(I),1);
                end
                %{
                assert(all(fu(:) >= 0));
                I = find(sum(fu,2) == 0);
                if ~isempty(I)
                    fu(I,:) = rand(length(I),size(fu,2));
                end
                %}          
            end
        end
        function [testResults,savedData] = runMethod(obj,input,savedData)
            train = input.train;
            test = input.test;
                     
            obj.targetHyp.trainAndTest(input);
            
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
            pc = ProjectConfigs.Create();
            train = input.train;            
            obj.sourceHyp = {};
            
            if isfield(input.originalSourceData{1}.savedFields,'learner')
                for idx=1:length(input.originalSourceData)
                    s = input.originalSourceData{idx};
                    obj.sourceHyp{idx} = s.savedFields.learner;
                end
            else
                error('no Source hyps!');
            end

            cvParams = struct('key','values');                        
            cvParams(1).key = 'reg';
            cvParams(1).values = num2cell(obj.get('cvReg'));
            if obj.get('noTransfer')
                cvParams(1).values = {0};
            end            
            if obj.get('oracle')
                cvParams(1).values = {.5};
                if pc.dataSet == Constants.NG_DATA
                    cvParams(1).values = {0};
                end
            end
            if obj.get('allSource')
                cvParams(1).values = {1};
            end
            obj.delete('sigmaScale');
            
            cv = CrossValidation();            
            cv.trainData = train.copy();
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
            testResults.learnerStats.dataSetWeights = obj.beta;
            if isa(obj,'LayeredHypothesisTransfer')
                testResults.learnerStats.dataSetWeights = obj.finalHyp.model.w;
            end
        end
        function [prefix] = getPrefix(obj)
            prefix = 'HypTran';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {};
            nameParams{end+1} = 'targetMethod';
            obj.set('targetMethod',obj.targetHyp.getPrefix());
            if obj.get('noTransfer',false)
                nameParams{end+1} = 'noTransfer';
            end
            if obj.get('oracle',0)
                nameParams{end+1} = 'oracle';
            end
            if obj.get('l2',0)
                nameParams{end+1} = 'l2';
            end
            if obj.get('hinge',0)
                nameParams{end+1} = 'hinge';
            end
            if obj.get('allSource',0)
                nameParams{end+1} = 'allSource';
            end
        end 
    end
    
end

