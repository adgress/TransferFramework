function [acc] = measureNNAccuracy(view1,view2,answer,k)
    if nargin < 4
        k = 1;
    end
    idx = knnsearch(view2,view1);
    answer = answer(:,2);
    correct = idx == answer;
    acc = sum(correct)/numel(correct);
    display(sprintf('Knn Accuracy (K = %d): %2.2f',k,acc));
end