function [val,predictedSkills,actualSkills] = evaluateITSPerf(distMat,fu,predicted)
    labelSets = distMat.labelSets;
    numLabelSets = length(unique(labelSets));
    assert(numLabelSets == max(labelSets));
    isStudent = distMat.objectType == Constants.STUDENT;
    isStepCorrect = distMat.objectType == Constants.STEP_CORRECT;
    isStepIncorrect = distMat.objectType == Constants.STEP_INCORRECT;
    isTestCorrect = distMat.isTargetTest & isStepCorrect;
    testCorrectSkills = distMat.Y(isTestCorrect);
    isTestIncorrect = distMat.isTargetTest & isStepIncorrect;
    WStudCorrect = distMat.W(isStudent,isTestCorrect);
    WStudIncorrect = distMat.W(isStudent,isTestIncorrect);
    
    
    studentInds = find(isStudent);    
    testStepInds = find(isTestCorrect);
    studentSkills = zeros(length(studentInds),numLabelSets);
    studentStepSkills = zeros(size(WStudCorrect));
    for labelIdx=1:numLabelSets
        currLabels = distMat.classes(labelSets == labelIdx);
        studentFU = fu(isStudent,currLabels);
        I = sum(studentFU,2) == 0;
        studentFU(I,:) = .5;
        studentFU = Helpers.NormalizeRows(studentFU);
        studentSkills(:,labelIdx) = studentFU(:,1);        
    end
    for stepIdx=1:length(testStepInds)
        currSkill = testCorrectSkills(stepIdx);
        studentStepSkills(:,stepIdx) = studentSkills(:,currSkill);
    end
    isLabeled = (WStudCorrect + WStudIncorrect) > 0;
    isLabeled = isLabeled(:);
    error = abs(studentStepSkills - WStudCorrect);
    %normalizedError = sum(error(:)) / numel(studentStepSkills);
    normalizedError = sum(error(isLabeled)) / sum(isLabeled);
    
    val = 1 - normalizedError;
    predictedSkills = studentStepSkills;
    actualSkills = WStudCorrect;
    diff = predictedSkills - actualSkills;
    percMore = mean(mean(diff > 0));
    meanOverestimate = mean(diff(diff > 0));
    %display(['Perc Error overestimate:' num2str(percMore*meanOverestimate/normalizedError)]);
    if percMore*meanOverestimate/normalizedError > 1
        %error('');
    end
    %predictedSkills = zeros(size(W,1),numLabelSets);
    %actualSkills = predictedSkills;   
    predictedSkills = predictedSkills(isLabeled);
    actualSkills = actualSkills(isLabeled);
end