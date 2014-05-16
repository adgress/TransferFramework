function [obj] = ObjFunc_seq(X)
    global rhoByD;
    global myData;
    global k1; %Number of clusters in dataset 1
    global k2; %Number of clusters in dataset 2
    global relations;    
    global memberships1;
    
    noFeat= size(myData,2);

%    X1=X(1:k1*noFeat);
    X2=X(1:end);

    
    
%    meanproto1=reshape(X1,noFeat,k1)';
    meanproto2=reshape(X2,noFeat,k2)';
    
    %disp('Mean proto 1:')
    %disp(meanproto1);
    
    %disp('Mean proto 2:')
    %disp(meanproto2);    
    
%    [memberships1] = calculatemembershipProbs(myData, meanproto1, rhoByD);
    [memberships2] = calculatemembershipProbs(myData, meanproto2, rhoByD);

    % Row wise
    [ contingency1 ] = prepareContingency(memberships1, memberships2,...
                                                  relations, ...
                                                  1);     
    % Column wise
    [ contingency2 ] = prepareContingency(memberships1, memberships2,...
                                                  relations, ...
                                                  2);         
%    disp('contingency 1:')
%    disp(contingency1);
%    disp('contingency 2:')
%    disp(contingency2);
                         
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
end

