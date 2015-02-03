classdef SepLLGCMethod < LLGCMethod
    %LLGCMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = SepLLGCMethod(configs)
            obj = obj@LLGCMethod(configs);
            if ~obj.has('uniform')
                obj.set('uniform',false);
            end
            if ~obj.has('regularized')
                obj.set('regularized',true);
            end
            if ~obj.has('sum')
                obj.set('sum',false);
            end
        end
        
        function [testResults,savedData] = ...
                trainAndTest(obj,input,savedData)
            useHF = false;
            train = input.train;
            test = input.test;
            trainCopy = train.copy();
            testCopy = test.copy();            
            numClasses = max(train.Y);
            numInstances = size(trainCopy.X,1) + size(testCopy.X,1);
            %numFeatures = size(trainCopy.X,2);
            %numFeatures = 20;            
            invM = {};      
            alpha = obj.get('alpha');
            featureGroups = {1:300,301:328,329:368,369:405};
            %featureGroups = [num2cell(1:300) {301:328,329:368,369:405}];
            %featureGroups = num2cell(1:405);
            
            F = zeros(numInstances,numClasses,length(featureGroups));
            %for dimIdx=1:numFeatures
            for groupIdx=1:length(featureGroups);
                dims = featureGroups{groupIdx};
                trainCopy.X = train.X(:,dims);
                testCopy.X = test.X(:,dims);   
                d = obj.createDistanceMatrix(trainCopy,testCopy,...
                    useHF,obj.configs);                                
                d.removeTestLabels();                               
                if groupIdx == 1
                    distMat = d;
                    Ymat = Helpers.createLabelMatrix(d.Y);
                end
                if obj.get('sum')
                    if groupIdx > 1
                        distMat.W = distMat.W + d.W;
                    end
                else
                    %F(:,:,dimIdx) = obj.runBandedLLGC(distMat);
                    %F(:,:,dimIdx) = obj.runLLGC(d);
                    [Wrbf,YtrainMat,sigma] = makeLLGCMatrices(obj,d);
                    invM{end+1} = LLGC.makeInvM(Wrbf,alpha);
                    %[F(:,:,groupIdx),~] = LLGC.llgc_inv([],Ymat,alpha,invM{groupIdx});
                    [F(:,:,groupIdx),~] = LLGC.llgc_inv([],YtrainMat,alpha,invM{groupIdx});
                    %F2= obj.runLLGC(d);
                end
            end
            F(isnan(F(:))) = 0;
            assert(~any(isnan(F(:))));
            if obj.get('sum')
                distMat.W = distMat.W ./ length(featureGroups);
            end
            isLabeledInds = distMat.isLabeled();
            numLabeled = sum(isLabeledInds);
            %F_labeled = F(isLabeledInds,:,:);
            Y_labeled = Helpers.createLabelMatrix(distMat.Y(isLabeledInds));                                    
            isLabeledInds = find(isLabeledInds);
            if ~obj.get('sum')                     
                F_labeled = zeros(length(isLabeledInds),size(F,2),size(F,3));
                for instanceIdx = 1:length(isLabeledInds)
                    ind = isLabeledInds(instanceIdx);
                    Y_copy = distMat.Y;                    
                    Y_copy(ind) = -1;
                    YMatCurrRemoved = Helpers.createLabelMatrix(Y_copy);
                    for groupIdx=1:length(featureGroups)
                         [F(:,:,groupIdx),~] = LLGC.llgc_inv([],YMatCurrRemoved,alpha,invM{groupIdx});
                         F_labeled(instanceIdx,:,groupIdx) = F(ind,:,groupIdx);
                    end                    
                end
                F(isnan(F(:))) = 0;
                assert(~any(isnan(F(:))));
                F_labeled(isnan(F_labeled)) = 0;
                %{
                pc = ProjectConfigs.Create();
                regVals = pc.reg;            
                regPerf = zeros(size(regVals));
                for instanceIdx = 1:length(isLabeledInds)
                    ind = isLabeledInds(instanceIdx);
                    Y_copy = distMat.Y;                    
                    Y_copy(ind) = -1;
                    YMatCurrRemoved = Helpers.createLabelMatrix(Y_copy);                    
                    F = zeros(numInstances,numClasses,numFeatures);
                    for dimIdx=1:numFeatures
                         [F(:,:,dimIdx),~] = LLGC.llgc_inv([],YMatCurrRemoved,alpha,invM{dimIdx});
                    end
                    F_labeled = F(isLabeledInds,:,:);

                    
                    Y_labeledCopy = Y_labeled;
                    trueLabel = distMat.Y(ind);
                    Y_labeledCopy(instanceIdx,:) = 0;
                    
                    [F_bar,Y_bar] = obj.stackLabels(F_labeled,Y_labeledCopy);
                    for regIdx=1:length(regVals)
                        reg = regVals(regIdx);
                        %isLabeledInds = find(distMat.Y > 0);
                        %acc = 0;
                        b = obj.solveForBeta(F_bar,Y_bar,reg);
                        Fb = obj.sumF(F,b);
                        Fb = Helpers.normRows(Fb);
                        %[~,FbPred] = max(Fb,[],2);
                        regPerf(regIdx) = regPerf(regIdx) + Fb(ind,trueLabel);
                    end
                    regPerf = regPerf ./ length(isLabeledInds);
                    regPerf(regIdx) = mean(acc);            
                end
                %}
                
                trainAccs = [];
                testAccs = [];
                for groupIdx=1:length(featureGroups);
                    %{
                    Fcurr = F(:,:,dimIdx);
                    [~,FcurrPred] = max(Fcurr,[],2);
                    accVec = FcurrPred == distMat.trueY;
                    trainAccs(dimIdx) = mean(accVec(isLabeledInds));
                    testAccs(dimIdx) = mean(accVec(distMat.isTargetTest()));
                    %}
                    Fcurr = F_labeled(:,:,groupIdx);
                    [~,FcurrPred] = max(Fcurr,[],2);
                    accVec = FcurrPred == distMat.Y(isLabeledInds);
                    trainAccs(groupIdx) = mean(accVec);
                    t = [FcurrPred distMat.Y(isLabeledInds)];
                end
                
                if ~obj.get('uniform')
                    [F_bar_labeled,Y_bar_labeled] = obj.stackLabels(F_labeled,Y_labeled);                    
                    if obj.get('regularized')
                        %error('');
                        reg = 10;
                    else
                        reg = 0;
                    end                
                    b = obj.solveForBeta(F_bar_labeled,Y_bar_labeled,reg);
                    Fb_labeled = obj.sumF(F_labeled,b);
                    [~,Fb_labeledPred] = max(Fb_labeled,[],2);
                    accVec = Fb_labeledPred == distMat.Y(isLabeledInds);
                    t = [Fb_labeledPred distMat.Y(isLabeledInds)];
                    display(['TrainAcc: ' num2str(mean(accVec))]);
                end
            end
            
            trueY = distMat.trueY;
            testResults = FoldResults();
            testResults.yActual = trueY;
            testResults.dataType = distMat.type;
            if obj.get('sum')
                F  = obj.runLLGC(distMat);
                [~,FsumPred] = max(F,[],2);
                testResults.dataFU = sparse(F);
                testResults.yPred = FsumPred;
            else                
                if obj.get('uniform')
                    Faverage = obj.sumF(F);
                    [~,FavePred] = max(Faverage,[],2);
                    testResults.yPred = FavePred;
                    testResults.dataFU = sparse(Faverage);
                else                
                    %b = obj.solveForBeta(F_bar,Y_bar,reg);
                    Fb = obj.sumF(F,b);
                    [~,FbPred] = max(Fb,[],2);
                    testResults.yPred = FbPred;                    
                    testResults.dataFU = sparse(Fb);                    
                end              
            end
            accVec = testResults.yPred == trueY;
            trainAcc = mean(accVec(isLabeledInds));
            testAcc = mean(accVec(distMat.isTargetTest()));
            display([num2str(trainAcc) ' ' num2str(testAcc)]);
            assert(~any(isnan(testResults.dataFU(:))));
        end
        
        function [Fb] = sumF(obj,F,b)
            if ~exist('b','var')
                Fb = sum(F,3)./size(F,3);
            else
                Fb = zeros(size(F,1),size(F,2));
                for featIdx=1:length(b)
                    Fb = Fb + F(:,:,featIdx)*b(featIdx);
                end
            end
        end
        
        function [F_bar,Y_bar] = stackLabels(obj,F,Y)
            numInstances = size(F,1);
            numClasses = size(F,2);
            numFeatures = size(F,3);
            F_bar = zeros(numInstances*numClasses,numFeatures);
            Y_bar = zeros(size(F_bar,1),1);            
            for classIdx=1:numClasses
                start = (classIdx-1)*numInstances + 1;
                finish = classIdx*numInstances;
                F_bar(start:finish,:) = ...
                    reshape(F(:,classIdx,:),numInstances,numFeatures);
                Y_bar(start:finish,:) = Y(:,classIdx);
            end            
        end
        
        function [b] = solveForBeta(obj,F_bar,Y_bar,reg)
            numFeatures = size(F_bar,2);
            u = ones(numFeatures,1)./numFeatures;
            warning off
            cvx_begin quiet
                variable b(numFeatures,1)
                %minimize(norm(F_bar*b-Y_bar,'fro') + reg*norm(b-u,2))
                minimize(norm(F_bar*b-Y_bar) + reg*norm(b,2))
                subject to
                    b >= 0
            cvx_end  
            warning on
            b(b < 0) = 0;
        end
        
        function [] = updateConfigs(obj, newConfigs)
            %keys = {'sigma', 'sigmaScale','k','alpha'};
            keys = {'sigmaScale','alpha'};
            obj.updateConfigsWithKeys(newConfigs,keys);
        end                
        
        function [prefix] = getPrefix(obj)
            prefix = 'SepLLGC';
        end
        function [nameParams] = getNameParams(obj)
            nameParams = {'sigmaScale','alpha'};
            if obj.has('sum') && obj.get('sum')
                nameParams{end+1} = 'sum';
            elseif obj.has('uniform') && obj.get('uniform')
                nameParams{end+1} = 'uniform';
            else
                nameParams{end+1} = 'regularized';
            end
        end
    end
    
end

