function [C] = getSkillCorrelation(file)
if ~exist('file','var')
    error('');
end
%file = 'Data/ITS/DS1-69.mat';
%file = 'Data/ITS/DS2-35.mat';
data = load(file);
data = data.data;
numStuds = size(data.WCorrect,2);
numSteps = size(data.WCorrect,1);
W = data.W{1};
answeredQuestion = (data.W{1} + data.W{2}) > 0;
Y = data.Y;
numSkills = max(Y);
studentSkills = zeros(numStuds,numSkills);
for studIdx=1:numStuds
    for skillIdx=1:numSkills
        stepsWithSkill = Y == skillIdx & answeredQuestion(:,studIdx);
        Wcurr = W(stepsWithSkill,studIdx);
        if isempty(Wcurr)
            studentSkills(studIdx,skillIdx) = nan;
            continue;
        end
        studentSkills(studIdx,skillIdx) = mean(Wcurr);
    end
end
C = zeros(numSkills);
for i=1:numSkills
    for j=1:numSkills
        si = studentSkills(:,i);
        sj = studentSkills(:,j);
        I = ~isnan(si + sj);        
        if sum(I) < 2
            display('Not enough skill overlap to estimate correlation');
            C(i,j) = nan;
            continue;
        end
        C(i,j) = corr(si(I),sj(I));        
    end
end
%c = corr(studentSkills);

format short 
C
end