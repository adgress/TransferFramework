% Image matrices

%%mention the input directory
inputDir='../data_vanc-1k';

SimilarityMatrix_ForTags=dlmread(strcat(inputDir,'/SimilarityMatrix_ForImages.txt'));
Im.imageSimMat=convertSparseColumnsToSparseMat(SimilarityMatrix_ForTags);

Wi=Im.imageSimMat;
iSize=size(Wi,1);
Wi=Wi-eye(iSize);
D=diag(sum(Wi'));
Li=D-Wi;

figure;
[v,d]=eig(Li);
scatter3(v(:,2),v(:,3),v(:,4));
title('Just Images');

% Location matrices

SimilarityMatrix_ForLocation=dlmread(strcat(inputDir,'/SimilarityMatrix_ForLocation.txt'));
Tag.locSimMat=convertSparseColumnsToSparseMat(SimilarityMatrix_ForLocation);
Wl=Tag.locSimMat;
lSize=size(Wl,1);
Wl=Wl-eye(lSize);
D=diag(sum(Wl'));
Ll=D-Wl;

figure;
[v,d]=eig(Ll);
scatter3(v(:,2),v(:,3),v(:,4));
title('Just Locations');

relIL=load(strcat(inputDir,'/ImageLocations.txt'));

relILMat=zeros(iSize,lSize);

for(i=1:size(relIL))
 relILMat(relIL(i,1),relIL(i,2))=1;
end;

%Lhuge=[Wi relILMat; relILMat' Wl];
Lhuge=[Wi 20*relILMat; 20*relILMat' Wl];

% Need to renormalize it. Use the RW Laplacian

LhugeTrans = diag(sum(Lhuge))^-1*Lhuge;
Lhuge = eye(iSize+lSize)-LhugeTrans;

figure;
[v,d]=eig(Lhuge);
scatter3(v(1:iSize,2),v(1:iSize,3),v(1:iSize,4),10,'r');
hold on;
scatter3(v(iSize+1:iSize+lSize,2),v(iSize+1:iSize+lSize,3),...
    v(iSize+1:iSize+lSize,4),50,'b');
title('Images and Locations');
hold off;

figure
ids=kmeans(v(:,2:10),10);
hist(ids); 
