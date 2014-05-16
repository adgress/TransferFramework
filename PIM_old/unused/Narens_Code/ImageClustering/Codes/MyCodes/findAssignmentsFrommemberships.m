function [ assignments ] = findAssignmentsFrommemberships(w)
% Input: The membership probabilities

% output: the variable assignments would contains the assignments
% Note that the assignments are the indices of the columns.

s=size(w);
k= s(1,2);%number of clusters

n=length(w);

assignments=ones(n,1);
for i=1:n % for every data point
    memberships= w(i, :);
    [maximum, indices]= max(memberships);
    max_index=indices(1, 1);    
    assignments(i, 1)=max_index;
end


end

