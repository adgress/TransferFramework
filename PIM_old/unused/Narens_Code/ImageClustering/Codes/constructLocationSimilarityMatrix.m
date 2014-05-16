javaaddpath('MyJavaCodes.jar'); 
import HelperPackage.*;

inputDir='../data_vanc-1k';

IDvsLocationFile=strcat(inputDir,'/IDvsLocation.map'); %Input
OutputSimilarityFile=strcat(inputDir,'/SimilarityMatrix_ForLocation.txt');%Output

temp=dlmread(IDvsLocationFile);

lattitudes=[];
longitudes=[];

for i=1:size(temp,1)
    lattitudes(i)=0;
    longitudes(i)=0;
end

for i=1:size(temp,1)
    ID=temp(i,1);
    lattitudes(ID)=temp(i,2);
    longitude(ID)=temp(i,3);
end

% At this moment the variable lattitudes and longitudes contain the lattitudes
% and longitudes. The indices of these two arrays match with the LocationIDs.
% That is, a lattitude and longitude with ID 1 is in index 1 of the variable
% "lattitudes" and "longitudes". 

fid=fopen(OutputSimilarityFile, 'w');

for i=1:size(temp,1)
    v1=[lattitudes(i) longitudes(i)];
    for j=i:size(temp,1)
        v2=[lattitudes(j) longitudes(j)];        
        dist=pdist([v1;v2], 'euclidean');
        similarity=1.0/(1+dist);
        disp(sprintf('%d\t%d\t%g',i,j,similarity));
        if (similarity~=0)
            fprintf(fid,'%d\t%d\t%g\n', i, j, similarity);
            %if (i~=j)
            %    fprintf(fid,'%d\t%d\t%g\n', j, i, similarity);
            %end
        end
    end
end

fclose(fid);
