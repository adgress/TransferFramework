% This program partitions the graph with image information tags information
%  and locations information using QP with inequality constraints 
%  abs(vi-vj)<= alpha
%  This program does K-way partition with K>=2. 
function[trainAcc,testAcc,trainNNData,testNNData] = main(data,settings)
    close all
    
    loadConstants;
        
    trainAcc = cell(numel(settings.methodSettings),1);
    testAcc = trainAcc;
    trainNNData = trainAcc;
    testNNData = trainAcc;
    for i=1:numel(data.folds)
        train = data.folds{i};
        n = size(data.imageSimMat,2);
        trainIndices = 1:ceil(settings.percentTrain*n);
        train.imageSimMat = train.imageSimMat(trainIndices,trainIndices);
        train.imageTagsSimMat = train.imageTagsSimMat(trainIndices,:);
        train.imageLocationsSimMat = data.imageLocationsSimMat(trainIndices,:);
        train.imageTagsSimMat_original = train.imageTagsSimMat;
        
        test = data.test;
        test.imageSimMat = test.imageSimMat(:,trainIndices);
        
        %{
        imagesKept = data.imagesKept;
        wordsKept = data.wordsKept;
        Wmt_train = train.imageTagsSimMat_original;
        for j=1:size(Wmt_train,1)
            tagIndices = logical(Wmt_train(j,:));
            image = imagesKept(j);
            tags = wordsKept(tagIndices);
            image
            tags
        end
        display('done');
        %}
        for j=1:numel(settings.methodSettings)
            currMethod = settings.methodSettings{j};
            currSettings = struct();
            currSettings.reg = settings.reg;
            currSettings.kNN = settings.kNN;
            currSettings.locationCannotLink = settings.locationCannotLink;
            currSettings.normalizeKernels = settings.normalizeKernels;
            currSettings.whitenData = settings.whitenData;
            currSettings.method = currMethod.method;
            currSettings.includeLocations = currMethod.includeLocations;
            currSettings.constraintMatrix = currMethod.constraintMatrix;
            currSettings.locationConstraints = currMethod.locationConstraints;
            currSettings.centerData = currMethod.centerData;
            currSettings.normalizeVectors = currMethod.normalizeVectors;
            currSettings.justLocations = settings.justLocations;
            if isfield(settings,'constraintPercentage')
                currSettings.constraintPercentage = settings.constraintPercentage;
            end
            currSettings.data = data;
            [V,trainAcc{j}(:,i),testAcc{j}(:,i),...
                trainNNData{j}(:,i),testNNData{j}(:,i)] = ...
                embedSKCAA(train,test,settings.numVectors,currSettings);                       
            
            if currMethod.clustering                
                
                clustering = struct();
                
                clustering.data = data;                           
                clustering.images = V.projectedImages;
                clustering.tags = V.projectedTags;
                clustering.locations = V.projectedLocations;
                clustering.imageTagsSimMat_original = V.imageTagsSimMat_original;
                clustering.method = V.method;
                save clustering;
            end
            if currMethod.hierarchicalClustering                
                hierClustering = struct();
                hierClustering.images = V.projectedImages;
                hierClustering.tags = V.projectedTags;
                hierClustering.locations = V.projectedLocations;
                hierClustering.data = data;
                save hierClustering;
            end
            
            
        end
        %{
        if visualize
            embeddedImages = V1(1:numTrain,:);
            embeddedWords = V1(numTrain+1:end,:);
            subplot(1,2,1)
            visualizeEmbedding(embeddedImages,embeddedWords);
            
            embeddedImages = V2(1:numTrain,:);
            embeddedWords = V2(numTrain+1:end,:);
            subplot(1,2,2)
            visualizeEmbedding(embeddedImages,embeddedWords); 
            
        end
        %}
    end
    for i=1:numel(trainAcc)
        [mean(trainAcc{i},2) mean(testAcc{i},2)];
        %[var(trainAcc{i}')' var(testAcc{i}')']
    end
end

function [] = visualizeEmbedding(images,words)
%{
    i = 0;
    scatter3(images(:,i+1),images(:,i+2),images(:,i+3),10,'r');
    hold on;
    scatter3(words(:,i+1),words(:,i+2),words(:,i+3),50,'b');
    hold off
%}
        %clear all;
        
        scatter(images(:,1),images(:,2),10,'r');
        hold on;
        scatter(words(:,1),words(:,2),50,'b');
        hold off;
%{
    if size(images,2) ==1
        plot(1:length(images),images,'r+', ...
        1:length(words),words,'b.');
        return;
    end
    if size(images,2) > 2
        [coeff,score,latent] = princomp([images;words]);
        images = score(1:size(images,1),:);
        words = score(size(images,1)+1:end,:);
    end
    scatter3(images(:,1),images(:,2),images(:,3),10,'r+');
    hold on;
    scatter3(words(:,1),words(:,2),words(:,3),50,'b.');
    hold off;
    display(sprintf('Percentage of Variance:%2.2f',sum(latent(1:3))/sum(latent)));
%}
    legend('Image','Tag');
    title('Projected Images and Tags');  
end

function [projectedImages,projectedTags,projectedLocations] = ...
    embedData(imageVecs,tagVecs,locVecs,imageSimMat,tagSamples,locSimMat,numVectors)
    if numVectors > size(imageVecs,2)
        display(sprintf('embedData Warning: only using %d of %d vectors',size(imageVecs,2),numVectors));
        numVectors = min(size(imageVecs,2),numVectors);
    end
    projectedImages = imageSimMat*imageVecs(:,1:numVectors);
    projectedTags = tagSamples*tagVecs(:,1:numVectors);    
    projectedLocations = [];
    if ~isempty(locVecs)
        numVectors = min(size(locVecs,2),numVectors);
        projectedLocations = locSimMat*locVecs(:,1:numVectors);
    end
end

function [V,trainAcc,testAcc,trainNNData,testNNData] = embedSKCAA(trainData,testData,numVectors,options)
    loadConstants;

    Km_train = trainData.imageSimMat;
    Kt_train = trainData.tagSimMat;
    Kl_train = trainData.locationSimMat;      
    
    Wmt_train = trainData.imageTagsSimMat;
    Wml_train = trainData.imageLocationsSimMat;
    Wtl_train = trainData.tagsLocationSimMat;
    Wll_train = trainData.Wll_train;
    
    %Do we want this?
    if options.method ~= SPECTRAL_EMBEDDING && options.method ~= KCCA_EMBEDDING && false
        Km_train = Km_train - eye(size(Km_train));
        Kl_train = Kl_train - eye(size(Kl_train));
        Kt_train = Kt_train - eye(size(Kt_train));
    end

    %Do we want this?
    Km_test = testData.imageSimMat;
    if options.normalizeKernels
        wScale = sum(Wmt_train(:));
        %Wml_train = wScale*Wml_train/sum(Wml_train(:));
        %Wmt_train = (kernelScale*Wmt_train/sum(Wmt_train(:)));
        %Wml_train = (kernelScale*Wml_train/sum(Wml_train(:)));
    end    
    if options.whitenData
        %Experiment with raw feature vectors?
        c1 = sqrt(inv(full(cov(Km_train)+.01*eye(size(Km_train)))));
        c2 = sqrt(inv(full(cov(Kt_train)+.01*eye(size(Kt_train)))));
        c3 = sqrt(inv(full(cov(Kl_train)+.01*eye(size(Kl_train)))));
        Km_train = Km_train*c1;
        Kt_train = Kt_train*c2;
        Kl_train = Kl_train*c3;
        Km_test = Km_test*c1;
    end
    
    if options.method == SPECTRAL_EMBEDDING
        %{
        if image_locations
            Lhuge=[1*Km 1*Wml; ...
                   1*Wml' Kl];
        else
            Lhuge=[Km 1*Wmt; ...
               1*Wmt' Kt];
        end
        % Need to renormalize it. Use the RW Laplacian
        LhugeTrans = diag(sum(Lhuge))^-1*Lhuge;
        Lhuge = eye(size(LhugeTrans))-LhugeTrans;

        figure;
        [v,d]=eig(Lhuge);
        scatter3(v(1:500,2),v(1:500,3),v(1:500,4),10,'r');
        hold on;
        scatter3(v(501:end,2),v(501:end,3),v(501:end,4),50,'b');
        if image_locations
            title('Images and Locations');
        else
            title('Images and Tags');
        end
        hold off;

        V = v(:,2:10);
        if image_locations
            acc = measureNNAccuracy(V(1:500,:),V(501:end,:),ImageLocations);            
        else
            for i=kNN
                acc = measureMultilabelNNAccuracy(V(1:500,:),V(501:end,:),Wmt,i);
            end
        end
        %}
    elseif options.method == NEW_FORMULATION     
        embeddingData = struct();
        embeddingData.Km_train = Km_train;
        embeddingData.Kt_train = Kt_train;
        embeddingData.Kl_train = Kl_train;

        embeddingData.Wmt_train = Wmt_train;
        embeddingData.Wml_train = Wml_train;
        embeddingData.Wtl_train = Wtl_train;
        embeddingData.Wll_train = Wll_train;
        [a,b,c] = embedNewFormulation(embeddingData,options);
    elseif options.method == OLD_FORMULATION
        [a,b,c] = embedOldFormulation(Km_train,Kt_train,Kl_train,...
                        Wmt_train,Wml_train,Wtl_train);
    elseif options.method == KCCA_EMBEDDING
        [a,b,c] = embedKCCA(Kt_train,Km_train,Wmt_train,options);
    elseif options.method == GUESS
        a = zeros(size(Km_train));
        b = zeros(size(Kl_train));
        c = zeros(size(Kt_train));
    else
        assert(false);
    end    
    Wmt_test = testData.imageTagsSimMat;
    projectedLocations = [];
    if options.method == KCCA_EMBEDDING
        numVecs = min(size(a,2),numVectors);
        if numVecs < numVectors
            display(sprintf('Warning: Only using %d of %d vectors',numVecs,numVectors));
        end
        projectedImages = (Km_train-repmat(mean(Km_train),size(Km_train,1),1))*a(:,1:numVecs);
        projectedTags = (Kt_train-repmat(mean(Kt_train),size(Kt_train,1),1))*c(:,1:numVecs);
        projectedImages_test = (Km_test-repmat(mean(Km_train),size(Km_test,1),1))*a(:,1:numVecs);
        projectedLocations = [];
        %U = (X-repmat(mean(X),N,1))*A
        %V = (Y-repmat(mean(Y),N,1))*B
    else
        if options.centerData
            projectedImages = (Km_train-repmat(mean(Km_train),size(Km_train,1),1))*a(:,1:numVectors);
            projectedTags = (Kt_train-repmat(mean(Kt_train),size(Kt_train,1),1))*c(:,1:numVectors);
            projectedImages_test = (Km_test-repmat(mean(Km_train),size(Km_test,1),1))*a(:,1:numVectors);
            if options.includeLocations
                projectedLocations = (Kl_train-repmat(mean(Kl_train),size(Kl_train,1),1))*b(:,1:numVectors);
            end
        else
            [projectedImages,projectedTags,projectedLocations] = ...
                embedData(a,c,b,Km_train,Kt_train,Kl_train,numVectors);
            [projectedImages_test,~,~] = ...
                embedData(a,c,b,Km_test,Kt_train,Kl_train,numVectors);
        end
    end    
    V = struct();
    V.projectedImages = projectedImages;
    V.projectedTags = projectedTags;
    V.projectedLocations = projectedLocations;
    V.imageTagsSimMat_original = trainData.imageTagsSimMat_original;
    V.method = options.method;
    trainAcc = [];
    testAcc = [];
    index = 1;
    for i=options.kNN
        [trainAcc(index),trainNNData] = measureMultilabelNNAccuracy(projectedImages,projectedTags,trainData.imageTagsSimMat_original,trainData.imageTagsSimMat_original,i,options.method);
        index = index+1;
    end
    %display('Test Error:');
    index = 1;
    for i=options.kNN
        [testAcc(index),testNNData] = measureMultilabelNNAccuracy(projectedImages_test,projectedTags,trainData.imageTagsSimMat_original,Wmt_test,i,options.method);
        index = index+1;
    end
    testAcc
    trainTagCounts = sum(trainData.imageTagsSimMat_original > 0,1);
    testTagCounts = sum(testData.imageTagsSimMat > 0,1);
    trainAcc = trainAcc';
    testAcc = testAcc';
    if options.justLocations
        V.projectedImages = [];
        V.projectedTags = [];
    end
end


