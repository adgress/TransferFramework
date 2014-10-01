function [] = deleteResults(fileName,dataSet)
    if nargin < 2
        dataSet = Constants.CV_DATA;
    end
    s = getProjectConstants();
    projectDir = s.projectDir;
    resultsDir = [projectDir '/results'];
    if dataSet == Constants.CV_DATA
        resultsDir = [resultsDir '/CV'];
    else
        error('unknown dataset');
    end
    resultDirectories = ls(resultsDir);
    numDeleted = 0;
    for i=1:length(resultDirectories)
        d = resultDirectories(i,:);
        if isequal(d,'.  ') || isequal(d,'.. ')
            continue;
        end
        currFile = [resultsDir '/' d '/' fileName];
        
        if exist(currFile,'file')
            delete(currFile);
            numDeleted = numDeleted+1;
        end
    end
    display(sprintf('Deleted %d files',numDeleted));
end

