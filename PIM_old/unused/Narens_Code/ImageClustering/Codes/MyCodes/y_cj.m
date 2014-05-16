function [val] = y_cj( c, j, w, labels, classAssignments)
%Y_CJ Summary of this function goes here
%   Detailed explanation goes here
% c: c-th class
% j:j-th cluster

indicesWithClassc=find(classAssignments==labels(c));

sum=0;
for i=1:length(indicesWithClassc)
    index=indicesWithClassc(i);    
    sum=sum+w(index, j);
end

val=sum;

end

