matlabpool open 7;

javaaddpath('MyJavaCodes.jar');
import HelperPackage.*;

inputDir='../imageVectorFiles'; %Input
IDvsImageFile='../data/IDvsImage.map'; %Input
keepImageVectorsLoaded = true;
outputDir='../temp/';
OutputSimilarityFileMatch='../data/SimilarityMatrix_ForImages_matches.txt'; %Output
OutputSimilarityFileCosine='../data/SimilarityMatrix_ForImages_cosine.txt'; %Output
OutputSimilarityFileJaccards='../data/SimilarityMatrix_ForImages_jaccards.txt'; %Output

Helper.delDir(outputDir);
pause(1);
mkdir(outputDir);
pause(1);

totalID=countnonemptyLines(IDvsImageFile);

[tempImageIDs, tempImageNames] = textread(IDvsImageFile,'%s\t%[^\n]', totalID);

imageNames={};

for i=1:size(tempImageIDs,1)
    imageNames{i}='';
end

for i=1:size(tempImageIDs,1)
    ind=str2num(tempImageIDs{i});
    imageNames{ind}=tempImageNames{i};
end

imageData={};
if (keepImageVectorsLoaded==true)
    for i=1:size(imageNames,2)
        file=strcat(inputDir,'/',imageNames{i});
        desc=dlmread(file);
        imageData{i}=desc;
        fprintf('Total loaded: %d\n', i);
    end
end
% At this moment the variable imageNames contain all the imageNames. The indices of
% this array matches with the tagIDs. That is, a tag with tagId 1 is in
% index 1 of the variable "imageNames". 

parfor i=1:size(imageNames,2)
    
    outputFileName = strcat(outputDir,'/',num2str(i));
    fid=fopen(outputFileName, 'w');
   
    if (keepImageVectorsLoaded==true)
        desc1=imageData{i};
    else
        file1=strcat(inputDir,'/',imageNames{i});
        desc1=dlmread(file1);
    end
    for j=i:size(imageNames,2)
        if (keepImageVectorsLoaded==true)
            desc2=imageData{j};
        else
            file2=strcat(inputDir,'/',imageNames{j});
            desc2=dlmread(file2);    
        end
        [totalMatch]=ImageImageMatch(desc1,desc2);
        
        disp(sprintf('%d %d %s %s %g', i, j, imageNames{i}, imageNames{j}, totalMatch));
        if (totalMatch~=0)            
            fprintf(fid,'%d\t%d\t%g\n', i, j, totalMatch);
        end
    end
    fclose(fid);
end


tempFiles=dir(outputDir);
tempFiles(1)=[]; %remove .
tempFiles(1)=[]; %remove ..

allMatches=[];
for i=1:size(tempFiles,1)
    fileName=strcat(outputDir,'/',tempFiles(i).name);    
    matchData=dlmread(fileName);
    allMatches=[allMatches;matchData];
end

dlmwrite(OutputSimilarityFileMatch,allMatches,'\t');
pause(1);

%%Now you have data with all the matches

%Calculate Number Of Keypoints For EachImage
noOfKeypoints=[];
if (keepImageVectorsLoaded~=true)
    imageData={};
    for i=1:size(imageNames,2)
        file=strcat(inputDir,'/',imageNames{i});
        desc=dlmread(file);
        imageData{i}=desc;
        noOfKeypoints=[noOfKeypoints size(desc,1)];
        fprintf('Total loaded: %d\n', i);
    end
else
    for i=1:length(imageData)
        desc=imageData{i};
        noOfKeypoints=[noOfKeypoints size(desc,1)];
        fprintf('Total loaded: %d\n', i);
    end    
end

%% Now construct the similarity files for cosine ans jaccards
fid_cosine=fopen(OutputSimilarityFileCosine, 'w');
fid_jacc=fopen(OutputSimilarityFileJaccards, 'w');

for i=1:size(allMatches,1)
    ind1=allMatches(i,1);
    ind2=allMatches(i,2);
    matchFound=allMatches(i,2);
    [cosineSimilarity jaccardSimilarity]=Similarities(matchFound, noOfKeypoints(ind1), noOfKeypoints(ind2));
    fprintf(fid_cosine,'%d\t%d\t%g\n', ind1, ind2, cosineSimilarity);            
    fprintf(fid_jacc,'%d\t%d\t%g\n', ind1, ind2, jaccardSimilarity);                            
end

fclose(fid_cosine);
fclose(fid_jacc);

matlabpool close;
