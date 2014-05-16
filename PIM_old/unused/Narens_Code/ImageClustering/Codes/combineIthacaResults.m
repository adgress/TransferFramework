
inputDir='../imageVectorFiles'; %Input
IDvsImageFile='../data/IDvsImage.map'; %Input
matchDir='../temp/'; %Input
keepImageVectorsLoaded = true;
OutputSimilarityFileMatch='../data/SimilarityMatrix_ForImages_matches.txt'; %Output
OutputSimilarityFileCosine='../data/SimilarityMatrix_ForImages_cosine.txt'; %Output
OutputSimilarityFileJaccards='../data/SimilarityMatrix_ForImages_jaccards.txt'; %Output

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
 
 noOfKeypoints=zeros(size(imageNames,2),1);
 for i=1:size(imageNames,2)
     file=strcat(inputDir,'/',imageNames{i});
     desc=dlmread(file);
     noOfKeypoints(i)=size(desc,1);
     fprintf('Total loaded: %d\n', i);
 end


tempFiles=dir(matchDir);
tempFiles(1)=[]; %remove .
tempFiles(1)=[]; %remove ..

allMatches=[];
for i=1:size(tempFiles,1)
    fileName=strcat(matchDir,'/',tempFiles(i).name);
    matchData=dlmread(fileName);
    allMatches=[allMatches;matchData];
end

dlmwrite(OutputSimilarityFileMatch,allMatches,'\t');
pause(1);

%%Now you have data with all the matches


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

