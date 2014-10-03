classdef Helpers < handle
    %HELPERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)   
        
        
        function [] = MakeDirectoryForFile(fileName)
            inds = strfind(fileName,'/');
            lastInd = inds(end);
            d = fileName(1:lastInd);
            if ~exist(d,'dir')
                mkdir(d);
            end
        end
        function [] = PrintNum(s,n)
            display([s num2str(n)]);
        end
        
        function [v] = SelectFromRows(X,inds)
            m = size(X,2);
            inds = logical(Helpers.createLabelMatrix(inds,m));
            v = X(inds(:));
        end
        
        function [X] = AddBias(X)
            X = [X ones(size(X,1),1)];
        end
        
        function [Xp] = ApplyPCA(X,proj,mean)
            Xcentered = X - repmat(mean,size(X,1),1);
            Xp = Xcentered*proj;
        end
        function [b] = IsBinary(W)
            b = sum(W(:) == 1 | W(:) == 0) == numel(W);
        end
        function [dupeX] = DupeRows(X,numDupe)
            inds = zeros(sum(numDupe),1);
            index = 0;
            for i=1:length(numDupe)
                k = numDupe(i);
                inds(index+1:index+k) = i;
                index = index + k;
            end
            dupeX = X(inds,:);
        end
        function [dupeX] = DupeRowsForW(X,W)
            isNonZero = W ~= 0;
            numToDupe = sum(isNonZero,2);
            dupeX = Helpers.DupeRows(X,numToDupe);
        end
        
        function [f] = MakeProjectURL(file)
            [s] = getProjectConstants();
            f = [s.projectDir '/' file];
        end
        
        function [v] = NormalizeRange(v,range)
            if nargin < 2
                range = [min(v) max(v)];
            end
            v = v - range(1);
            v = v ./ (range(2)-range(1));
        end                
        
        function [D] = CreateDistanceMatrix(X,Y)
            if nargin < 2
                Y = X;
            end
            %{
            X=X';
            Y=Y';
            D = bsxfun(@plus,dot(X,X,1)',dot(Y,Y,1))-2*(X'*Y); 
            D = real(D.^.5);     
            D2 = zeros(size(X,2),size(Y,2));
            for i=1:size(D2,1)
                xi = X(:,i);
                for j=1:size(D2,2);
                    yj = Y(:,i);
                    D2(i,j) = sqrt(norm(xi-yj));
                end
            end
            %}
            D = pdist2(X,Y);
        end
        
        function [perf] = getAllLabelAccuracy(pred,act)
            maxLabel = max(act);
            perf = zeros(maxLabel,1);
            for i=1:maxLabel
                perf(i) = Helpers.getLabelAccuracy(pred,act,i);
            end
        end

        function [perf] = getLabelAccuracy(pred,act,label)
            perf = sum(act == label & pred == act)/sum(act == label);
        end
        
        function [bestInds] = KNN(Xtrain,Xtest,k,configs)
            useSim = nargin >=4 && configs('useKNNSim');
            if useSim
                D = Xtrain*Xtest';
            else
                D = Helpers.CreateDistanceMatrix(Xtrain,Xtest);
            end
            bestInds = zeros(size(Xtest,1),k);
            for i=1:k
                if useSim
                    [~,inds] = max(D);
                else
                    [~,inds] = min(D);
                end
                bestInds(:,i) = inds';
                numTest = size(Xtest,1);
                indMat = sparse(inds,1:numTest,true(numTest,1),size(D,1),size(D,2));
                if i ~= k
                    if useSim
                        D(indMat) = -Inf;
                    else
                        D(indMat) = Inf;
                    end
                end
            end
        end
        
        function [split] = split_string(string,delim)
            split = {};
            while numel(string) > 0
                [split{end+1}, string] = strtok(string,delim);
            end
        end       
        
        function [sCombined] = CombineStructs(s1,s2)
            sCombined = struct();
            structs = {s1, s2};
            for structIdx = 1:numel(struct)
                fields = fieldnames(structs{structIdx});
                currStruct = structs{structIdx};
                for fieldIdx = 1:numel(fields)
                    field = fields{fieldIdx};
                    sCombined.(field) = currStruct.(field);
                end
            end
        end
        
        function [map] = CombineMaps(map1,map2)
            assert(map1,'containers.Map');
            assert(map2,'containers.Map');
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
        
        function [] = RemoveKey(m,key)
            if isKey(m,key)
                remove(m,key);
            end
        end
        
        function [m2] = CopyMap(m)            
            m2 = Helpers.CombineMaps(m,containers.Map);
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
        function [X,m] = CenterData(X,m)
            if nargin < 2
                m = mean(X,1);
            end
            X = X - repmat(m,size(X,1),1);
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
        function [Ymat] = createLabelMatrix(Y,m)
            if nargin < 2
                m = max(Y(:));
            end
            %Ymat = zeros(size(Y,1),max(Y));
            %Ymat(:,Y) = 1;
            Ymat = 0;
            n = size(Y,1);
            Y(Y < 0) = m+1;
            for i=1:size(Y,2)            
                assert(m > 0);                
                s = sparse(1:n,Y(:,i),1,n,m+1);
                Ymat = Ymat + s(:,1:m);
            end
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
                n = numel(cellArray);
                l = length(cellArray{1}.(field));
                assert(min(size(l)) == 1);
                vals = zeros(n,l);
                for i=1:numel(cellArray)
                    v = cellArray{i}.(field);
                    if size(v,1) > 1
                        v = v';
                    end
                    vals(i,:) = v;
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
        function [percCorrect,score] = getAccuracy(predMat,Yactual,label)
            if nargin < 3
                label = -1;
            end
            YactualMat = Helpers.createLabelMatrix(Yactual);
            [~,predicted] = max(predMat,[],2);
            predMat = Helpers.normRows(predMat);
            percCorrect = sum(predicted == Yactual)/length(predicted);
            entryScores = sum(YactualMat.*predMat,2);
            entryScores(isnan(entryScores)) = 0;
            score = sum(entryScores)/length(predicted);
        end             
        function [percCorrect,score] = getAccuracyPerLabel(predMat,Yactual)
            m = max(Yactual);
            percCorrect = zeroes(m,1);
            score = percCorrect;
            error('Not Finished');
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

