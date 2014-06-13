function [] = deleteTransferRepairResults()   
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
    for i=1:length(resultDirectories)
        d = resultDirectories(i,:);
        if isequal(d,'.  ') || isequal(d,'.. ')
            continue;
        end
        toRemove = [resultsDir '/' d '/REP/'];
        success = rmdir(toRemove,'s');
    end
end

