function [ contingency, w ] = prepareContingency(...
                                              membership1, membership2,...
                                              relations, ...
                                              rowOrCol)                                          
    % membership1 and membership2 are the membership probabilities for two
    % clusterings. relations is a variable that contains the relations. For
    % one to one clustering it would only contain one to one relations. the
    % variable relations has two columns (the first one relates to a 
    % datapoint in clustering 1 and the second one relates to a datapoint 
    % in clustering 2).
    % If rowOrCol==1, it indicates row distributions are reflected in the
    % contingency table, otherwise col distributions.
    
n1= size(membership1,1);%number of datapoints
k1= size(membership1,2);%number of clusters

n2= size(membership2,1);%number of datapoints
k2= size(membership2,2);%number of clusters

noRelations= size(relations,1);


w=zeros(k1,k2);

for i=1:k1
    for j=1:k2
        for r=1:noRelations
            point1Index=relations(r,1);
            point2Index=relations(r,2);
            v1_i=membership1(point1Index, i);
            v2_j=membership2(point2Index, j);
%            disp(sprintf('v1_i=%f v2_j=%f', v1_i, v2_j));
            w(i,j)=w(i,j)+v1_i*v2_j;
        end        
    end
end

contingency=zeros(k1,k2);
if (rowOrCol==1) % Row distribution    
    for i=1:k1
        sumOfithRow=sum(w(i,:));
        for j=1:k2
            contingency(i,j)=w(i,j)/sumOfithRow;                 
        end
    end
else
    for j=1:k2    
        sumOfjthCol=sum(w(:,j));
        for i=1:k1
            contingency(i,j)=w(i,j)/sumOfjthCol;
        end
    end    
end

end