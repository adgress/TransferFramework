function [symF] = prepareSymbolicF(meanproto1, meanproto2)
    global rhoByD;
    global data1;
    global data2;
    global k1; % Number of clusters in dataset 1
    global k2; % Number of clusters in dataset 2
    global relations;    
    
    noFeat1= size(data1,2);
    noFeat2= size(data2,2);    
    
    %disp('Mean proto 1:')
    %disp(meanproto1);
    
    %disp('Mean proto 2:')
    %disp(meanproto2);    
    
    [memberships1] = calculateSymMembershipProbs(data1, meanproto1, rhoByD);
    [memberships2] = calculateSymMembershipProbs(data2, meanproto2, rhoByD);
    disp(':size(membership1)');
    disp(size(memberships1));    
    
    [ contingency1 ] = prepareSymContingency(memberships1, memberships2,...
                                                  relations, ...
                                                  1);     
                                              
    [ contingency2 ] = prepareSymContingency(memberships1, memberships2,...
                                                  relations, ...
                                                  2);         
    %disp('Mean prototype 1:')
    %disp(meanproto1);
    %disp('Mean prototype 2:')
    %disp(meanproto2);
                         
    %% Deal with row distribution
    Part1=0;
    U=ones(1,size(contingency1,2))/size(contingency1,2);
    for i=1:length(contingency1) % over the rows
       Part1=Part1+KLDiv(contingency1(i,:), U);        
    end
    Part1=Part1/length(contingency1); % Dividing by number of clusters
    
    %% deal with column distribution
    Part2=0;
    U=ones(length(contingency2),1)/length(contingency2);
    for j=1:size(contingency2,2) % over the columns
        Part2= Part2+KLDiv(contingency2(:,j)', U');
    end
    Part2=Part2/size(contingency2,2); % dividing by number of clusters
    %% Sum them up for F    
    obj=Part1+Part2; 
    symF=obj;
end