function [] = createImageKernel()
    input = 'PIM/Data/featData/featResults500-1000.mat';
    featResults = load(input);   
    featResults = featResults.featResults;
    numImages = max(featResults.keyPointToImage);
    m = max(featResults.featIndices);
    imageX = zeros(numImages,m);
    for i=1:numImages
        currVecs = find(featResults.keyPointToImage == i);
        vecClusters = featResults.featIndices(currVecs);
        v = zeros(1,m);
        v(vecClusters) = 1;
        display([ num2str(i) ':' num2str(sum(v)/length(v))]);
        imageX(i,:) = v/norm(v);
    end
    K = zeros(numImages);
    for i=1:numImages
        for j=1:numImages
            K(i,j) = imageX(i,:)*(imageX(j,:)');
        end
    end
end
