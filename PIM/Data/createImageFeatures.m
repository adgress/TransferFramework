function [] = createImageFeatures()
    runLaptap = 1;
    if runLaptap
        inputDir = 'C:\Users\Aubrey\Desktop\matlab\imageVectorFiles\';
        outputDir = 'C:\Users\Aubrey\Google Drive\Research\TransferFramework\PIM\Data\featureData\';
        allKeypoints = zeros(100000,128);
        numToUse = 10;
        numClusters = 10;
    else
        inputDir = '/home/adgress/PIM/imageVectorFiles/';
        outputDir = 'PIM/Data/featureData/';
        allKeypoints = zeros(1000000,128);
        numToUse = -1;
        numClusters = 1000;
    end
    allFiles = dir(inputDir);
    if ~runLaptap
        numToUse = length(allFiles);
    end
    
    
    keypointToImages = zeros(size(allKeypoints,1),1);
    fileNames = cell(590,1);
    index = 1;
    matInd = 0;
    for i=1:numToUse
        if allFiles(i).isdir
            continue;
        end
        fileNames{index} = allFiles(i).name;
        file = [inputDir allFiles(i).name];
        
        keyPoints = load(file);        
        numVecs = size(keyPoints,1);
        allKeypoints(matInd+1:matInd+numVecs,:) = keyPoints;
        keypointToImages(matInd+1:matInd) = index;
        matInd = matInd + numVecs;
        index = index+1;
    end    
    [IDX,C] = kmeans(allKeypoints(1:matInd,:),numClusters);
    featResults = struct();
    featResults.featIndices = IDX;
    featResults.C = C;
    featResults.fileNames = fileNames;
    featResults.keyPointToImage = keypointToImages;
    fileName = sprintf('featResults%d-%d.mat',numToUse,numClusters);
    save([outputDir fileName],'featResults');
end
