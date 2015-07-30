function [] = makeStudentData()
    fileName = 'Data/ITS/DS1-69';
    data = load(fileName);
    data = data.data;
    labelToUse = 1;
    W = data.W{1};
    numStudents = size(W,2);
    labels = unique(data.Y);
    numLabels = length(labels);
    Y = zeros(numStudents,numLabels);
    for yIdx=1:numLabels
        y = labels(yIdx);
        I = data.Y == y;
        studentSkills = mean(W(I,:));
        m = median(studentSkills);
        binaryY = studentSkills';
        binaryY(binaryY < m) = 0;
        binaryY(binaryY >= m) = 1;
        Y(:,yIdx) = binaryY;
    end
    distW = zeros(numStudents);
    usesSkill = data.Y == labelToUse;
    usesSkill(:) = 1;
    for i=1:numStudents
        for j=1:numStudents
            if i == j
                distW(i,j) = 0;
                continue;
            end
            si = W(usesSkill,i);
            sj = W(usesSkill,j);
            %distW(i,j) = norm(si-sj)/(norm(si)*norm(sj));
            distW(i,j) = norm(si-sj);
        end
    end
    distW(isinf(distW)) = 0;
    distW(isnan(distW)) = 0;
    distW = abs(distW);
    data = struct();
    data.Y = Y + 1;
    data.Y = data.Y(:,labelToUse);
    data.W = {distW};
    data.WIDs = {(1:numStudents)'};
    data.Wdim = [];
    fileName = [fileName '-student.mat'];
    save(fileName,'data');
end