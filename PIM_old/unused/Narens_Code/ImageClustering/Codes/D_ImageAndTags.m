%Image matrices

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


% Tag matrices
SimilarityMatrix_ForTags=dlmread(strcat(inputDir,'/SimilarityMatrix_ForTags.txt'));
Tag.tagSimMat=convertSparseColumnsToSparseMat(SimilarityMatrix_ForTags);
Wt=Tag.tagSimMat;
tSize=size(Wt,1);
Wt=Wt-eye(tSize);
D=diag(sum(Wt'));
Lt=D-Wt;

figure;
[v,d]=eig(Lt);
scatter3(v(:,2),v(:,3),v(:,4));
title('Just Tags');


relIT=load(strcat(inputDir,'/ImageTagsFile.txt'));
relITMat=zeros(iSize,tSize);

%Since some images don't have a tag. Enforce a Laplacian
relITMat(:,:)=1/tSize;

% for(i=1:size(relIT))
%  relITMat(relIT(i,1),relIT(i,2))=relITMat(relIT(i,1),relIT(i,2))+1;
% end;

%msh


% Since an image can have multiple tags (unlike a location). Need to
% normalize so they sum to 1.
DIT=diag(sum(relITMat'));
relITMat=DIT^(-1)*relITMat;

%Lhuge is laid as out: 
% Image      Locations    Tags
% Locations
% Tags

Lhuge=[Wi 1000*relITMat; 1000*relITMat' Wt;];

% Need to renormalize it. Use the RW Laplacian

LhugeTrans = diag(sum(Lhuge))^-1*Lhuge;
Lhuge = eye(iSize+tSize)-LhugeTrans;

figure;
[v,d]=eig(Lhuge);
scatter3(v(1:iSize,2),v(1:iSize,3),v(1:iSize,4),10,'r');
hold on;
scatter3(v(iSize+1:iSize+tSize,2),v(iSize+1:iSize+tSize,3),v(iSize+1:iSize+tSize,4),10,'g');
title('Images (Red) and Tags (Green)');
hold off;

figure
ids=kmeans(v(:,2:10),10);
hist(ids); 

figure; hist(ids(1:iSize)); title('Images');
figure; hist(ids(iSize+1:iSize+tSize)); title('Tags');
