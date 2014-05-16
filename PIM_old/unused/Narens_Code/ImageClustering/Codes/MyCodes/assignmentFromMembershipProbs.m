function [assignments] = assignmentFromMembershipProbs(U)
    
    for i=1:size(U,1)
        [C,I]=max(U(i,:));
        assignments(i)=I;
    end

end

