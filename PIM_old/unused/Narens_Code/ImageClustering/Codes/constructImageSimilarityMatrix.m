javaaddpath('MyJavaCodes.jar');
import HelperPackage.*;

inputDir='../imageVectorFiles'; %Input
IDvsImageFile='../data/IDvsImage.map'; %Input
keepImageVectorsLoaded = true;
OutputSimilarityFile='../data/SimilarityMatrix_ForImages.txt'; %Output



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

fid=fopen(OutputSimilarityFile, 'w');

for i=1:size(imageNames,2)
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
        similarity=ImageImageSimilarity(desc1,desc2);
        
        disp(sprintf('%d %d %s %s %g', i, j, imageNames{i}, imageNames{j}, similarity));
        if (similarity~=0)
            fprintf(fid,'%d\t%d\t%g\n', i, j, similarity);
            %if (i~=j)
            %    fprintf(fid,'%d\t%d\t%g\n', j, i, similarity);
            %end
        end
    end
end

fclose(fid);
