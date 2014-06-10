function [] = createImageKernel()
    runLaptap = isequal(computer,'PCWIN');
    useDistance = 0;
    if runLaptap
        input = 'PIM/Data/featData/featResults8-10.mat';
        outputFile = 'PIM/Data/ImageLinearKernel10.mat';
        if useDistance
            outputFile = 'PIM/Data/ImageDistance10.mat';
        end
    else
        input = 'PIM/Data/featData/featResults500-1000.mat';
        outputFile = 'PIM/Data/ImageLinearKernel1000.mat';
        if useDistance
            outputFile = 'PIM/Data/ImageDistance1000.mat';
        end
    end
    featResults = load(input);   
    featResults = featResults.featResults;
    numImages = max(featResults.keyPointToImage);
    m = max(featResults.featIndices);
    imageX = zeros(numImages,m);
    ID2Image = load('IDvsImage.map');
    for i=1:numImages
        currVecs = find(featResults.keyPointToImage == i);
        vecClusters = featResults.featIndices(currVecs);
        v = zeros(1,m);
        v(vecClusters) = 1;
        display([ num2str(i) ':' num2str(sum(v)/length(v))]);
        imageID = find(ID2Image(:,2) == str2num(featResults.fileNames{i}));
        assert(~isempty(imageID));
        imageID
        imageX(imageID,:) = v/norm(v);
    end
    K = zeros(numImages);
    for i=1:numImages
        for j=1:numImages
            if useDistance
                K(i,j) = norm(imageX(i,:) - (imageX(j,:)));
            else
                K(i,j) = imageX(i,:)*(imageX(j,:)');
            end
        end
    end
    imageSimMat = K;
    save(outputFile,'imageSimMat');
end
