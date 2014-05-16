function [ hardMemberships ] = prepareHardAssignmentProbabilitiesFromU(U)
    % U is a matrix that contains the soft assignments. This is w used in
    % some other functions.
    
s=size(U);
k= s(1,2);%number of clusters

n=length(U);

hardMemberships=zeros(n,k);

for i=1:n % for every data point
    memberships= U(i, :);
    [maximum, indices]= max(memberships);
    max_index=indices(1, 1);    
    hardMemberships(i, max_index)=1.0;
end



end