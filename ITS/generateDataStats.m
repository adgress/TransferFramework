function [  ] = generateDataStats(  )
pc = ProjectConfigs.Create();
switch pc.dataSet
    case Constants.DS1
        file = 'Data/ITS/DS1-69_reg';
    case Constants.DS2
        file = 'Data/ITS/DS2-35_reg';
    case Constants.DS3
        %file = 'Data/ITS/DS3-39';
        file = 'Data/ITS/DS3-39_reg';
    case Constants.PRG
        file = 'Data/ITS/Prgusap1_reg';
end
data = load(file);
data = data.data;
isLabeled = (data.W{1} + data.W{2}) > 0;
W = data.W{1};
numLabels = length(unique(data.Y));

numQuestions = [];
numPairs = [];
avg = [];
variance = [];
skills = unique(data.Y);
for labIdx=1:numLabels
    hasLabel = data.Y == skills(labIdx);
    subW = W(hasLabel,:);
    isLabeledCurr = isLabeled(hasLabel,:);
    allVals = subW(isLabeledCurr(:));
    numQuestions(labIdx) = sum(hasLabel);
    numPairs(labIdx) = length(allVals);
    avg(labIdx) = mean(allVals);
    variance(labIdx) = var(allVals);
end
format('bank');
d = [skills' ; numQuestions ; numPairs ;avg ; variance];
display('Skill - Num Questions - Num Pairs - Mean - Variance');
display(d');
c = getSkillCorrelation(file);
end

