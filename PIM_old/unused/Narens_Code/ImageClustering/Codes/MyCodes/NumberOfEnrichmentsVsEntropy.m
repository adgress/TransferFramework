function [ results ] = NumberOfEnrichmentsVsEntropy( ...
    myData, clusterAssignments, labelAssignments, pValueThreshold )

% results would return 3 columns.
% Col1: Entropy
% Col2: totalEnrichmentsP (wald)
% Col3: totalEnrichmentsH (Hypergeometric)

hardAssignmentDefinition =0.9999;
numberOfClusters=length(unique(labelAssignments));
labels=unique(labelAssignments);
k=length(labels);

PValues_hyperG = ones(k,k);
for classID=1:k
    for clusterID=1:k
        [hyperPVal]=calculateHyperGeomPValue( clusterAssignments, labelAssignments, labels, classID, clusterID);
        PValues_hyperG(classID, clusterID)=hyperPVal;
    end
end    


results=[];
while (hardAssignmentDefinition>0.0)
    
    U = prepareHardAssignmentProbFromAssignments(clusterAssignments, hardAssignmentDefinition);    
    
    totalEnrichmentsP=0;
    totalEnrichmentsH=0;
    
    PValues = ones(k,k);
    for classID=1:k
        for clusterID=1:k
            [pVal jaccard w]=calculateP( myData, labelAssignments, classID, clusterID, U);
            PValues(classID, clusterID)=pVal;
            
            if PValues(classID, clusterID)<=pValueThreshold
                totalEnrichmentsP=totalEnrichmentsP+1;
            end            
            if PValues_hyperG(classID, clusterID)<=pValueThreshold
                totalEnrichmentsH=totalEnrichmentsH+1;
            end                        
        end
    end    
    
    
    % Calculate entropy
    vector=ones(1,k);
    toBeMultipliedBy = (1.0-hardAssignmentDefinition)/(k-1);
    vector=vector*toBeMultipliedBy;
    vector(1,1)=hardAssignmentDefinition;
    entropy=TheEntropy(vector);
    % End of Calculate entropy
    
    %results=[results; hardAssignmentDefinition totalEnrichmentsP totalEnrichmentsH];
    results=[results; entropy totalEnrichmentsP totalEnrichmentsH];
    
    hardAssignmentDefinition=hardAssignmentDefinition-0.1;
end


end

