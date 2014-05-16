% Image matrices

Im=load('imageSimMat.mat');
Wi=Im.imageSimMat;
Wi=Wi-eye(500);
D=diag(sum(Wi'));
Li=D-Wi;

figure;
[v,d]=eig(Li);
scatter3(v(:,2),v(:,3),v(:,4));
title('Just Images');

% Location matrices

Loc=load('locationSimMat.mat');
Wl=Loc.locationSimMat;
Wl=Wl-eye(99);
D=diag(sum(Wl'));
Ll=D-Wl;

figure;
[v,d]=eig(Ll);
scatter3(v(:,2),v(:,3),v(:,4));
title('Just Locations');

relIL=load('ImageLocations.mat');
relIL = relIL.ImageLocations;
relILMat=zeros(500,99);

for i=1:size(relIL,1)
 relILMat(relIL(i,1),relIL(i,2))=1;
end;

Lhuge=[Wi 20*relILMat; 20*relILMat' Wl];

% Need to renormalize it. Use the RW Laplacian

LhugeTrans = diag(sum(Lhuge))^-1*Lhuge;
Lhuge = eye(599)-LhugeTrans;

figure;
[v,d]=eig(Lhuge);
scatter3(v(1:500,2),v(1:500,3),v(1:500,4),10,'r');
hold on;
scatter3(v(501:599,2),v(501:599,3),v(501:599,4),50,'b');
title('Images and Locations');
hold off;

figure
ids=kmeans(v(:,2:10),10);
hist(ids); 
acc = measureNNAccuracy(v(1:500,2:10),v(501:end,2:10),relIL);
acc