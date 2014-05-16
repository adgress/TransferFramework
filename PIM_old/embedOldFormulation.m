function [a,b,c] = embedOldFormulation(Km_train,Kt_train,Kl_train,...
    Wmt_train,Wml_train,Wtl_train)
    useLaplacian = 1;

    
    W = [0*eye(size(Km_train)) Wml_train Wmt_train;...
        Wml_train' 0*eye(size(Kl_train)) Wtl_train';...
        Wmt_train' Wtl_train 0*eye(size(Kt_train))];
    K = blkdiag(Km_train,Kl_train,Kt_train);
    D = diag(sum(W,2));
    
    %D = eye(size(D));
    
    L = D - W;
    if ~useLaplacian
        L = W;
    end
    BNormalization = .1;
    A = K*L*K';
    B = K*D*K';
    B = B + BNormalization*eye(size(B));
    printCondNumber(L,'L');
    printCondNumber(A,'A');
    printCondNumber(B,'B');

    [vecs,vals] = eig(A,B);
    vals = diag(vals);

    if ~useLaplacian
        [sortedVals,I] = sort(vals,'descend');
        vecs = vecs(:,I);
    else
        [sortedVals,I] = sort(vals,'ascend');
        vecs = vecs(:,I);
        vecs = vecs(:,1:end);
    end

    m1 = size(Km_train,1);
    m2 = size(Kl_train,1);

    vecSets = cell(3,1);
    vecSets{1} = vecs(1:m1,:);
    vecSets{2} = vecs(m1+1:m1+m2,:);
    vecSets{3} = vecs(m1+m2+1:end,:);
    UL = A(1:numImages,1:numImages);
    UR = A(1:numImages,numImages+1:end);
    LL = A(numImages+1:end,1:numImages);
    LR = A(numImages+1:end,numImages+1:end);
    v1 = vecSets{1}(:,:);
    v3 = vecSets{3}(:,:);
    a = diag(v1'*UL*v1);
    b = diag(v1'*UR*v3);
    d = diag(v3'*LR*v3);
    values = {a,b,d};
    %{
            figure;
            hold on;
            lineSpecs = {'-r','-b','-g'};
            for j=1:numel(values)
                v = values{j};
                plot(1:numel(v),v,lineSpecs{j});
            end
            legend('Image-Image','Image-Tag','Tag-Tag');
            hold off;
    %}
    %Necessary because some projection vectors are 0
    for j=1:length(vecSets)
        v = vecSets{j};
        newVecs = [];
        index = 1;
        for i=1:size(v,2);
            vi = v(:,i);
            if norm(vi) < 1e-3
                continue;
            end
            newVecs(:,index) = vi/norm(vi);
            index = index + 1;
        end
        vecSets{j} = newVecs;
    end
    a = vecSets{1};
    b = vecSets{2};
    c = vecSets{3};
end