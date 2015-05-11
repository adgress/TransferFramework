classdef Helpers < handle
    %HELPERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)   
        
        function [b] = hasEqualRows(A,B)
            b = false;
            for i=1:size(A,1)
                for j=1:size(B,1)
                    ai = A(i,:);
                    bj = B(j,:);
                    if all(ai == bj)
                        b = true;
                        return;
                    end
                end
            end
        end
        
        function [a] = makeInt8(v)
            a = int8(v);
            if isempty(v)
                return;
            end
            assert(all(v==a));
        end
        
        function [yBinary] = MakeLabelsBinary(y)
            u = unique(y);
            u(u == -1) = [];
            assert(length(u) == 2);
            yBinary = zeros(size(y));
            yBinary(y == u(1)) = 1;
            yBinary(y == u(2)) = -1;
        end
        
        function [v] = RemoveNullColumns(v)
            v( :, ~any(v,1) ) = [];
        end
        
        function [v] = Normalize(val,allVals)
            minVal = min(allVals);
            maxVal = max(allVals);
            assert(minVal ~= maxVal);
            v = (val-minVal)/(maxVal-minVal);
        end
        
        function [v] = NormalizeRange(v,range)
            if nargin < 2
                range = [min(v) max(v)];
            end
            v = v - range(1);
            v = v ./ (range(2)-range(1));
        end                
        
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
            %[s] = getProjectConstants();
            %f = [s.projectDir '/' file];
            f = file;
        end                
        
        %NOTE: Computes squared distances
        function [D] = CreateDistanceMatrixMahabolis(X,V)
            assert(size(V,1) == size(V,2));
            XV = X*V;            
            XV = XV';            
            Xt = X';
            D = bsxfun(@plus,dot(Xt,XV,1)',dot(XV,Xt,1))-2*(Xt'*XV);
            D = real(D);
            %{
            if size(V,1) > 1 && V(1,1) ~= 1
                D2 = zeros(size(X,2));            
                for i=1:size(X,1);
                    for j=1:size(X,1)
                        Xi = X(i,:);
                        Xj = X(j,:);
                        D2(i,j) = (Xi-Xj)*V*(Xi-Xj)';
                        d = D2(i,j);
                        d2 = 0;
                        for k=1:size(V,1)
                            d2 = d2 + V(k,k)*(Xi(k)-Xj(k))^2;
                        end
                        if abs(d-d2) > 1e-12
                            display('');
                            assert(D2(i,j) == d2);
                        end                        
                    end
                end
                norm(D - D2)               
                display('');
            end
            %}
        end
        
        %NOTE: Computes squared distances
        function [D] = CreateDistanceMatrix(X,Y)
            if nargin < 2
                Y = X;
            end
            pc = ProjectConfigs.Create();
            if pc.dataSet == Constants.NG_DATA                
                Y = Y';
                normA = sqrt(sum(X .^ 2, 2));
                normB = sqrt(sum(Y .^ 2, 1));
                D = bsxfun(@rdivide, bsxfun(@rdivide, X * Y, normA), normB);
                D(isnan(D(:))) = 0;
                D = 1 - D;                                
            else
                X=X';
                Y=Y';
                D = bsxfun(@plus,dot(X,X,1)',dot(Y,Y,1))-2*(X'*Y);
                %D = real(D.^.5);
                D = real(D);
            end
            %tic
                        
            %{
            D2 = zeros(size(X,1),size(Y,1));
            for i=1:size(X,1)
                xi = X(i,:);
                a = norm(xi);
                for j=1:size(Y,1)                    
                    yj = Y(:,j);
                    D2(i,j) = 1 - xi*yj/(a*norm(yj));
                end
            end
            %}
            %toc
            %{
            tic
            D = pdist2(X,Y);
            toc
            %}
        end
        
        function [S] = SparsifyDistanceMatrix(W ,k)
            assert(all(size(W) == size(W,1)));
            if k >= size(W,1)
                S = W;
                return;
            end
            [V,I] = sort(W,2,'descend');
            toKeep = I(:,1:k+1); %k+1 to account for self
            K = zeros(size(W));
            for i=1:size(toKeep,2);
                Ii = I(:,i);
                linearInds = sub2ind(size(W),(1:size(W,1))',Ii);
                K(linearInds) = 1;
            end       
            K = (K + K') > 0;
            S = W.*K;
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
        
        function [v] = StructField2Mat(l,field)
            v = [l.(field)];
            v = reshape(v,length(l),length(l(1).(field)));
        end
        
        function [sCombined] = CombineStructs(s1,s2)
            sCombined = struct();
            structs = {s1, s2};
            for structIdx = 1:numel(structs)
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
            
            %TODO: zscore instead of whiten?
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
            Ymat = sparse(length(Y),m);
            n = size(Y,1);
            Y(Y < 0) = m+1;
            for i=1:size(Y,2)            
                assert(m > 0);                
                s = sparse(1:n,Y(:,i),1,n,m+1);
                Ymat = Ymat + s(:,1:m);
            end
        end  
        
        function [b] = hasFieldForArray(cellArray,field)
            for cellArrayItr=1:length(cellArray)
                if ~isfield(cellArray{cellArrayItr},field)
                    b = false;
                    return;
                end
            end
            b = true;
        end
        
        function [b] = isFieldNonemptyForArray(cellArray,field)
            for cellArrayItr=1:length(cellArray)
                if isempty(cellArray{cellArrayItr}.(field))
                    b = false;
                    return;
                end
            end
            b = true;
        end
        
        function [d] = getDimension(m)
            if prod(size(m)) == 1
                d = 1;
            else
                d = sum(size(m) > 1);
            end
        end
        
        function [vals] = getValuesOfField(cellArray,field)
            if ~isfield(cellArray{1},field)
                error('Missing field')
            end
            firstEntry = cellArray{1}.(field);
            if isa(firstEntry,'cell') || ...
                    isa(firstEntry,'struct') || ...
                    Helpers.getDimension(firstEntry) > 1
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
            %W = W.^2;
            W = -W./(2*sigma^2);
            W = exp(W);
        end
        function [b] = cellArrayHasValue(c,value)
            b = false;
            for cellIdx=1:length(c)
                if isequal(c{cellIdx},value)
                    b = true;
                    break;
                end
            end
        end
        function [b] = structMatchesQuery(s,queries)
            b = true;
            for queryIdx=1:length(queries)
                query = queries{queryIdx};
                if ~Helpers.cellArrayHasValue(query.values,s.(query.field))
                    b = false;
                    break;
                end
            end
        end
        function [m] = MakeQuery(fieldName, values)
            m = struct();
            m.field = fieldName;
            m.values = values;
        end
        
        function [] = AssertInvalidPercent(x,perc)
            isInvalid = isnan(x(:)) | isinf(x(:));
            percInvalid = mean(isInvalid);
            if percInvalid > perc
                display(['Perc Invalid:' num2str(percInvalid)]);
                assert(false);                
            end
        end
        
        function [v,inds] = MakeCrossProductOrdered(varargin)
            [v,inds] = Helpers.MakeCrossProductNoDupe(varargin{:});
            vNew = {};
            indsNew = {};
            for idx=1:length(inds)
                currInds = inds{idx};
                if ~issorted(currInds)
                    continue;
                end
                vNew{end+1} = v{idx};
                indsNew{end+1} = inds{idx};
            end
            v = vNew;
            inds = indsNew;
        end
        
        function [v,inds] = MakeCrossProductNoDupe(varargin)
            [v,inds] = Helpers.MakeCrossProduct(varargin{:});
            vNew = {};
            indsNew = {};
            for idx=1:length(inds)
                currInds = inds{idx};
                if length(unique(currInds)) ~= length(currInds)
                    continue;
                end
                vNew{end+1} = v{idx};
                indsNew{end+1} = inds{idx};
            end
            v = vNew;
            inds = indsNew;
        end
        
        function [s] = Cell2StructArray(cellArray)
            %f = fields(cellArray{1});
            s = cellArray{1};
            for idx=2:length(cellArray)
                s(idx) = cellArray{idx};
            end
        end
        
        function [inds] = IsMember(cellArray,toFind)
            inds = zeros(size(cellArray));
            if ~iscell(toFind)
                toFind = {toFind};
            end
            for idx=1:length(toFind)
                inds = inds | ismember(cellArray,toFind{idx});
            end
        end
        
        function [v] = IntersectCellArrays(c1,c2)
            v = {};
            for idx=1:length(c1)
                val = c1{idx};
                if ismember(c2,val)
                    v{end+1} = val;
                end
            end
        end
        
        function [v] = MapCellArray(func,c)
            v = cell(size(c));
            for idx=1:numel(c)
                if exist('v','var')
                    v{idx} = func(c{idx});
                else
                    func(c{idx});
                end
            end
        end
        
        function [v,inds] = MakeCrossProductForFields(fields,o)
            paramsArray = {};
            for i=1:length(fields)
                paramsArray{end+1} = o.(fields{i});
            end
            [v,inds] = Helpers.MakeCrossProduct(paramsArray{:});
        end
        
        function [v,inds] = MakeCrossProduct(varargin)
            v = {};
            inds = {[]};
            isCellArray = isa(varargin{1},'cell');
            if isCellArray
                v{1} = {};
            else
                v{1} = [];
            end
            for i=1:length(varargin)
                vNew = {};
                indsNew = {};
                currArray=varargin{i};
                for vIdx=1:length(v)
                    vCurr = v{vIdx};
                    indsCurr = inds{vIdx};
                    for currArrayIdx=1:length(currArray)
                        vCurrNew = vCurr;                        
                        if isCellArray
                            vCurrNew{end+1} = currArray{currArrayIdx};
                        else
                            vCurrNew(end+1) = currArray(currArrayIdx);
                        end
                        vNew{end+1} = vCurrNew;
                        indsNew{end+1} = [indsCurr currArrayIdx];
                    end
                end
                v = vNew;
                inds = indsNew;
            end
        end
        function [c] = Mat2CellArray(m)
            c = {};
            for i=1:numel(m)
                c{end+1} = m(i);
            end
        end
    end
    
end

