function [  ] = loadData()
%LOADDATA Summary of this function goes here
%   Detailed explanation goes here

useDS1 = 1;

studentName = 4;
studResType = 9;
studResSubtype = 10;
tutResType = 11;
tutResSubtype = 12;
levelDomainType = 13;
levelNumber = 14;
problemName = 15;
stepName = 18;
isLastAttempt = 20;
outcome = 21;
kcStart = 31;

baseSize = 300000;
fileData = struct();
fileData.studentNames = cell(baseSize,1);
fileData.problemNames = cell(baseSize,1);
fileData.stepNames = cell(baseSize,1);
fileData.studResTypes = cell(baseSize,1);
fileData.studResSubtypes = cell(baseSize,1);
fileData.outcomes = cell(baseSize,1);
fileData.kcArrays = cell(baseSize,1);
fileData.kcs = cell(baseSize,1);
fileData.kcCats = cell(baseSize,1);

studResTypeValues = {'ATTEMPT', 'HINT_REQUEST'};
tutResTypeValues = {'RESULT','HINT_MSG'};
if useDS1
    dataSetName = 'DS1';       
    kcLast = 100;    
    %LFA_AIC_Model0_v2 (21 KCs)
    %kcDefault = 85;
    
    %LFASearchModel0 (7 KCs)
    kcDefault = 69;
else
    dataSetName = 'DS2';
    kcLast = 48;
    %Default
    kcDefault = 31;
end
fileName = ['ITS/' dataSetName '.txt'];
%{
for idx=kcStart:2:kcLast
    kcArrays{end+1} = {};
end
%}
file = fopen(fileName,'r+');

numLines = 0;
while true
    s = fgetl(file);
    if ~ischar(s)
        break;
    end
    numLines = numLines + 1;
    a = StringHelpers.split_string(s,'\t',false);
    numTabs = 0;
    for idx=1:length(s)
        if isequal(s(idx),9)
            numTabs = numTabs + 1;
        end
    end
    for idx=1:length(a)
        %display([num2str(idx) ' ' a{idx}]);        
    end
    if numLines > 1
        i = numLines - 1;
        fileData.studentNames{i} = a{studentName};
        fileData.problemNames{i} = a{problemName};
        fileData.stepNames{i} = a{stepName};
        fileData.studResTypes{i} = a{studResType};
        fileData.studResSubtypes{i} = a{studResSubtype};
        fileData.outcomes{i} = a{outcome};
        fileData.kcs{i} = a{kcDefault};
        fileData.kcCats{i} = a{kcDefault+1};
        %{
        t = 1;
        for idx=kcStart:2:kcLast
            kcArrays{t}{end+1} = a{idx};
            t = t+1;
        end
        %}
    end    
end

numEntries = numLines - 1;
fileData = truncateFields(fileData,numEntries);

ordData = struct();
uniqueOrdData = struct();
[uniqueOrdData.uniqueStepNames,ordData.stepOrd] = makeNominal(fileData.stepNames);
[uniqueOrdData.uniqueStudentNames,ordData.studentOrd] = makeNominal(fileData.studentNames);
[uniqueOrdData.uniqueStudResType,ordData.studentResOrd] = makeNominal(fileData.studResTypes);
%[uniqueStudResSubtype,studentResSubOrd] = makeOrdinal(studResSubtypes);
[uniqueOrdData.uniqueOutcome,ordData.outcomeOrd] = makeNominal(fileData.outcomes);
[uniqueOrdData.uniqueKC,ordData.kcOrd] = makeNominal(fileData.kcs);
[uniqueOrdData.uniqueKCCat,ordData.kcCatOrd] = makeNominal(fileData.kcCats);

while true
    [uniqueOrdData,ordData,numRemoved] = pruneData(uniqueOrdData,ordData);
    if numRemoved == 0
        break;
    end
end
isAttempt = ordData.studentResOrd == 'ATTEMPT';
isCorrect = ordData.outcomeOrd == 'CORRECT';
isIncorrect = ordData.outcomeOrd == 'INCORRECT';

studentIDs = double(ordData.studentOrd);
stepIDs = double(ordData.stepOrd);
labelIDs = double(ordData.kcOrd);

numStudents = length(uniqueOrdData.uniqueStudentNames);
numSteps = length(uniqueOrdData.uniqueStepNames);
W = zeros(numStudents,numSteps);
WCorrect = W;
WIncorrect = W;
for studIdx=1:numStudents
    for stepIdx=1:numSteps
        isStudent = studentIDs == studIdx;
        isStep = stepIDs == stepIdx;
        I = isStudent & isStep;
        numCorrect = sum(isCorrect(I));
        numIncorrect = sum(isIncorrect(I));
        WCorrect(studIdx,stepIdx) = numCorrect;
        WIncorrect(studIdx,stepIdx) = numIncorrect;
    end
end
W = WCorrect + WIncorrect;

data = struct();
data.WCorrect = WCorrect;
data.WInCorrect = WIncorrect;
data.studentOrd = ordData.studentOrd;
data.stepOrd = ordData.stepOrd;
data.kcOrd = ordData.kcOrd;
data.kcCatOrd = ordData.kcCatOrd;
data.outcomeOrd = ordData.outcomeOrd;
data.studentResOrd = ordData.studentResOrd;

Wmastered = WCorrect ./ (WCorrect-WIncorrect);
WnotMastered = 1 - Wmastered;

Wmastered = Helpers.replaceNanInf(Wmastered);
WnotMastered = Helpers.replaceNanInf(WnotMastered);
Wmastered(isnan(Wmastered)) = 0;
WnotMastered(isnan(WnotMastered)) = 0;

numKC = length(uniqueOrdData.uniqueKC);
stepY = zeros(numSteps,1);
kcDouble = double(ordData.kcOrd);

for stepIdx=1:numSteps
    isStep = stepIDs == stepIdx;
    Y = kcDouble(isStep & isAttempt);
    
    %assert(length(unique(Y)) == 1);
    if isempty(unique(Y))
        display('Step with zero students');
    end
    stepY(stepIdx) = Y(1);    
end

WIDs = {[1:numStudents]',[1:numSteps]'};
%W = [Wmastered WnotMastered];
data.W = {Wmastered, WnotMastered};
data.Y = stepY;
data.WIDs = WIDs;
a = getlabels(ordData.studentOrd)';
b = getlabels(ordData.stepOrd)';
data.WNames = {a,b};
data.YNames = [getlabels(ordData.kcOrd)' ; getlabels(ordData.kcOrd)'];
save(['Data/ITS/' dataSetName '.mat'], 'data');
end

function [keys,vals] = makeNominal(v)
if isa(v{1},'double')
    v = cell2mat(v);
    keys = unique(v);
    vals = v;
    return
end    
isEmpty = cellfun(@length,v) == 0;
v(isEmpty) = {'(blank)'};    
vals = nominal(v,unique(v));
keys = unique(vals);
end

function [s] = truncateFields(s,n)
f = fields(s);
for idx=1:length(f)
    ff = f{idx};
    s.(ff) = s.(ff)(1:n);
end
end

function [uniqueOrdData,ordData,numRemoved] = pruneData(uniqueOrdData,ordData)
stepNamesToRemove = false(size(uniqueOrdData.uniqueStepNames));
isAttempt = ordData.studentResOrd == 'ATTEMPT';
transactionsToRemove = ~isAttempt;
kcsToRemove = false(size(uniqueOrdData.uniqueKC));
for kcIdx=1:length(uniqueOrdData.uniqueKC)
    numStepsWithKC = 0;
    cumI = false(size(transactionsToRemove));
    for stepIdx=1:length(uniqueOrdData.uniqueStepNames)
        I = uniqueOrdData.uniqueKC(kcIdx) == ordData.kcOrd & ...
            uniqueOrdData.uniqueStepNames(stepIdx) == ordData.stepOrd & ...
            ~transactionsToRemove;
        numStepsWithKC = numStepsWithKC + (sum(I) > 0);        
        cumI = cumI | I;
    end
    %numStepsWithKC
    %uniqueKC(kcIdx)
    if numStepsWithKC < 3
        kcsToRemove(kcIdx) = true;
        transactionsToRemove(cumI) = true;
    end
end
for stepIdx=1:length(uniqueOrdData.uniqueStepNames)
    numStudentsAsked = 0;
    cumI = false(size(transactionsToRemove));
    for studIdx=1:length(uniqueOrdData.uniqueStudentNames)
        I = uniqueOrdData.uniqueStepNames(stepIdx) == ordData.stepOrd & ...
            uniqueOrdData.uniqueStudentNames(studIdx) == ordData.studentOrd & ...
            ~transactionsToRemove;      
        cumI = cumI | I;
        numStudentsAsked = numStudentsAsked + (sum(I) > 0);
    end
    if numStudentsAsked < 10
        stepNamesToRemove(stepIdx) = true;
        transactionsToRemove(cumI) = true;
    end
end

remove = @(v) v(~transactionsToRemove,:);
ordData = Helpers.mapField(ordData,remove);

uniqueOrdData.uniqueStepNames(stepNamesToRemove) = [];
uniqueOrdData.uniqueKC(kcsToRemove) = [];

ordData = Helpers.mapField(ordData, @droplevels);
uniqueOrdData = Helpers.mapField(uniqueOrdData, @droplevels);

%{

ordData.stepOrd(transactionsToRemove) = [];
ordData.studentResOrd(transactionsToRemove) = [];
ordData.studentOrd(transactionsToRemove) = [];
ordData.outcomeOrd(transactionsToRemove) = [];
ordData.kcOrd(transactionsToRemove) = [];
ordData.kcCatOrd(transactionsToRemove) = [];


ordData.kcOrd = droplevels(ordData.kcOrd);


ordData.stepOrd = droplevels(stepOrd);
%}
numRemoved = sum(transactionsToRemove);
end
