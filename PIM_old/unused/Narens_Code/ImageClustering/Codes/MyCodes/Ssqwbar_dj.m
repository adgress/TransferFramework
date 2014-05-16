function [S] = Ssqwbar_dj(w, d, j, labels, classAssignments)
% d: the d-th class
% j: the j-th cluster
% labels: a vector that contains the classes (e.g., 0, 1) if it has two
% vectors
% classAssignments a vector of length n=number of objects.

indicesWithClassd=find(classAssignments==labels(d));

sum=0;
for i=1:length(indicesWithClassd)
    index=indicesWithClassd(i);
    sq=w(index, j)-w_dj_bar(w, d, j, labels, classAssignments);
    sq=sq*sq;
    sum=sum+sq;
end

n_d=length(classAssignments(classAssignments==labels(d)));
S=sum/(n_d-1);

