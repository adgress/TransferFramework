%Image matrices

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

% Tag matrices

Tag=load('tagSimMat.mat');
Wt=Tag.tagSimMat;
Wt=Wt-eye(590);
D=diag(sum(Wt'));
Lt=D-Wt;

figure;
[v,d]=eig(Lt);
scatter3(v(:,2),v(:,3),v(:,4));
title('Just Tags');


relIL=load('ImageLocations.txt');
relILMat=zeros(500,99);

for(i=1:size(relIL))
 relILMat(relIL(i,1),relIL(i,2))=1;
end;

relIT=load('ImageTagsFile.txt');
relITMat=zeros(500,590);

for(i=1:size(relIT))
 relITMat(relIT(i,1),relIT(i,2))=1;
end;

%Lhuge is laid as out: 
% Image      Locations    Tags
% Locations
% Tags

Lhuge=[Wi 100*relILMat 100*(0.5611)*relITMat; 100*relILMat' Wl zeros(99,590); 100*(0.5611)*relITMat' zeros(99,590)' Wt;];

% Need to renormalize it. Use the RW Laplacian

LhugeTrans = diag(sum(Lhuge))^-1*Lhuge;
Lhuge = eye(1189)-LhugeTrans;

figure;
[v,d]=eig(Lhuge);
scatter3(v(1:500,2),v(1:500,3),v(1:500,4),10,'r');
hold on;
scatter3(v(501:599,2),v(501:599,3),v(501:599,4),50,'b');
hold on;
scatter3(v(600:1189,2),v(600:1189,3),v(600:1189,4),50,'g');
title('Images (Red) and Locations(Blue) and Tags (Green)');
hold off;

figure
ids=kmeans(v(:,2:10),10);
hist(ids); 