function [] = printHierClustering()
    addpath('..');
    addpath('results');
    load hierClustering;    
    allData = [hierClustering.images ; hierClustering.tags ; hierClustering.locations];
    nImages = size(hierClustering.images,1);
    nTags = size(hierClustering.tags,1);
    nLocs = size(hierClustering.locations,1);
    
    %numClusters = 40;
    numClusters = 10;
    useCustomMetric = 0;
    useCustomLinkage = 1;
    if useCustomLinkage        
        [loc_idx,loc_C] = kmeans(hierClustering.locations,numClusters,...
            'emptyaction','singleton','start','uniform','replicates',10);
        histc(loc_idx,1:numClusters)
        [c,C] = kmeans(allData,numClusters,'start',loc_C,'replicates',1);        
    else
        if useCustomMetric
            objectTypes = [ones(nImages,1) ; 2*ones(nTags,1) ; 3*ones(nLocs,1)];
            z = linkage([allData objectTypes],'weighted',{@distfunc});        
        else
            metric = 'euclidean';
            z = linkage(allData,'ward',metric);
        end
        c = cluster(z,'maxclust',numClusters);%,'criterion','distance');        
    end
    for i=1:size(c,2)
        histc(c(:,i),1:numClusters(i))
    end
    numItems = 4;

    heightIndex = 1;
    clusters = 1:numClusters;
    for i=clusters
        clusterIndex = i;
                
        imagesInCluster_indices = find(c(1:nImages,heightIndex) == clusterIndex);
        tagsInCluster_indices = find(c(nImages+1:nImages+nTags,heightIndex) == clusterIndex);
        locationsInCluster_indices = find(c(nImages+nTags+1:end,heightIndex) == clusterIndex);
    
        imagesInCluster = hierClustering.images(imagesInCluster_indices,:);
        tagsInCluster = hierClustering.tags(tagsInCluster_indices,:);
        locationsInCluster = hierClustering.locations(locationsInCluster_indices,:);
        
        centroid = mean(allData(c(:,heightIndex) == clusterIndex,:));
        [closestImages,d1] = getClosest(imagesInCluster,centroid,numItems);
        [closestTags,d2] = getClosest(tagsInCluster,centroid,numItems);
        [closestLocations,d3] = getClosest(locationsInCluster,centroid,numItems);

        d = [d1 , d2 , d3];
        
        images = imagesInCluster_indices(closestImages);
        tags = tagsInCluster_indices(closestTags);
        locations = locationsInCluster_indices(closestLocations);
        
        directory = ['hierClustering/numClusters' num2str(numClusters) '/cluster'  num2str(i) '/'];
        delete([directory '*.pgm']);
        delete([directory '*.jpg']);
        [~,~,~] = mkdir('.',directory);
        
        printClusterDataToFile(directory,images,tags,locations,d,data);
    end
end

function [d] = distfunc(xi,X)    
    X_types = X(end,:);
    X_norm = X(1:end-1,:) - repmat(xi(1:end-1),size(X,1),1);
    d = diag(X_norm'*X_norm);
    d = sqrt(d);
    xType = xi(end);
    for i=1:size(X_norm,2)
        
    end
end
