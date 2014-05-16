loadConstants();

numTags=30;
numVectors=10;
percentTrain=0.5;


options = struct();
options.method = 1;
options.measure = OVERALL_PRECISION;
options.showTrainingError = 0;

options.kNN = [3 6 9 12];
options.showGuess = true;
index = 1;
options.useSubplots = false;
if index == 1
    options.prefix = 'sizes';
    options.ymin = [.02 .08 .08 .08];
    options.ymax = [.06 .12 .12 .12];
    sizeFile = sprintf('results/size,numTags=%d,numVectors=%d.mat',numTags,numVectors);
    load(sizeFile);
    options.showGuess = true;
    [f] = visualizeExperiment(trainingSizeExperiment,options,[1 3]);
    if options.useSubplots
        fileName = [num2str(options.measure) '-size' createSettingsString(trainingSizeExperiment)];
        print(f,'-djpeg',['figures/' fileName '.jpg']);
        saveas(f,['figures/' fileName '.fig']);
    end
end
if index == 2    
    options.ymin = [.02 .02 .02];
    options.ymax = [.15 .15 .15];
    tagsFile = sprintf('results/tags,percentTrain=%1.1f,numVectors=%d.mat',percentTrain,numVectors);    
    load(tagsFile);    
    [f] = visualizeExperiment(numTagsExperiment,options,[1 3]);
    fileName = [num2str(options.measure) '-tags' createSettingsString(numTagsExperiment)];
    print(f,'-djpeg',['figures/' fileName '.jpg']);
    saveas(f,['figures/' fileName '.fig']);
end
if index == 3
    options.prefix = 'vectors';
    options.ymin = [.02 .06 .06 .06];
    options.ymax = [.10 .14 .14 .14];
    vectorsFile = sprintf('results/vectors,percentTrain=%1.1f,numTags=%d.mat',percentTrain,numTags);
    load(vectorsFile);
    [f] = visualizeExperiment(numVectorsExperiment,options,[1 2]);
    if options.useSubplots
        fileName = [num2str(options.measure) '-vectors' createSettingsString(numVectorsExperiment)];
        print(f,'-djpeg',['figures/' fileName '.jpg']);
        saveas(f,['figures/' fileName '.fig']);    
    end
end