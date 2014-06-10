%function [imageTagsSimMat,tagSimMat,imageSimMat,wordsKept,imagesKept] = ...
function [wordsKept,imagesKept,locationsKept] = ...
    keepTopNTags(imageTagsSimMat,imageLocationsSimMat,n)
    tagCounts = sum(imageTagsSimMat);
    [vals, I] = sort(tagCounts,'descend');
    if n >= length(vals)
        wordsKept = I;
    else              
        toSkip = 5;
        wordsKept = I(1+toSkip:n+toSkip);
    end
    wordsKept = sort(wordsKept,'ascend');
    imagesKept = sum(imageTagsSimMat(:,wordsKept),2) > 0;
    imagesKept = find(imagesKept);
    
    imageLocationsSimMat = imageLocationsSimMat(imagesKept,:);
    locationsKept = find(sum(imageLocationsSimMat,1) > 0);
end