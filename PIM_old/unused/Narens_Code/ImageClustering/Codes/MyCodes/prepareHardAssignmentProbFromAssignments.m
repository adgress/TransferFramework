function [ hardMemberships ] = prepareHardAssignmentProbFromAssignments(assignments, probOfBest)
    % U is a matrix that contains the soft assignments. This is w used in
    % some other functions.
    % probOfBest is the probability to be assigned for best assignment.
    
    %s=size(U);

    n=length(assignments);

    labels=unique(assignments);
    k= length(labels);%number of clusters
    
    %hardMemberships=zeros(n,k);
    hardMemberships=ones(n,k);
    toBeMultipliedBy = (1.0-probOfBest)/(k-1);
    hardMemberships=hardMemberships*toBeMultipliedBy;
        
    for i=1:n % for every data point
        whichClusterIsAssigned= assignments(i);
        indexOfThatCluster=find(labels==whichClusterIsAssigned);
        hardMemberships(i, indexOfThatCluster)=probOfBest;
    end

    
end