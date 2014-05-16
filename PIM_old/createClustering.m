function [] = createClustering(numClusters)
    if nargin < 1
        numClusters = 10;
    end
    return;
    numClosest = 10;    
    addpath('..');
    addpath('results');
    load results/clustering;    
    
    V = {clustering.images,clustering.tags,clustering.locations};
    allData = [V{1} ; V{2} ; V{3}];    
    nImages = size(V{1},1);
    nTags = size(V{2},1);
    nLocs = size(V{3},1);
    clustering.allData = allData;
    %[trainAcc,~] = measureMultilabelNNAccuracy(clustering.images,clustering.tags,clustering.imageTagsSimMat_original,clustering.imageTagsSimMat_original,1,clustering.method);
    %trainAcc
    
    createDistancePlot = 0;
    clusterData = 1;
    visualizeData = 1;
    
    if createDistancePlot
        W = clustering.imageTagsSimMat_original;
        distanceMatrix = zeros(size(W));
        for imageIndex=1:size(W,1)
            for tagIndex=1:size(W,2)
                distanceMatrix(imageIndex,tagIndex) = ...
                    sqrt(norm(clustering.images(imageIndex,:) - clustering.tags(tagIndex,:)));                
            end
        end
        meanDistance = mean(distanceMatrix(:));
        meanSupervisedDistance = mean(distanceMatrix(find(W)));
        N = 10;
        pairIndices = find(W(:));
        numTotal = numel(pairIndices);
        percentLessThan = zeros(N,1);   
        taus = (1:10)*meanDistance/N;
        index = 1;
        for tau=taus
            numLessThan = sum(distanceMatrix(pairIndices) <= tau);
            percentLessThan(index) = numLessThan/numTotal;
            index = index+1;
        end
        CreateTable(taus,percentLessThan,meanDistance,meanSupervisedDistance);
    end
    
    if clusterData
        [idx,C] = kmeans(allData,numClusters,'start','cluster','replicates',10);
        %[idx,C] = kmeans(allData,numClusters);
        clustering.im_idx = idx(1:nImages);
        clustering.tag_idx = idx(nImages+1:nImages+nTags);
        clustering.loc_idx = idx(nImages+nTags+1:end);
        clustering.hist = histc(idx,1:numClusters);
        clustering.hist_im = histc(clustering.im_idx,1:numClusters);
        clustering.hist_tag = histc(clustering.tag_idx,1:numClusters);
        clustering.hist_loc = histc(clustering.loc_idx,1:numClusters);
        clustering.hist_all = [clustering.hist_im clustering.hist_tag clustering.hist_loc];
        clustering.hist_all
        clusters = 1:numClusters;
    end
    clustering.clusters = clusters;
    clustering.idx = idx;
    clustering.C = C;
    save(['results/clustering-with-clusters.mat'],'clustering');
    return;
    if visualizeData
        n = size(allData,1);
        X = zeros(n);
        for i=1:n
            for j=1:n
                xi = allData(i,:);
                xj = allData(j,:);
                X(i,j) = sqrt(norm(xi-xj));
            end
        end
        numDims = 2;
        %{
        [allLocs] = loadLocationsFile();
        allLocs = allLocs - repmat(mean(allLocs),size(allLocs,1),1);
        allLocs = allLocs - repmat(min(allLocs),size(allLocs,1),1);
        allLocs = allLocs ./ repmat(max(allLocs),size(allLocs,1),1);
        locationSimMat = zeros(size(locationSimMat));
        for i=1:size(allLocs,1)
            for j=1:size(allLocs,1)
                xi = allLocs(i,:);
                xj = allLocs(j,:);
                p = norm(xi-xj);
                locationSimMat(i,j) = p;
            end
        end
        X = locationSimMat;
        %}
        %{
        load locationSimMat;
        X = locationSimMat;
        %}
        if size(allData,2) < 3
            Y = allData(:,1:2);
        else
            [Y,stress] = mdscale(X,numDims,'start','random','Replicates',1);    
        end        
        %axis auto;
        hold off;
        hold on;        
        showClusters = 1;
        if ~showClusters
            colorMap = hsv(3);  
            if nImages > 0
                scatter(Y(1:nImages,1),Y(1:nImages,2),10,colorMap(1,:),'o');
            end
            if nTags > 0
                scatter(Y(nImages+1:nImages+nTags,1),Y(nImages+1:nImages+nTags,2),20,colorMap(2,:),'x');
            end
            %scatter(Y(nImages+nTags+1:end,1),Y(nImages+nTags+1:end,2),60,colorMap(3,:),'x');
            for i=nImages+nTags+1:size(Y,1)            
                yi = Y(i,:);
                locID = data.locationsKept(i-nImages-nTags);
                text(yi(1),yi(2), num2str(locID));
            end
            legend('Images','Tags','Locations');
        else
            colorMap = hsv(numClusters);
            yImages = Y(1:nImages,1:2);
            yTags = Y(nImages+1:nImages+nTags,1:2);
            yLocs = Y(nImages+nTags+1:end,1:2);
            for i=1:numClusters
                scatter(yImages(clustering.im_idx==i,1),...
                    yImages(clustering.im_idx==i,2),...
                    10,colorMap(i,:),'o');
                scatter(yTags(clustering.tag_idx==i,1),...
                    yTags(clustering.tag_idx==i,2),...
                    30,colorMap(i,:),'x');                
                scatter(yLocs(clustering.loc_idx==i,1),...
                    yLocs(clustering.loc_idx==i,2),...
                    10,colorMap(i,:),'+');                    
            end
        end
        axis([min(Y(:,1)) max(Y(:,1)) min(Y(:,2)) max(Y(:,2))]);        
        hold off;
        
    end
    %return;
    for i=1:numel(clusters)
        
        
        cluster = clusters(i);
        idx_im = find(clustering.im_idx == cluster);
        idx_tag = find(clustering.tag_idx == cluster);
        idx_loc = find(clustering.loc_idx == cluster);
        %{
        if visualizeData
            if numDims == 2
                scatter(Y(idx_im,1),Y(idx_im,2),10,colorMap(i,:),'o');
                scatter(Y(idx_tag+nImages,1),Y(idx_tag+nImages,2),60,colorMap(i,:),'o');
                scatter(Y(idx_loc+nImages+nTags,1),Y(idx_loc+nImages+nTags,2),60,colorMap(i,:),'s');
            else
                scatter3(Y(idx_im,1),Y(idx_im,2),Y(idx_im,3),10,colorMap(i,:),'o');
                scatter3(Y(idx_tag+nImages,1),Y(idx_tag+nImages,2),Y(idx_tag+nImages,3),60,colorMap(i,:),'o');
                scatter3(Y(idx_loc+nImages+nTags,1),Y(idx_loc+nImages+nTags,2),Y(idx_loc+nImages+nTags,3),60,colorMap(i,:),'s');
            end
        end
        %}
        images = clustering.images(idx_im,:);
        tags = clustering.tags(idx_tag,:);
        locations = clustering.locations(idx_loc,:);
        Ci = C(i,:);
        centroid = mean([images;tags;locations]);        
        [closestImages,d1]= getClosest(images,centroid,numClosest);
        [closestTags,d2]= getClosest(tags,centroid,numClosest);
        [closestLocations,d3]= getClosest(locations,centroid,numClosest);
                
        [closestItems,d4] = getClosest([images;tags;locations],centroid,numClosest);
        numImages = sum(closestItems <= numel(idx_im));
        numTags = sum(closestItems <= (numel(idx_im)+numel(idx_tag))) - numImages;
        display(sprintf('Images:%d,Tags:%d,Locs:%d',numImages,numTags,numClosest - numImages - numTags));
        d = [d1 , d2 , d3];
        
        images = idx_im(closestImages);
        tags = idx_tag(closestTags);
        locations = idx_loc(closestLocations);
        
        directory = ['clustering/cluster'  num2str(i) '/'];
        delete([directory '*.pgm']);
        delete([directory '*.jpg']);
        [~,~,~] = mkdir('.',directory);
        
        printClusterDataToFile(directory,images,tags,locations,d,data);
    end
    if visualizeData
        hold off;
    end
end

function [] = CreateTable(taus,percentLessThan,meanDistance,meanSupervisedDistance);
    %columnNames = {'tau','test=local','test=news','test=shopping'};
    rowNames = {'tau','Percent Closter Than Tau'};
    f = figure('Position', [100 100 1200 300]);
    t = uitable('Parent', f, 'Position', [0 0 1200 200],'RowName',rowNames);
    set(t, 'Data', [taus ; percentLessThan']);
    MyBox = uicontrol(f,'Style','text');
    set(MyBox,'String',sprintf('Mean Distance = %f',meanDistance));
    set(MyBox,'Position',[150 220 200 25]);

end