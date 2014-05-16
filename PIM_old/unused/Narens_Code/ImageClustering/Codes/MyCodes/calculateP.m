function [pval, jaccard, w] = calculateP( myData, labelAssignments, classID, clusterID, U)
    %clear all;
    % Data and lebels
    %myData=dlmread('data/ionosphere.txt', '\t');
    %labelAssignments=dlmread('data/ionosphere.labels', '\t');
    %%
    labels=unique(labelAssignments);
    k=length(labels);

    if (clusterID<1 || clusterID>k)
        disp('k=');
        disp(k);
        disp('clusterID');
        disp(clusterID);
        err = MException('ResultChk:OutOfRange', ...
            'clusterID is outside expected range');
        throw(err);
    end

    if (classID<1 || classID>k)
        disp('classID');
        disp(classID);
        err = MException('ResultChk:OutOfRange', ...
            'classID is outside expected range');
        throw(err);
    end 

    addpath('Codes');
    
%     nclass=k;                   % number of class
%     phi=2;                      % fuzzy exponent >1
%     maxiter=1000;               % maximum iterations
%     toldif=0.000000001;         % convergence criterion % 0.000001
%     distype=1;                  % distance type:        1 = euclidean, 2 = diagonal, 3 = mahalanobis
%     scatter=0.2;                % scatter around initial membership
%     ntry=10;                    % number of trial to choose an optimal solution
% 
%     % run fuzme
%     [U, centroid, dist, W, obj] = run_fuzme(nclass,myData,phi,maxiter,distype,toldif,scatter,ntry);

    %idx = kmeans(myData,k);

    %n=length(idx); %% number of objects

    n=length(labelAssignments);
    
    classMemberships=[];
    for l=1:length(labels)
        v=labelAssignments; % v is the lables
        disp(labels(l));
        v(v==labels(l))=-1; 
        v(v>-1)=0;
        v(v<0)=1.0;
        classMemberships=[classMemberships v];
    end 

    w=U; % w contains all the membership probabilities

    % CALCULATE mean(w_j):
    % At this moment you have w. You can access w_ij by w(i, j) where
    % i indicates the elelemnt id and j is the j-th cluster. 
    % you can find the sample mean of the j-th cluster by mean(w(:,j))

    % CALCULATE n_c: This is the number of samples labeled with class c.
    % you can access this in the following way:
    % length(labelAssignments(labelAssignments==labels(l)))

    % CALCULATE w_d,j: where d is the class and j is the cluster.
    % w_dj_bar(w, d, j, labels, labelAssignments)

    % CALCULATE p_c=n_c/n
    % You can calculate this in the following way:
    % length(labelAssignments(labelAssignments==labels(l)))/n

    % class c cluster j
    c=classID; % 1 indicates the first class
    j=clusterID; % 1 indicates the fist cluster
    ycj=y_cj( c, j, w, labels, labelAssignments);
    n_cwj=(length(labelAssignments(labelAssignments==labels(c))))*mean(w(:,j));
    top=ycj-n_cwj;


    sum=0.0;
    p_c=length(labelAssignments(labelAssignments==labels(c)))/n;
    for l=1:length(labels)
        d=l;
        n_d=length(labelAssignments(labelAssignments==labels(d)));
        Ssq=Ssqwbar_dj(w, d, j, labels, labelAssignments);
        wbar_dj=w_dj_bar(w, d, j, labels, labelAssignments);
        wbarsq_dj=wbar_dj*wbar_dj;
        sum=sum+n_d*(Ssq+(1-p_c)*wbarsq_dj);
    end 
    bottom=sqrt(p_c*sum);

    if (bottom==0)
        %err = MException('ResultChk:Zero', ...
        %    'Bottom is zero. Hence will be divide by zero');
        %throw(err);        
        bottom=1e-100;
    end
    
    z= top/bottom;
    disp('z value: ');
    disp(z);

    %p=z2p(z, n_cwj, bottom);
    p=2.0*normcdf(-1.0*abs(z));

    disp('p value: ');
    disp(p);
    pval=p;
    
    assignments= findAssignmentsFrommemberships(w); % assignments from memberships
    jaccard=JaccardSimilarity(assignments, labelAssignments);
    disp('Jaccard:');
    disp(jaccard);
