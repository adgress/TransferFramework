function [] = makeStudentData()
    fileName = 'Data/ITS/DS1-69';
    data = load(fileName);
    data = data.data;
    
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
    correlationW = zeros(numStudents);
    for i=1:numStudents
        for j=1:numStudents
            if i == j
                correlationW(i,j) = 1;
                continue;
            end
            si = W(:,i);
            sj = W(:,j);
            correlationW(i,j) = norm(si-sj)/(norm(si)*norm(sj));
        end
    end
    correlationW = abs(correlationW);
    data = struct();
    data.Y = Y + 1;
    data.W = {correlationW};
    data.WIDs = {(1:numStudents)'};
    fileName = [fileName '-student.mat'];
    save(fileName,'data');
end