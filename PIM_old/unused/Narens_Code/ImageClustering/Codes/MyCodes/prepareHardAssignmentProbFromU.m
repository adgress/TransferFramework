function [ hardMemberships ] = prepareHardAssignmentProbFromU(U, probOfBest)
    % U is a matrix that contains the soft assignments. This is w used in
    % some other functions.
    % probOfBest is the probability to be assigned for best assignment.
    
    s=size(U);
    k= s(1,2);%number of clusters

    n=length(U);

    %hardMemberships=zeros(n,k);
    hardMemberships=ones(n,k);
    toBeMultipliedBy = (1.0-probOfBest)/(k-1);
    hardMemberships=hardMemberships*toBeMultipliedBy;
        
    for i=1:n % for every data point
        memberships= U(i, :);
        [maximum, indices]= max(memberships);
        max_index=indices(1, 1);
        hardMemberships(i, max_index)=probOfBest;
    end

    
    
end