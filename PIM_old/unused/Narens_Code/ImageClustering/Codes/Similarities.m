function [cosineSimilarity jaccardSimilarity] = Similarities(totalMatch, length1, length2)
    cosineSimilarity=(totalMatch)/(sqrt(length1)*sqrt(length2));        
    jaccardSimilarity=totalMatch/(length1+length2-totalMatch);    
    
end

