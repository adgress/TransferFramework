function [I,dist] = getClosest(V,c,k)
    distances = [];
    for i=1:size(V,1)
        vi = V(i,:);
        d = norm(vi-c);
        distances(i) = d;
    end
    [sortedDistances,I] = sort(distances,'ascend');    
    I = I(1:min(k,numel(distances)));
    dist = sortedDistances(1:min(k,numel(distances)));
end