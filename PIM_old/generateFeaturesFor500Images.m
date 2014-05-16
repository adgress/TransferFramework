fid=fopen('IDvsImage.map');

imageFolder = 'images/';
featureFolder = 'features/';
imageData = struct();
m = 500;
imageData.data = zeros(1000,m);
imageData.imageSize = 0;
for i=1:m
    imageName = num2str (i);
    imagePath = [folder imageName '.pgm'];    
    A=imread(imagePath, 'pgm');
    featureFileName = num2str (i);
    getfeat_single_image(imagePath,featureFileName,featureFolder,true);
end