function [acc,NNData] = measureMultilabelNNAccuracy(view1,view2,Wmt_train,answer,k,method)
    loadConstants;
    if nargin < 5
        k = 1;
    end
    idx = knnsearch(view2,view1,'k',k);
    idx_all = knnsearch(view2,view1,'k',size(view2,1));
    numCorrect = 0;
    count = 0;
    predictedVec = zeros(size(view2,1),1);
    [~,mostPopularTags] = sort(sum(Wmt_train,1),'descend');
    perTagCorrect = zeros(size(view2,1),1);
    perTagTotal = perTagCorrect;
    NNData.answers = answer;
    NNData.nn = idx_all;
    if method == GUESS
        NNData.nn = repmat(mostPopularTags,size(view1,1),1);
    end
    for i=1:size(view1,1)
        numLabels = sum(answer(i,:) > 0);
        if method == GUESS      
            predictedTags = mostPopularTags(1:min(k,numLabels));
        else
            predictedTags = idx(i,1:min(k,numLabels));        
        end
        count = count + min(k,numLabels);
        isCorrect = sum(answer(i,predictedTags) > 0);
        numCorrect = numCorrect + isCorrect;
        predictedVec(predictedTags) = predictedVec(predictedTags) + 1;
        for j=1:numel(predictedTags)
            tag = predictedTags(j);
            perTagTotal(tag) = perTagTotal(tag) + 1;
            perTagCorrect(tag) = perTagCorrect(tag) + answer(i,tag);
        end
    end
    %correct = diag(confMat)
    %incorrect = sum(confMat - diag(correct),2)
    perTagPrecision = perTagCorrect./perTagTotal;
    perTagPrecision(isnan(perTagPrecision)) = 0;
    acc = numCorrect/count;
    acc = mean(perTagPrecision);
    %display(sprintf('Knn Accuracy (K = %d): %2.2f',k,acc));
end
