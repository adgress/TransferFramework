function [] = pruneDS3()
    file = 'Data/ITS/DS3-39.mat';
    saveFileName = 'data/ITS/DS3-39-pruned.mat';
    minQuestions = 30;
    skillsToSkip = 1;
    
    data = load(file);
    data = data.data;
    
    numPerLabel = hist(data.Y,unique(data.Y));
    %{
    for idx=1:length(numPerLabel)
        display([num2str(numPerLabel(idx)) ': ' data.YNames{idx}]);
    end
    %}
    labelIDs = 1:length(numPerLabel);
    labelsToUse = numPerLabel > minQuestions & labelIDs ~= skillsToSkip;
    data = removeSkills(data,~labelsToUse);
    data = pruneStudents(data);
    
    save(saveFileName,'data');
end

function data = pruneStudents(data)
    minQuestionsAnswered = 20;
    toRemove = zeros(size(data.W{1},2),1);
    hasAnsweredMinimum = (sum(data.W{1} + data.W{2}) >= minQuestionsAnswered);
    toRemove(~hasAnsweredMinimum) = true;
    
    for idx=1:length(data.W)
        data.W{idx} = data.W{idx}(:,~toRemove);
    end
    
    data.WCorrect = data.WCorrect(:,~toRemove);
    data.WInCorrect = data.WInCorrect(:,~toRemove);
    
    %Have wrong incorrect WNames for some reason.  Fix this if we want to
    %use WNames
    %data.WNames{2} = data.WNames{2}(~toRemove);
    data.WIDs{2} = data.WIDs{2}(~toRemove);
    a = data.W{1} + data.W{2};
end

function [data,numRemoved] = removeSkills(data,I)
    toRemove = zeros(size(data.Y));
    inds = find(I);
    for idx=1:length(inds)
        toRemove = toRemove | data.Y == inds(idx);
    end        

    for idx=1:length(data.W)
        data.W{idx} = data.W{idx}(~toRemove,:);
    end
    data.WCorrect = data.WCorrect(~toRemove,:);
    data.WInCorrect = data.WInCorrect(~toRemove,:);
    data.WNames{1} = data.WNames{1}(~toRemove);
    data.WIDs{1} = data.WIDs{1}(~toRemove);
    data.YNames(I) = [];
    data.Y(toRemove) = [];
    YLeft = find(~I);
    
    %Remap Y labels
    for idx=1:length(YLeft)
        data.Y(data.Y == YLeft(idx)) = idx;
    end
    numRemoved = sum(toRemove);
end