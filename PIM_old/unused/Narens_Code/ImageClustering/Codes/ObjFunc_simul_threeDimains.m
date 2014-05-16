function [obj] = ObjFunc_simul_threeDimains(X, toTransfer)
    rhoByD=toTransfer.rhoByD;
    data1=toTransfer.data1;
    data2=toTransfer.data2;
    data3=toTransfer.data3;
    k1=toTransfer.k1;
    k2=toTransfer.k2;
    k3=toTransfer.k3;
    relations1=toTransfer.relations1;
    relations2=toTransfer.relations2;
    sequential=toTransfer.sequential;

    noFeat1= size(data1,2);
    noFeat2= size(data2,2);
    noFeat3= size(data3,2);

    if (sequential==false)
        X1=X(1:k1*noFeat1);
        startOfX2=1+k1*noFeat1;
        X2=X(startOfX2:startOfX2+noFeat2*k2-1);
        startOfX3=startOfX2+noFeat2*k2;
        X3=X(startOfX3:end);
        meanproto1=reshape(X1,noFeat1,k1)';
        meanproto2=reshape(X2,noFeat2,k2)';
        meanproto3=reshape(X3,noFeat3,k3)';
    else
        X1=X;
        meanproto1=reshape(X1,noFeat1,k1)';
        meanproto2=toTransfer.meanproto2;
        meanproto3=toTransfer.meanproto3;
    end
    
    %disp('Mean proto 1:')
    %disp(meanproto1);
    
    %disp('Mean proto 2:')
    %disp(meanproto2);    
    
    [memberships1] = calculatemembershipProbs(data1, meanproto1, rhoByD);
    [memberships2] = calculatemembershipProbs(data2, meanproto2, rhoByD);
    [memberships3] = calculatemembershipProbs(data3, meanproto3, rhoByD);


    [ contingencyR1_1 ] = prepareContingency(memberships1, memberships2,...
                                                  relations1, ...
                                                  1);                    
    [ contingencyR1_2 ] = prepareContingency(memberships1, memberships2,...
                                                  relations1, ...
                                                  2);         
                 
    % Now prepare row and column contingency tables for the second
    % relationship
    
    [ contingencyR2_1 ] = prepareContingency(memberships1, memberships3,...
                                                  relations2, ...
                                                  1);     
    [ contingencyR2_2 ] = prepareContingency(memberships1, memberships3,...
                                                  relations2, ...
                                                  2);             
                                              
    %disp('Mean prototype 1:')
    %disp(meanproto1);
    %disp('Mean prototype 2:')
    %disp(meanproto2);
                         
    %% Deal with row distribution
    Part1=0;
    U=ones(1,size(contingencyR1_1,2))/size(contingencyR1_1,2);
    for i=1:length(contingencyR1_1) % over the rows
       Part1=Part1+KLDiv(contingencyR1_1(i,:), U);        
    end
    Part1=Part1/length(contingencyR1_1); % Dividing by number of clusters
    %% deal with column distribution
    Part2=0;
    U=ones(length(contingencyR1_2),1)/length(contingencyR1_2);
    for j=1:size(contingencyR1_2,2) % over the columns
        Part2= Part2+KLDiv(contingencyR1_2(:,j)', U');
    end
    Part2=Part2/size(contingencyR1_2,2); % dividing by number of clusters
    %% Sum them up for F    
    obj1=Part1+Part2;
    
    
    %% R2
    %% Deal with row distribution
    Part1=0;
    U=ones(1,size(contingencyR2_1,2))/size(contingencyR2_1,2);
    for i=1:length(contingencyR2_1) % over the rows
       Part1=Part1+KLDiv(contingencyR2_1(i,:), U);        
    end
    Part1=Part1/length(contingencyR2_1); % Dividing by number of clusters
    
    %% deal with column distribution
    Part2=0;
    U=ones(length(contingencyR2_2),1)/length(contingencyR2_2);
    for j=1:size(contingencyR2_2,2) % over the columns
        Part2= Part2+KLDiv(contingencyR2_2(:,j)', U');
    end
    Part2=Part2/size(contingencyR2_2,2); % dividing by number of clusters
    %% Sum them up for F    
    obj2=Part1+Part2;

    obj=-1.0*(obj1+obj2); % dependent
    
end

