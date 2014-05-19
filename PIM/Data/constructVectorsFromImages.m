javaaddpath('MyJavaCodes.jar'); 
import HelperPackage.*;

inputDir='../data/images'; %input
IDvsImageFile = '../data/IDvsImage.map'; %input. 
outputDir='../data/imageVectorFiles'; %output

Helper.delDir(outputDir);
pause(1);
mkdir(outputDir);
pause(1);

addpath('siftDemoV4');

totalLines=countnonemptyLines(IDvsImageFile);
[tempTagIDs, imageNames] = textread(IDvsImageFile,'%s\t%[^\n]', totalLines);
imageNamesWithoutExtension=imageNames;
imageNames=strcat(imageNames,'.pgm');

for i=1:length(imageNames)
    fileName=strcat(inputDir,'/',imageNames{i});
    [image, descrips, locs] = sift(fileName);
    outputFileName=strcat(outputDir,'/',imageNamesWithoutExtension{i});
    dlmwrite(outputFileName, descrips, '\t');    
    disp(sprintf('%d\tWritten vectors for for image: %s',i,fileName));
end

% fileNames=dir(inputDir);
% fileNames(1)=[]; % removes the directory . from the list
% fileNames(1)=[]; % removes the directory .. from the list

