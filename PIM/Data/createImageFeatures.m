function [] = createImageFeatures()
    runLaptap = 0;
    if runLaptap
        inputDir = 'C:\Users\Aubrey\Desktop\matlab\imageVectorFiles\';
        outputDir = 'C:\Users\Aubrey\Google Drive\Research\TransferFramework\PIM\Data\featData\';
        allKeypoints = zeros(100000,128);
        numToUse = 10;
        numClusters = 10;
    else
        inputDir = '/home/adgress/PIM/imageVectorFiles/';
        outputDir = 'PIM/Data/featData/';
        allKeypoints = zeros(1000000,128);
        numToUse = -1;
        numClusters = 1000;
    end
    allFiles = dir(inputDir);
    if ~runLaptap
        numToUse = length(allFiles);
    end
    
    savedDataFile = [outputDir 'generatedData' num2str(numToUse) '.mat'];
    if exist(savedDataFile)
        load(savedDataFile);
    else
        keypointToImages = zeros(size(allKeypoints,1),1);
        fileNames = cell(500,1);
        index = 1;
        matInd = 0;
        for i=1:numToUse
            if allFiles(i).isdir
                continue;
            end
            index
            fileNames{index} = allFiles(i).name;
            file = [inputDir allFiles(i).name];

            keyPoints = load(file);        
            numVecs = size(keyPoints,1);
            allKeypoints(matInd+1:matInd+numVecs,:) = keyPoints;
            keypointToImages(matInd+1:matInd) = index;
            matInd = matInd + numVecs;
            index = index+1;
        end
        save(savedDataFile);
    end
    options = struct();
    options.Display = 'iter';
    %options.UseParallel = 1;
    [IDX,C] = kmeans(allKeypoints(1:matInd,:),numClusters,'distance','cosine','options',options);
    featResults = struct();
    featResults.featIndices = IDX;
    featResults.C = C;
    featResults.fileNames = fileNames;
    featResults.keyPointToImage = keypointToImages(1:matInd);
    fileName = ['featResults' num2str(index-1) '-' num2str(numClusters) '.mat'];
    save([outputDir fileName],'featResults');
end
