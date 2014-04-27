classdef Helpers < handle
    %HELPERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        
        function [D] = CreateDistanceMatrix(X,Y)
            X=X';
            Y=Y';
            D = bsxfun(@plus,dot(X,X,1)',dot(Y,Y,1))-2*(X'*Y); 
        end
        
        function [minInds] = KNN(Xtrain,Xtest,k)
            D = Helpers.CreateDistanceMatrix(Xtrain,Xtest);
            minInds = zeros(size(Xtest,1),k);
            for i=1:k
                [~,inds] = min(D);
                minInds(:,i) = inds';
                numTest = size(Xtest,1);
                indMat = sparse(inds,1:numTest,true(numTest,1));
                if i ~= k
                    D(indMat) = Inf;
                end
            end
        end
        
        function [split] = split_string(string,delim)
            split = {};
            while numel(string) > 0
                [split{end+1}, string] = strtok(string,delim);
            end
        end
        
        function [map] = CombineMaps(map1,map2)
            map = containers.Map();
            maps = {map1,map2};
            for i=1:length(maps)
                m = maps{i};
                keys = m.keys;
                for j=1:length(keys)
                    k = keys{j};
                    v = m(k);
                    map(k) = v;
                end
            end
        end
        
        function [] = printCondNumber(X,varName)
            display(sprintf('Cond(%s) = %2.2e',varName,cond(X)));
        end
        
        function [acc] = measureNNAccuracy(view1,view2,answer,k)
            if nargin < 4
                k = 1;
            end
            idx = knnsearch(view2,view1);
            answer = answer(:,2);
            correct = idx == answer;
            acc = sum(correct)/numel(correct);
            display(sprintf('Knn Accuracy (K = %d): %2.2f',k,acc));
        end
        
        function [param_string] = make_param_string(input)
            loadConstants();
            learner = input('learner');
            C = num2str(input('C'));
            degree = num2str(input('degree'));
            sigma = num2str(input('sigma'));
            usePar = input('usePar');
            whiten = input('whiten');
            param_string = '';
            if learner == ALTR_LIN || learner == ALTR_POLY ||...
                    (learner >= RANKSVM && learner <= RANKSVM_WEIGHTED_BAD) || ...
                    (learner >= ALTR_LIN_DUAL && learner <= ALTR_LIN_NO_WEAK)
                param_string = [param_string ',C=' C];
            end
            if learner == ALTR_POLY || learner == ALTR_POLY_KER_CHUNKING
                param_string = [param_string ',degree=' degree];
            end
            if learner == ALTR_RBF_KER
                param_string = [param_string ',sigma=' sigma];
            end
            if usePar
                param_string = [param_string ',Parallel'];
            end
            if input('whiten')
                param_string = [param_string ',whiten'];
            end
            if input('weak_to_add') > 0
                param_string = [param_string ',num_weak=' num2str(input('weak_to_add'))];
            end
            if input('percent_weak_to_add') > 0
                param_string = [param_string ',percent_weak_added=' num2str(input('percent_weak_to_add'))];
            end
            if input('percent_weak_to_use') > 0
                param_string = [param_string ',percent_weak_used=' num2str(input('percent_weak_to_use'))];
            end
        end
        function [X,mean] = CenterData(X,mean)
            if nargin < 2
                mean = sum(X,1);
            end
            X = X - repmat(mean,size(X,1),1);
        end
        function [X] = NormalizeRows(X)
            sums = sum(X,2);
            assert(sum(sums == 0) == 0);
            try 
                r = repmat(sums,1,size(X,2));
                X = X ./ r;
            catch err
                numRows = size(X,1);
                X = spdiags (sums, 0, numRows, numRows) \ X ;
            end            
        end        
        function [Psource,Ptarget] = getSubspaces(sourceTrainData, ...
                targetTrainData, targetTestData, configs)            
            if configs('usePLS')
                Ymat = Helpers.createLabelMatrix(sourceTrainData.Y);
                [~,~,~,~,~,~,~,plsStats] = ...
                     plsregress(sourceTrainData.X,Ymat,configs('d'));
                Psource = plsStats.W;                
                %Psource2 = princomp(sourceTrainData.X);
                %Psource2 = Psource2(:,1:d);
                %display(norm(Psource-Psource2))
            else                
                Psource = princomp(sourceTrainData.X);
            end
            Ptarget = princomp([targetTrainData.X ; targetTestData.X]);
        end
        function [results] = trainAndTestSVM(train,test,options)            
            if nargin < 3
                options = struct();
                options.kernel = 'linear';
            end
            assert(isequal(options.kernel,'linear'));
            
            whitenMatrix = inv(sqrtm(cov(train.X)));
            XTrain = train.X*whitenMatrix;
            XTest = test.X*whitenMatrix;            
    
            results = struct();
            results.test = struct();
            results.test.actual = test.Y;           
            results.train = struct();
            results.train.actual = train.Y;
            results.svm = svmtrain(train.Y,XTrain,'-t 0 -q');
            [results.train.predicted] = svmpredict(train.Y,XTrain,results.svm,'-q');
            [results.test.predicted] = svmpredict(test.Y,XTest,results.svm,'-q');
        end
        function [Ymat] = createLabelMatrix(Y)
            %Ymat = zeros(size(Y,1),max(Y));
            %Ymat(:,Y) = 1;
            n = size(Y,1);
            m = max(Y);
            assert(m > 0);
            Y(Y < 0) = m+1;
            Ymat = sparse(1:n,Y,1,n,m+1);
            Ymat = Ymat(:,1:m);
        end  
        function [vals] = getValuesOfField(cellArray,field)
            vals = [];
            if ~isfield(cellArray{1},field)
                return;
            end
            if isa(cellArray{1}.(field),'cell')
                vals = {};
                for i=1:numel(cellArray)
                    vals{i} = cellArray{i}.(field);
                end                
            else
                vals = zeros(numel(cellArray),1);
                for i=1:numel(cellArray)
                    vals(i) = cellArray{i}.(field);
                end
            end
        end
        function [m] = getMode(vals)
            [m,freq] = mode(vals,2);
            k = size(vals,2);
            majority = floor(k/2 + 1);
            notMajority = find(freq < majority);
            for i=1:length(notMajority)
                ind = notMajority(i);
                v = vals(ind,:);
                [mNew,freqNew] = mode(v(v ~= m(ind)));
                if freqNew == freq(ind)
                    indices1 = find(m(ind) == v);
                    indices2 = find(mNew == v);
                    minInd = min([indices1(1) indices2(1)]);
                    m(ind) = v(minInd);
                end
            end
        end
        
        function [sigma] = selectBestSigma(W,Ytrain,Ytest,sigmas,useHF)
            scores = zeros(1,length(sigmas));
            percCorrect = scores;            
            if useHF
                YtrainMat = Helpers.createLabelMatrix(Ytrain); 
            else
                Yactual = [Ytrain ; Ytest];
                isTrain = ...
                    logical([ones(size(Ytrain)) ; zeros(size(Ytest))]);
                labeledTest = Yactual > 0 & ~isTrain;                
                Y = [Ytrain ; -1*ones(size(Ytest))];
                YtrainMat = Helpers.createLabelMatrix(Y);
            end
            for i=1:length(sigmas)                
                s = sigmas(i);
                K = Helpers.distance2RBF(W,s);  
                if useHF                    
                    warning off;                
                    [fu, fu_CMN] = harmonic_function(K, YtrainMat);
                    warning on;
                    fuCV = fu(1:length(Ytest),:);
                    fuCMNCV = fu_CMN(1:length(Ytest),:);
                    fu_test = fuCMNCV;
                    [percCorrect(i),scores(i)] = Helpers.getAccuracy(fu_test,...
                        Ytest);
                else                                            
                    warning off;
                    [fu] = llgc(K, YtrainMat);
                    warning on;
                    [percCorrect(i),scores(i)] = Helpers.getAccuracy(...
                        fu(labeledTest,:),Yactual(labeledTest));
                end
                
            end
            [bestAcc,bestAccInd] = max(percCorrect);
            [bestScore,bestScoreInd] = max(scores);
            %[bestAcc bestScore]
            %assert(bestAccInd == bestScoreInd);
            %percCorrect
            sigma = sigmas(bestAccInd);
        end
        
        function sigma = autoSelectSigma(W,Ytrain,Ytest,isTrain,useCV,useHF)
            if nargin < 6
                useHF = true;
            end
            sigmas = [.1 .01 .001 .0001 .00001 .000001];
            percentageArray = [.9 .1 0];
            if useCV && length(Ytrain) > 0
                [split] = DataSet.generateSplitForLabels(percentageArray,Ytrain);
                trainInds = split == 1;
                cvInds = split == 2;            
                YtestTrain = Ytrain(trainInds);
                YtestTest = Ytrain(cvInds);
                if ~useHF
                    YtestTest = [YtestTest ; -1*ones(size(find(~isTrain)))];
                end
                newPerm = [find(trainInds) ; find(cvInds)];
                newPerm = [newPerm ; find(~isTrain)];
                Wperm = W(newPerm,newPerm);            
                sigma = Helpers.selectBestSigma(Wperm,YtestTrain,YtestTest,sigmas,useHF);
            else
                display('autoSelectSigma: No YTrain, default sigma selected');
                sigma = .1;
            end
        end
        
        function [percCorrect,score] = getAccuracy(predMat,Yactual)
            YactualMat = Helpers.createLabelMatrix(Yactual);
            [~,predicted] = max(predMat,[],2);
            predMat = Helpers.normRows(predMat);
            percCorrect = sum(predicted == Yactual)/length(predicted);
            score = sum(sum(YactualMat.*predMat))/length(predicted);
        end
        
        function [W] = normRows(W)
            v = sum(W');
            W = W ./ repmat(v',1,size(W,2));
        end
        
        function [W] = distance2RBF(W,sigma)
            W = W.^2;
            W = W./(-2*sigma);
            W = exp(W);
        end
    end
    
end

