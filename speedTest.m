function [] = speedTest(numThreads)
    matlabpool close force local;
    matlabpool('local', numThreads);
    
    numMats = 24;
    numTrials = 10;
    matSize = 300;
    matrices = cell(numMats,1);
    for i=1:numMats
        matrices{i} = rand(matSize);
    end
    times = zeros(numTrials,1);
    for i=1:length(times)
        tic
        parfor j=1:length(matrices)
            eig(matrices{j});
        end
        times(i) = toc;
        display(num2str(times(i)));
    end
    display(['Time: ' num2str(mean(times)) ' +/-' num2str(std(times))]);
    display(['Best Time: ' num2str(min(times))]);
end