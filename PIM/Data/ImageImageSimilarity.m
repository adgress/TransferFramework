function [cosineSimilarity] = ImageImageSimilarity(keypointsSet1, keypointsSet2)
    totalMatch=matchFromKeypoints(keypointsSet1, keypointsSet2);    
    length1=size(keypointsSet1,1);
    length2=size(keypointsSet2,1);
    cosineSimilarity=(totalMatch)/(sqrt(length1)*sqrt(length2));    
    
    %jaccardSimilarity=totalMatch/(length1+length2-totalMatch);    
    
end

