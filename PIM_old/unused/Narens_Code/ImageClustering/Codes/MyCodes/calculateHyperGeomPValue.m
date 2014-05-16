function [pval] = calculateHyperGeomPValue( clusterAssignments, labelAssignments, labels, classID, cluster)
    
    % this function calculates the p-value from the hyper-geometric
    % distribution    
    clusterSize = length(clusterAssignments(clusterAssignments==cluster));
    classSize = length(labelAssignments(labelAssignments==labels(classID)));

    indicesWithClass=find(labelAssignments==labels(classID));
    indicesWithCluster=find(clusterAssignments==cluster);

    overlap = intersect(indicesWithClass, indicesWithCluster);
    
    M=clusterSize;
    n=classSize;
    k=length(overlap);
    N=length(labelAssignments);
    
    pval=sum(hygepdf(k:M, N, M, n));   
    %pval=sum(hygepdf(k, N, M, n));   
end