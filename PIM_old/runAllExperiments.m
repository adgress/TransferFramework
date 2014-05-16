function [] = runAllExperiments()
    loadConstants;
    
    %TODO: Seed with time
    %s = RandStream('mt19937ar','Seed',0)
    %RandStream.setGlobalStream(s);
    
    DEFAULT_NUM_VECTORS = 10;
    DEFAULT_TRAINING_SIZE = .5;
    DEFAULT_NUM_TAGS = 30;
    
    REGULAR_EXPERIMENT= 1;
    LOCATION_EXPERIMENT = 1;
    KCCA_EXPERIMENT = 1;    
    LOCATION_CONSTRAINT_EXPERIMENT = 0;
    GUESS_EXPERIMENT = 1;
    
    TRAINING_SIZE = 0
    TAGS = 0;
    VECTORS = 0;
    CLUSTERING = 1;
    NUM_CONSTRAINTS = 0;
    
    settings = struct();        
    settings.iterations = 40;
    settings.kNN = [1 5 10];
    settings.normalizeKernels = 0;
    settings.reg = 1;
    settings.numTest = 100;
    settings.useNUSDataSet = 0;
    settings.normalizeKernels = 0;
    settings.whitenData = 0;
    settings.locationCannotLink = 0;
    settings.justLocations = 0;
    
    settings.numTags = 20;
    settings.percentTrain = .5;
    settings.numVectors = 10; 
    
    defaultMethodSettings = struct();
    defaultMethodSettings.method = NEW_FORMULATION;
    defaultMethodSettings.clustering = 0;
    defaultMethodSettings.hierarchicalClustering = 0;
    defaultMethodSettings.includeLocations = 0; 
    defaultMethodSettings.constraintMatrix = 2;    
    defaultMethodSettings.locationConstraints = 0;
    defaultMethodSettings.centerData = 0;
    defaultMethodSettings.normalizeVectors = 1;    
    defaultMethodSettings.name = 'Ours';
    settings.methodSettings = {};
    if REGULAR_EXPERIMENT
        settings.methodSettings{end+1} = defaultMethodSettings;
    end
    if LOCATION_EXPERIMENT        
        locationExperiment = defaultMethodSettings;
        locationExperiment.includeLocations = 1;
        locationExperiment.name = 'Ours+Locations';
        settings.methodSettings{end+1} = locationExperiment;
    end
    if LOCATION_CONSTRAINT_EXPERIMENT
        locationConstraintSettings = defaultMethodSettings;
        locationConstraintSettings.locationConstraints = 1;
        locationConstraintSettings.name = 'Our+Location Constraints';
        settings.methodSettings{end+1} = locationConstraintSettings;
    end
    if KCCA_EXPERIMENT
        KCCASettings = defaultMethodSettings;
        KCCASettings.method = KCCA_EMBEDDING;
        KCCASettings.name = 'CCA';
        settings.methodSettings{end+1} = KCCASettings;
    end    
    if GUESS_EXPERIMENT
        guessSettings = defaultMethodSettings;
        guessSettings.method = GUESS;
        guessSettings.name = 'Guess';
        settings.methodSettings{end+1} = guessSettings;
    end
    
    if CLUSTERING
        clusteringMethodSettings = defaultMethodSettings;
        %clusterMethodSettings.method = KCCA_EMBEDDING;
        clusteringMethodSettings.clustering = 1;
        clusteringMethodSettings.hierarchicalClustering = 1;
        clusteringMethodSettings.includeLocations = 1;
        
        clusteringSettings = settings;
        clusteringSettings.numTest = 0;
        clusteringSettings.percentTrain = 1;
        clusteringSettings.methodSettings = {clusteringMethodSettings};
        clusteringSettings.iterations = 1;
        clusteringSettings.numTags = 30;
        clusteringSettings.numVectors = 5;
        clusteringSettings.locationCannotLink = 0;
        %clusteringSettings.justLocations = 1;
        
        data = constructData(clusteringSettings);
        data = constructDataSets(data,clusteringSettings);
        [trainAcc,testAcc,trainNNData,testNNData] = main(data,clusteringSettings);
    end                 
    
    
    if TRAINING_SIZE
        settings.numTags = DEFAULT_NUM_TAGS;
        settings.numVectors = DEFAULT_NUM_VECTORS;
        settings.percentTrain = DEFAULT_TRAINING_SIZE;
        trainingSizeExperiment = struct();
        trainingSizeExperiment.trainAcc = {};
        trainingSizeExperiment.testAcc = {};
        trainingSizeExperiment.trainNNData = {};
        trainingSizeExperiment.testNNData = {};
        trainingSizeExperiment.sizes = [];
        trainingSizeExperiment.settings = settings;
        data = constructData(settings);
        data = constructDataSets(data,settings);
        for i=.1:.02:.4            
            settings.percentTrain = i;            
            settings.percentTrain
            trainingSizeExperiment.sizes(end+1) = settings.percentTrain;
            [trainAcc,testAcc,trainNNData,testNNData] = main(data,settings);
            trainingSizeExperiment.trainAcc{end+1} = trainAcc;
            trainingSizeExperiment.testAcc{end+1} = testAcc;
            trainingSizeExperiment.trainNNData{end+1} = trainNNData;
            trainingSizeExperiment.testNNData{end+1} = testNNData;
        end
        str = createSettingsString(trainingSizeExperiment);
        save(['results/size' str '.mat'],'trainingSizeExperiment');
    end

    if TAGS
        settings.numTags = DEFAULT_NUM_TAGS;
        settings.numVectors = DEFAULT_NUM_VECTORS;
        settings.percentTrain = DEFAULT_TRAINING_SIZE;
        numTagsExperiment = struct();
        numTagsExperiment.trainAcc = {};
        numTagsExperiment.testAcc = {};
        numTagsExperiment.trainNNData = {};
        numTagsExperiment.testNNData = {};
        numTagsExperiment.numTags = [];
        numTagsExperiment.settings = settings;      
        seed = rand();
        g = RandStream.getGlobalStream();
        for i=1:7
            settings.numTags = 10*i + 10;
            s = RandStream('mt19937ar','Seed',seed);
            RandStream.setGlobalStream(s);
            data = constructData(settings);
            data = constructDataSets(data,settings);
            %settings.numVectors = ceil(settings.numTags*.3);
            numTagsExperiment.numTags(i) = settings.numTags;
            [trainAcc,testAcc,trainNNData,testNNData] = main(data,settings);
            numTagsExperiment.trainAcc{i} = trainAcc;
            numTagsExperiment.testAcc{i} = testAcc;
            numTagsExperiment.trainNNData{end+1} = trainNNData;
            numTagsExperiment.testNNData{end+1} = testNNData;
        end  
        RandStream.setGlobalStream(g);
        str = createSettingsString(numTagsExperiment);
        save(['results/tags' str '.mat'],'numTagsExperiment');
    end
    
    if VECTORS
        settings.numTags = DEFAULT_NUM_TAGS;
        settings.numVectors = DEFAULT_NUM_VECTORS;
        settings.percentTrain = DEFAULT_TRAINING_SIZE;
        numVectorsExperiment = struct();
        numVectorsExperiment.trainAcc = {};
        numVectorsExperiment.testAcc = {};
        numVectorsExperiment.trainNNData = {};
        numVectorsExperiment.testNNData = {};
        numVectorsExperiment.numVectors = [];
        numVectorsExperiment.settings = settings; 
        data = constructData(settings);
        data = constructDataSets(data,settings);
        step = 2;
        for i=1:(DEFAULT_NUM_TAGS/step-1)
            settings.numVectors = step*i;
            numVectorsExperiment.numVectors(i) = settings.numVectors;
            [trainAcc,testAcc,trainNNData,testNNData] = main(data,settings);
            numVectorsExperiment.trainAcc{i} = trainAcc;
            numVectorsExperiment.testAcc{i} = testAcc;
            numVectorsExperiment.trainNNData{end+1} = trainNNData;
            numVectorsExperiment.testNNData{end+1} = testNNData;
        end    
        str = createSettingsString(numVectorsExperiment);
        save(['results/vectors' str '.mat'],'numVectorsExperiment');
    end
    
    if NUM_CONSTRAINTS
        settings.percentTrain = .5;
        settings.numTags = 40;
        settings.numVectors = 20;
        settings.methodSettings = {defaultMethodSettings};
        numConstraintsMethod = defaultMethodSettings;
        numConstraintsMethod.useLocations = 1;                
        numConstraintsMethod.locationConstraints = 1;
        numConstraintsMethod.name = 'Our+Location Constraints';
        
        settings.methodSettings{end+1} = numConstraintsMethod;
        
        numConstraintsExperiment = struct();
        numConstraintsExperiment.trainAcc = {};
        numConstraintsExperiment.testAcc = {};
        numConstraintsExperiment.constraintPercentage = [];
        numConstraintsExperiment.settings = settings; 
        data = constructData(settings);
        data = constructDataSets(data,settings);
        for i=1:5   
            error('');
            settings.constraintPercentage = .1*i;
            numConstraintsExperiment.constraintPercentage(i) = settings.constraintPercentage;
            [trainAcc,testAcc,trainNNData,testNNData] = main(data,settings);
            numConstraintsExperiment.trainAcc{i} = trainAcc;
            numConstraintsExperiment.testAcc{i} = testAcc;
            numConstraintsExperiment.trainNNData{i} = trainNNData;
            numConstraintsExperiment.testNNData{i} = testNNData;
        end 
        save numConstraintsExperiment;
    end
end

function [data] = constructData(options)    
    
    
    if ~options.useNUSDataSet
        data = struct;
        addpath('pimData');
        load imageSimMat
        load locationSimMat
        load tagSimMat

        useNewLocKernel = 1;
        if useNewLocKernel
            [allLocs] = loadLocationsFile();
            allLocs = allLocs - repmat(mean(allLocs),size(allLocs,1),1);
            allLocs = allLocs - repmat(min(allLocs),size(allLocs,1),1);
            allLocs = allLocs ./ repmat(max(allLocs),size(allLocs,1),1);
            locationSimMat = zeros(size(locationSimMat));
            for i=1:size(allLocs,1)
                for j=1:size(allLocs,1)
                    xi = allLocs(i,:);
                    xj = allLocs(j,:);                    
                    %p = (xi*xj')^3;
                    p = exp(-5*norm(xi-xj));
                    locationSimMat(i,j) = p;
                end
            end
            display('Using new Location Kernel');
        else
            display('Using OLD location kernel');
        end
        %locationSimMat = allLocs;
        %locationSimMat = locationSimMat/min(locationSimMat(:));

        [allWords] = loadTagsFile();     
        imageLocationsSimMat = loadImageLocations();
        imageTagsSimMat = loadImageTags();
        [m2,~]=size(locationSimMat);
        [m3,~]=size(tagSimMat);    

        tagsLocationSimMat = zeros(m3,m2);
        Wll_train = zeros(size(locationSimMat,1));
        cannotLink = [23 35; 35 47; 56 73];
        for i=1:size(cannotLink,1)
            l1 = cannotLink(i,1);
            l2 = cannotLink(i,2);
            Wll_train(l1,l2) = -1;
            Wll_train(l2,l1) = -1;
        end
        
        [wordsKeptIndices,imagesKeptIndicies,locationsKeptIndices] = ...
            keepTopNTags(imageTagsSimMat,imageLocationsSimMat,options.numTags);
        keepAllLocs = 0;
        if keepAllLocs
            display('Keeping all Locations');
            locationsKeptIndices = 1:99;
        else
            display('Discarding some locations');
        end
        imageTagsSimMat = imageTagsSimMat(imagesKeptIndicies,wordsKeptIndices);    
        tagSimMat = tagSimMat(wordsKeptIndices,wordsKeptIndices);           
        imageSimMat = imageSimMat(imagesKeptIndicies,imagesKeptIndicies);
        imageLocationsSimMat = imageLocationsSimMat(imagesKeptIndicies,locationsKeptIndices);
        if size(locationSimMat,1) == size(locationSimMat,2)
            locationSimMat = locationSimMat(locationsKeptIndices,locationsKeptIndices);
        else
            locationSimMat = locationSimMat(locationsKeptIndices,:);
        end
        tagsLocationSimMat = tagsLocationSimMat(wordsKeptIndices,locationsKeptIndices);
        data.wordsKept = allWords{2}(wordsKeptIndices);
        data.locationsKept = locationsKeptIndices;
        data.imagesKept = imagesKeptIndicies;
        
        data.imageSimMat = imageSimMat;
        data.tagSimMat = tagSimMat;
        data.locationSimMat = locationSimMat;
        data.imageLocationsSimMat = imageLocationsSimMat;
        data.tagsLocationSimMat = tagsLocationSimMat;
        data.imageTagsSimMat = imageTagsSimMat;
        
        data.Wll_train = Wll_train(locationsKeptIndices,locationsKeptIndices);
        %visualizeLocations(locationsKeptIndices);       
    else
        addpath('C:\Users\Aubrey\Desktop\nus_release (Gong)');
        data = struct();
        [allMatFileObj, labelMatFileObj,tagMatFileObj] = loadNUSData();        
    end
end

function [data] = constructDataSets(data,settings)
    numTest = settings.numTest;
    numImages = size(data.imageSimMat,1);
    [~,indices] = sort(rand(numImages,1));    
	trainIndices = indices(1:numImages-numTest);
    testIndices = indices(numImages-numTest+1:end);
        
    test = struct();
    test.imageSimMat = data.imageSimMat(testIndices,trainIndices);
    test.tagSimMat = data.tagSimMat;
    test.locationSimMat = data.locationSimMat;
    test.imageTagsSimMat = data.imageTagsSimMat(testIndices,:);
    test.imageLocationsSimMat = data.imageLocationsSimMat(testIndices,:);
    test.tagsLocationSimMat = data.tagsLocationSimMat;
    test.imageTagsSimMat_original = test.imageTagsSimMat;
    data.test = test;
    data.folds = {};
    for i=1:settings.iterations                
        train = struct();
        display('TODO: Fix this!');
        sorting = 1;
        if sorting
            display('Sorting - just for visualizing embedding');
            trainIndices = sort(trainIndices(randperm(numel(trainIndices))),'ascend');
        else
            display('Not Sorting - just for classification');
            trainIndices = trainIndices(randperm(numel(trainIndices)));
        end
        train.imageSimMat = data.imageSimMat(trainIndices,trainIndices);
        train.tagSimMat = data.tagSimMat;
        train.locationSimMat = data.locationSimMat;
        train.imageTagsSimMat = data.imageTagsSimMat(trainIndices,:);
        train.imageLocationsSimMat = data.imageLocationsSimMat(trainIndices,:);
        train.tagsLocationSimMat = data.tagsLocationSimMat;
        train.imageTagsSimMat_original = train.imageTagsSimMat;
        train.Wll_train = data.Wll_train;
        data.folds{i} = train;
        
        imagesKept = data.imagesKept;
        wordsKept = data.wordsKept;
    end
    
end
