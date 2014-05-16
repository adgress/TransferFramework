function [cosineSimilarity] = ImageImageMatch(keypointsSet1, keypointsSet2)
    cosineSimilarity=matchFromKeypoints(keypointsSet1, keypointsSet2);
end

