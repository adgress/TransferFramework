function [] = mainDBLP()
    addpath('dblp');
    dblp = loadDBLP();
    
    %range = 1:30176;
    range = 1:2000;
    X_1 = dblp.cikm(range,range);
    X_2 = dblp.kdd(range,range);
    k = sum(X_1(:)+X_2(:));
    W_12 = speye(size(X_1,1),size(X_2,2));
    W_12 = W_12 + sparse(rand(size(W_12)) > .99);
    W_12 = k*W_12;
    [vecs1,vecs2] = computeProjectionVectors(X_1,X_2,W_12,10);
    X_1p = X_1*vecs1;
    X_2p = X_2*vecs2;
    plotData3D(X_1p,'r',10);
    hold on;
    plotData3D(X_2p,'b',50);
end

function [] = plotData3D(X,color,size)
    scatter3(X(:,1),X(:,2),X(:,3),size,color);
end

function [vecs1,vecs2] = computeProjectionVectors(X_1,X_2,W_12,numVectors)
    X = blkdiag(X_1,X_2);  
    W = [speye(size(X_1)) W_12;...
        W_12' speye(size(X_2))];
    D = diag(sum(W,2));
    L = W;
    A = X*L*X';
    B = X*D*X';
    B = B + speye(size(B));
    condest(W)
    condest(A)
    condest(B)
    [vecs,vals] = eigs(A,B,numVectors);
    vals = diag(vals);
    [vals,I] = sort(vals,'descend');
    vals
    vecs = vecs(:,I);
    vecs = vecs(:,1:numVectors);
    vecs1 = vecs(1:size(X_1,1),:);
    vecs2 = vecs(size(X_1,1)+1:end,:);
    for i=1:size(vecs1,2)
        vecs1(:,i) = vecs1(:,i)/norm(vecs1(:,i));
    end
    for i=1:size(vecs2,2)
        vecs2(:,i) = vecs2(:,i)/norm(vecs2(:,i));
    end
end