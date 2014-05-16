function[W_mt] = loadImageTags()
    load imageLocations
    load imageSimMat
    load imageTagsFile
    load locationSimMat
    load tagSimMat
    
    [m1,~]=size(imageSimMat);
    [~,n3]=size(tagSimMat);
    
    W_mt = zeros(m1,n3);
    for i=1:size(ImageTagsFile)
        imageID = ImageTagsFile(i,1);
        tagID = ImageTagsFile(i,2);
        W_mt(imageID,tagID) = 1;
    end
end