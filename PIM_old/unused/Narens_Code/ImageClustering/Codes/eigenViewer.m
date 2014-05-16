threeColumnMatrix=dlmread('../data_500(minimini)/SimilarityMatrix_ForTags.txt');
k=3;
simMat=convertSparseColumnsToSparseMat(threeColumnMatrix);
[eigVectors,eigValues] = eigs(simMat,k+2);
data=eigVectors(:,2:k+2);

[IDX,C] = kmeans(data,k);

scatter3(data(:,2),data(:,3),data(:,4), 5, IDX);
title('Just Tags');

