javaaddpath('MyJavaCodes.jar'); 
import HelperPackage.*;

inputDir='../data_vanc-1k';

IDvsTagFile=strcat(inputDir,'/IDvsTag.map'); %Input
ImagevsTagFile=strcat(inputDir,'/ImageTagsFile.txt'); %Input
OutputSimilarityFile=strcat(inputDir,'/SimilarityMatrix_ForTags.txt'); %Output

simFinder=TagSimilarityFinder(ImagevsTagFile);

totalID=countnonemptyLines(IDvsTagFile);

[tempTagIDs, tempTags] = textread(IDvsTagFile,'%s\t%[^\n]', totalID);

tags={};

for i=1:size(tempTagIDs,1)
    tags{i}='';
end

for i=1:size(tempTagIDs,1)
    ind=str2num(tempTagIDs{i});
    tags{ind}=tempTags{i};
end

% At this moment the variable tags contain all the tags. The indices of
% this array matches with the tagIDs. That is, a tag with tagId 1 is in
% index 1 of the variable "tags". 

fid=fopen(OutputSimilarityFile, 'w');

for i=1:size(tags,2)
    s1=tags{i};
    for j=i:size(tags,2)
        s2=tags{j};
        similarity1=simFinder.findSimilarityBetweenTwoTags(i,j);
        similarity2=LCS.getSimilarity(s1,s2);        
        %similarity=(similarity1+similarity2)/2.0;
        similarity=max(similarity1, similarity2);

        if (similarity~=0)
            disp(sprintf('%d %d %s %s %g', i, j, s1, s2, similarity));            
            fprintf(fid,'%d\t%d\t%g\n', i, j, similarity);
            %if (i~=j)
            %    fprintf(fid,'%d\t%d\t%g\n', j, i, similarity);
            %end
        end
    end
end

fclose(fid);