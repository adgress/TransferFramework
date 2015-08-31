function [  ] = loadData()
%LOADDATA Summary of this function goes here
%   Detailed explanation goes here
pc = ProjectConfigs.Create();
dataSet = pc.dataSet;
normalize = 1;


studentName = 4;
studResType = 9;
problemName = 15;
stepName = 18;
outcome = 21;

realY = true;

fileData = struct();

studResTypeValues = {'ATTEMPT', 'HINT_REQUEST'};
tutResTypeValues = {'RESULT','HINT_MSG'};
splitChar = sprintf('\t');
switch dataSet
    case Constants.DS1
        dataSetName = 'DS1';
        kcLast = 100;
        %LFA_AIC_Model0_v2 (21 KCs)
        %kcDefault = 85;
        
        %LFASearchModel0 (7 KCs)
        kcDefault = 69;
    case Constants.DS2
        dataSetName = 'DS2';
        kcLast = 48;
        
        %Default
        %kcDefault = 31;
        
        %Reduce Step Name
        kcDefault = 35;
    case Constants.DS3
        dataSetName = 'DS3';
        
        problemName = 14;
        stepName = 17;
        outcome = 19;
        
        %MCAS39-State_WPI-Simple
        kcDefault = 39;
    case Constants.PRG
        dataSetName = 'Prgusap1';
        splitChar = sprintf(',');
        kcDefault = [];
        %966
        
        %A3
        litPrefixes = {'C3','D3','E3','M3','N3','P3'};
        %A6
        numPrefixes = {'D6','E6','M6','P6'};
        %UX
        pronPrefixes = {'U0','U1','U2'};
        %P9
        readPrefixes = {'P9'};
        
        allPrefixes = {litPrefixes,numPrefixes,pronPrefixes,readPrefixes};
        prefixIndices = {};
        allIndices = [];
end
columnsToUse = [studentName studResType problemName stepName ...
    outcome kcDefault];
fileName = ['ITS/' dataSetName '.txt'];
if dataSet == Constants.PRG
   fileName = ['ITS/' dataSetName '.csv']; 
end
dataSetName = [dataSetName '-' num2str(kcDefault) '_reg'];
if ~normalize
    dataSetName = [dataSetName '-nonNorm'];
end
%{
for idx=kcStart:2:kcLast
    kcArrays{end+1} = {};
end
%}
file = fopen(fileName,'r+');

s = fgetl(file);
header = StringHelpers.split_string(s,splitChar,false);
if dataSet == Constants.PRG
    allIndices = false(size(header));
    for skillIdx=1:length(allPrefixes)
        currPrefixes = allPrefixes{skillIdx};
        I = false(size(header));
        for prefIdx=1:length(currPrefixes)
            I = I | (hasPrefix(currPrefixes{prefIdx},header) & ...
                hasSuffix('S',header));
        end        
        prefixIndices{end+1} = I;
        allIndices = allIndices | I;
    end
end
format = '';
for idx=1:length(header)
    display([num2str(idx) ': ' header{idx}]);
    if idx == 1
        format = '%s';
        continue;
    end
    if dataSet == Constants.PRG
        %format = [format splitChar];
        if sum(idx == columnsToUse)
            format = [format '%s'];
        else
            %format = [format '%*s'];
            format = [format '%s'];
        end
    else
        %format = [format splitChar];
        display('Not adding \%c - is this okay?');
        %format = [format '%c'];   
        if sum(idx == columnsToUse)
            format = [format ' %s'];
        else
            %format = [format '%*s'];
            format = [format '%s'];
        end
    end
    
end

printData = 0;
if printData
    for k=1:100
        s2 = fgetl(file);
        a2 = StringHelpers.split_string(s2,splitChar,false);
        for idx=1:length(header)
            display([num2str(idx) ': ' header{idx} ', ' a2{idx}]);
        end
    end
end
%file2 = fopen(fileName,'r+');
numLines = 1000;
ordData = struct();
ordData.stepOrd = [];
ordData.studentOrd = [];
ordData.studentResOrd = [];
ordData.outcomeOrd = [];
ordData.kcOrd = [];
ordData.kcCatOrd = [];

uniqueOrdData = struct();
uniqueOrdData.uniqueStepNames = [];
uniqueOrdData.uniqueStudentNames = [];
uniqueOrdData.uniqueStudResType = [];
uniqueOrdData.uniqueOutcome = [];
uniqueOrdData.uniqueKC = [];
uniqueOrdData.uniqueKCCat = [];
ordData.stepOrd = [];
blockIdx = 1;
dataLoaded = false;

cachedFileName = [dataSetName '.mat'];
if exist(cachedFileName,'file')
    load(cachedFileName);
    dataLoaded = true;
end
lineIdx = 0;
while ~feof(file) && ~dataLoaded
    a = textscan(file,format,numLines,'Delimiter',splitChar);
    blockIdx = blockIdx + 1;
    numLines = length(a{1});
    isValid = @(s) strcmp(s,'1') || strcmp(s,'7');
    if dataSet == Constants.PRG 
        studentNames = [];
        stepNames = {};
        kcs = [];
        outcomes = [];
        numAdded = 0;
        for skillIdx=1:length(prefixIndices)
            thisSkillInds = find(prefixIndices{skillIdx});
            numEntries = 0;
            for qIdx=1:length(thisSkillInds)
                s = thisSkillInds(qIdx);
                answers = a{s};
                hasAnswer = ~cellfun('isempty',answers);
                answers = answers(hasAnswer);
                hasAnswer = find(hasAnswer);
                I = cellfun(isValid,answers);
                hasAnswer = hasAnswer(I);
                answers = answers(I);
                
                I1 = strcmp('1',answers);                
                I7 = strcmp('7',answers);
                assert(all(I7 | I1));
                answers(I1) = {'CORRECT'};
                answers(I7) = {'INCORRECT'};
                
                
                studentNames = [studentNames ; lineIdx + hasAnswer];
                outcomes = [outcomes ; answers];
                numAnswers = length(hasAnswer);
                stepNames = [stepNames ; repmat(header(s),numAnswers,1)];
                numEntries = numEntries + length(answers);
            end
            kcs = [kcs ; skillIdx*ones(numEntries,1)];    
            numAdded = numAdded + numEntries;
        end
        fileData.studentNames = studentNames;
        fileData.problemNames = stepNames;
        fileData.stepNames = stepNames;
        fileData.outcomes = outcomes;
        fileData.kcs = kcs;
        fileData.kcCats = [];
        fileData.studResTypes = cell(numAdded,1);
        fileData.studResTypes(:) = {'ATTEMPT'};
    else
        fileData.studentNames = a{studentName};
        fileData.problemNames = a{problemName};
        fileData.stepNames = a{stepName};
        fileData.studResTypes = a{studResType};
        fileData.outcomes = a{outcome};
        fileData.kcs = a{kcDefault};
        fileData.kcCats = a{kcDefault+1};                        
    end    
    c = struct();
    [c.uniqueKCCat,c.kcCatOrd] = makeNominal(fileData.kcCats);    
    [c.uniqueStudResType,c.studentResOrd] = makeNominal(fileData.studResTypes);
    [c.uniqueStepNames,c.stepOrd] = makeNominal(fileData.stepNames);
    [c.uniqueKC,c.kcOrd] = makeNominal(fileData.kcs);
    [c.uniqueStudentNames,c.studentOrd] = makeNominal(fileData.studentNames);
    [c.uniqueOutcome,c.outcomeOrd] = makeNominal(fileData.outcomes);
    ordData = combinedNominal(ordData,c);
    
    lineIdx = lineIdx + numLines;
end
if dataSet == Constants.PRG    
    uniqueOrdData.uniqueStudentNames = nominal(1:lineIdx);
    uniqueOrdData.uniqueStepNames = nominal(header(allIndices));
    uniqueOrdData.uniqueKC = nominal(1:4);
    uniqueOrdData.uniqueOutcome = unique(ordData.outcomeOrd);
end
fclose(file);

uniqueOrdData.uniqueStepNames = unique(ordData.stepOrd);
uniqueOrdData.uniqueStudentNames = unique(ordData.studentOrd);
uniqueOrdData.uniqueStudResType = unique(ordData.studentResOrd);
uniqueOrdData.uniqueOutcome = unique(ordData.outcomeOrd);
uniqueOrdData.uniqueKC = unique(ordData.kcOrd);
uniqueOrdData.uniqueKCCat = unique(ordData.kcCatOrd);

save(cachedFileName);

prunedFileName = [dataSetName '-pruned.mat'];
if ~exist(prunedFileName,'file');       
    while true
        [uniqueOrdData,ordData,numRemoved] = pruneData(uniqueOrdData,ordData);
        if numRemoved == 0
            break;
        end
    end
else
    load(prunedFileName);
end
isCorrect = ordData.outcomeOrd == 'CORRECT';
isIncorrect = ordData.outcomeOrd == 'INCORRECT';
isAttempt = isCorrect | isIncorrect;
%{
isAttempt = ordData.studentResOrd == 'ATTEMPT';
assert(all(isAttempt == (isCorrect | isIncorrect)));
%}
studentIDs = double(ordData.studentOrd);
stepIDs = double(ordData.stepOrd);
labelIDs = double(ordData.kcOrd);

numStudents = length(uniqueOrdData.uniqueStudentNames);
numSteps = length(uniqueOrdData.uniqueStepNames);
numLabels = length(uniqueOrdData.uniqueKC);

W = zeros(numStudents,numSteps);
WCorrect = W;
WIncorrect = W;
maxStudents = 1000;
studentSkills = zeros(numStudents,numLabels);
for studIdx=1:min(numStudents,maxStudents)
    isStudent = studentIDs == studIdx; 
    subStepIDs = stepIDs(isStudent);
    isCorrectSub = isCorrect(isStudent);
    isIncorrectSub = isIncorrect(isStudent);
    labelSub = labelIDs(isStudent);
    for stepIdx=1:numSteps
        %isStudent = studentIDs == studIdx;
        isStep = subStepIDs == stepIdx;
        %I = isStudent & isStep;
        I = isStep;
        numCorrect = sum(isCorrectSub(I));
        numIncorrect = sum(isIncorrectSub(I));
        WCorrect(studIdx,stepIdx) = numCorrect;
        WIncorrect(studIdx,stepIdx) = numIncorrect;
    end
    for labelIdx=1:numLabels
        l = double(uniqueOrdData.uniqueKC(labelIdx));
        scores = isCorrectSub(labelSub == l);
        scoresInc = isIncorrectSub(labelSub == l);
        hasScore = ~((scores + scoresInc) == 0);
        scores(~hasScore) = [];
        studentSkills(studIdx,labelIdx) = mean(scores);
    end
end

if size(studentSkills,1) > maxStudents
    studentSkills(maxStudents+1:end,:) = [];
    WCorrect = WCorrect(1:maxStudents,:);
    WIncorrect = WIncorrect(1:maxStudents,:);
end
W = WCorrect + WIncorrect;

if normalize
    Wmastered = WCorrect ./ (WCorrect+WIncorrect);
    WnotMastered = 1 - Wmastered;
else
    Wmastered = WCorrect;
    WnotMastered = WIncorrect;
end
stepY = zeros(numSteps,1);
kcDouble = double(ordData.kcOrd);

for stepIdx=1:numSteps
    isStep = stepIDs == stepIdx;
    Y = kcDouble(isStep & isAttempt);
    
    %assert(length(unique(Y)) == 1);
    if isempty(unique(Y))
        display('Step with zero students');
        stepY(stepIdx) = -1;
        continue;
    end
    stepY(stepIdx) = Y(1);    
end
BIG_NUMBER = 1000;
studentSkillW = cell(numLabels,1);
studentQuestionW = cell(numLabels,1);
for labIdx=1:numLabels
    
    Wcurr = BIG_NUMBER*ones(numStudents);    
    for i=1:min(numStudents,maxStudents)
        Wi = Wmastered(i,:);
        for j=i:min(numStudents,maxStudents)    
            Wj = Wmastered(j,:);
            bothLabeled = find(W(i,:) > 0 & W(j,:) > 0 & stepY' == labIdx);
            if isempty(bothLabeled)
                continue;
            end        
            a = Wi(bothLabeled);
            b = Wj(bothLabeled);            
            %w = 1 - dot(a,b)/(norm(a)*norm(b));
            w = norm(a-b);
            Wcurr(i,j) = w;
            Wcurr(j,i) = w; 
            if any(isnan(w))
                display('');
            end
        end
    end
    studentQuestionW{labIdx} = Wcurr;
    Wcurr = Helpers.CreateDistanceMatrix(studentSkills(:,labIdx));
    Wcurr(isnan(Wcurr)) = BIG_NUMBER;
    %assert(~any(isnan(Wcurr(:))));
    studentSkillW{labIdx} = Wcurr;    
end
data = struct();
data.studentSkills = studentSkills;
data.studentW = studentSkillW;
data.studentQuestionW = studentQuestionW;
data.WCorrect = WCorrect;
data.WInCorrect = WIncorrect;
data.studentOrd = ordData.studentOrd;
data.stepOrd = ordData.stepOrd;
data.kcOrd = ordData.kcOrd;
data.kcCatOrd = ordData.kcCatOrd;
data.outcomeOrd = ordData.outcomeOrd;
data.studentResOrd = ordData.studentResOrd;


Wmastered = Helpers.replaceNanInf(Wmastered);
WnotMastered = Helpers.replaceNanInf(WnotMastered);
Wmastered(isnan(Wmastered)) = 0;
WnotMastered(isnan(WnotMastered)) = 0;

numKC = length(uniqueOrdData.uniqueKC);


WIDs = {[1:numSteps]',[1:numStudents]'};
%W = [Wmastered WnotMastered];
data.W = {Wmastered', WnotMastered'};
data.Y = stepY;
data.WIDs = WIDs;
a = getlabels(ordData.studentOrd)';
b = getlabels(ordData.stepOrd)';
data.WNames = {b,a};
data.YNames = getlabels(ordData.kcOrd)';
data.WCorrect = data.WCorrect';
data.WInCorrect = data.WInCorrect';
save(['Data/ITS/' dataSetName '.mat'], 'data');
end

function [keys,vals] = makeNominal(v)
if isa(v,'double')    
    vals = nominal(v);
    keys = unique(v);    
    return;
elseif isa(v{1},'double')
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
%isAttempt = ordData.studentResOrd == 'ATTEMPT';

isCorrect = ordData.outcomeOrd == 'CORRECT';
isIncorrect = ordData.outcomeOrd == 'INCORRECT';
isAttempt = isCorrect | isIncorrect;

transactionsToRemove = ~isAttempt;
kcsToRemove = false(size(uniqueOrdData.uniqueKC));
for kcIdx=1:length(uniqueOrdData.uniqueKC)

    I = uniqueOrdData.uniqueKC(kcIdx) == ordData.kcOrd;
    stepsWithKC = unique(ordData.stepOrd(I));
    
    numStepsWithKC = length(stepsWithKC);
    cumI = I;

    if numStepsWithKC < 3
        kcsToRemove(kcIdx) = true;
        transactionsToRemove(cumI) = true;
    end
end
for stepIdx=1:length(uniqueOrdData.uniqueStepNames)
    I = uniqueOrdData.uniqueStepNames(stepIdx) == ordData.stepOrd & ...
        ~transactionsToRemove;
    studentsWithStep = unique(ordData.studentOrd(I));
    numStudentsAsked = length(studentsWithStep);
    cumI = I;
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

numRemoved = sum(transactionsToRemove);
end

function a = combineUnique(a,b)
f = fields(a);
for idx=1:length(f)
    a.(f{idx}) = unique([a.(f{idx}) ; b.(f{idx})]);
end
end


function a = combinedNominal(a,b)
f = fields(a);
for idx=1:length(f)
    a.(f{idx}) = [a.(f{idx}) ; b.(f{idx})];
end
end

function [I] = hasPrefix(prefix,strings)
    hasPrefix = @(s) StringHelpers.isPrefix(s,prefix);
    I = cellfun(hasPrefix,strings,'UniformOutput',true);
end

function [I] = hasSuffix(suffix,strings)
    hasSuffix = @(s) StringHelpers.isSuffix(s,suffix);
    I = cellfun(hasSuffix,strings,'UniformOutput',true);
end





