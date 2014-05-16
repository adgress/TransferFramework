simmat=applyThresholdOnSimMat(imageSimMat,0.0);
%simmat=imageSimMat;

simmatOriginal = simmat;
W=simmat;
D=diag(sum(W'));
L=D-W;
sum(L(:,1))
[v,d]=svds(simmatOriginal,10,0.001);
d
clusids=kmeans(v(:,1:5),5);
%clusids

labels=unique(clusids);
for i=1:length(labels)
    noOfElements=length(clusids(clusids==labels(i)));
    fprintf('# of elements in cluster %d: %d\n', labels(i), noOfElements);
end
