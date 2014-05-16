javaaddpath('MyJavaCodes.jar'); 
import HelperPackage.*;

IDvsTagFile='../data/IDvsTag.map'; %Input
OutputSimilarityFile='../data/SimilarityMatrix_ForTags.txt'; %Output

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
        similarity=LCS.getSimilarity(s1,s2);
        disp(sprintf('%d %d %s %s %s', i, j, s1, s2, similarity));
        if (similarity~=0)
            fprintf(fid,'%d\t%d\t%g\n', i, j, similarity);
            %if (i~=j)
            %    fprintf(fid,'%d\t%d\t%g\n', j, i, similarity);
            %end
        end
    end
end

fclose(fid);