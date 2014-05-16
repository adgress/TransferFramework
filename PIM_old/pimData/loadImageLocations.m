function[W_ml] = loadImageLocations()
    load imageLocations
    load imageSimMat
    load locationSimMat
    
    [m1,~]=size(imageSimMat);
    [m2,~]=size(locationSimMat);
    
    W_ml = zeros(m1,m2);
    for i=1:size(ImageLocations)
        imageID = ImageLocations(i,1);
        locID = ImageLocations(i,2);
        W_ml(imageID,locID) = 1;
    end    
end