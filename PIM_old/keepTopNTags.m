%function [imageTagsSimMat,tagSimMat,imageSimMat,wordsKept,imagesKept] = ...
function [wordsKept,imagesKept,locationsKept] = ...
    keepTopNTags(imageTagsSimMat,imageLocationsSimMat,n)
    tagCounts = sum(imageTagsSimMat);
    [vals, I] = sort(tagCounts,'descend');
    %wordsKept = I(1:n);    
    wordsKept = I(2:n+1);
    wordsKept = sort(wordsKept,'ascend');
    imagesKept = sum(imageTagsSimMat(:,wordsKept),2) > 0;
    imagesKept = find(imagesKept);
    
    imageLocationsSimMat = imageLocationsSimMat(imagesKept,:);
    locationsKept = find(sum(imageLocationsSimMat,1) > 0);
end