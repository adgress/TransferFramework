function [] = createPIMData()
    [Xl] = loadLocationsFile();
    [Wmt] = loadImageTags();
    [Wml] = loadImageLocations();
    [Xm] = load('imageSimMat.mat');
    Xm = Xm.imageSimMat;
        
    numTagsToKeep = 30;
    [tagsKept,imagesKept,locationsKept] = keepTopNTags(Wmt,Wml,numTagsToKeep);
    
    Xm = Xm(imagesKept,:);
    Xl = Xl(locationsKept,:);
    Wmt = Wmt(imagesKept,tagsKept);
    Wml = Wml(imagesKept,locationsKept);
    
    Xl = Kernel.Distance(Xl);
    sigma = mean(Xl(:));
    Xl = Helpers.distance2RBF(Xl,sigma);
    
    nImages = size(Wmt,1);
    nTags = size(Wmt,2);
    nLocs = size(Xl,1);
    
    Xt = eye(nTags);        
    Wtl = zeros(nTags,nLocs);
    for i=1:nLocs
        imagesWithLocation = Wml(:,i) > 0;
        for j=1:nTags
            imagesWithTag = Wmt(:,j) > 0;            
            Wtl(j,i) = sum(imagesWithTag & imagesWithLocation)/...
                sum(imagesWithTag | imagesWithLocation);
        end
    end 
    Wmm = eye(nImages);
    Wtt = eye(nTags);
    Wll = eye(nLocs);
    W = [Wmm Wmt Wml ;...
        Wmt' Wtt Wtl ;...
        Wml' Wtl' Wll];
    X = {Xm,Xt,Xl};
    data = struct();
    data.data = SimilarityDataSet(X,W);
    data.metadata = struct();
    data.metadata.tagsKept = tagsKept;
    data.metadata.locationsKept = locationsKept;
    data.metadata.imagesKept = imagesKept;
    data.metadata.locSigma = sigma;
    f = 'Data/pimData/pimData.mat';
    f = Helpers.MakeProjectURL(f);
    save(f,'data');
    %{
    [split] = data.splitDataAtInd(.6,.2,1);
    X = data.getBlockX();
    [splitData] = data.createDataSetsWithSplit(split,1);
    %}
end