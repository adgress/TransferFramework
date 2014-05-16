clear all;
global data1;
global data2;
global data3;
global k1; % Number of clusters in dataset 1
global k2; % Number of clusters in dataset 2
global k3; % Number of clusters in dataset 2
global relations1; % Image to locations
global relations2; % Image to tags
global rhoByD;
global memberships1;
global memberships2;
global memberships3;

k1=4; % number of desired clusters in dataset1
k2=4; % number of desired clusters in dataset2
k3=4; % number of desired clusters in dataset3
sequential=true; % make it false if you want simultaneous
rhoByD=50.0;
%% Read dataset1
threeColumnMatrix=dlmread('../data_500(minimini)/SimilarityMatrix_ForImages.txt');
simMat=convertSparseColumnsToSparseMat(threeColumnMatrix);
[eigVectors,eigValues] = eigs(simMat,k1+1);
data1=eigVectors(:,2:k1+1);
%labelAssignments1=dlmread('data/4P.labels', '\t');

scatter3(data1(:,2),data1(:,3),data1(:,4));
title('Just Image');
figure
%% Read dataset2
threeColumnMatrix=dlmread('../data_500(minimini)/SimilarityMatrix_ForLocation.txt');
simMat=convertSparseColumnsToSparseMat(threeColumnMatrix);
[eigVectors,eigValues] = eigs(simMat,k2+1);
data2=eigVectors(:,2:k2+1);

%labelAssignments2=dlmread('data/4P.labels', '\t');

scatter3(data2(:,2),data2(:,3),data2(:,4));
title('Just Location');

figure

%% Read dataset3
threeColumnMatrix=dlmread('../data_500(minimini)/SimilarityMatrix_ForTags.txt');
simMat=convertSparseColumnsToSparseMat(threeColumnMatrix);
[eigVectors,eigValues] = eigs(simMat,k3+1);
data3=eigVectors(:,2:k3+1);

%labelAssignments2=dlmread('data/4P.labels', '\t');

scatter3(data3(:,2),data3(:,3),data3(:,4));
title('Just Tags');

figure

%% Add a directory for validity
path(path,'./Codes');
path(path,'./MyCodes');
path(path,'./Codes/validityTests');
%%
% For disparate clustering in this scene we only need the 1-to-1
% relationships. So, prepare the 1-to-1 relatiosnships.
%relations=zeros(length(data1),2);
%relations(:,1)=1:length(data1);
%relations(:,2)=1:length(data1);

relations1=dlmread('../data_500(minimini)/ImageLocations.txt');
relations2=dlmread('../data_500(minimini)/ImageTagsFile.txt');


%% Since we are considering one-to-one relationships
% we have to see if data1 and data2 has same number of 
% rows.

size1=size(data1,1);
size2=size(data2,1);
size3=size(data3,1);

%% Now apply k-means on both the datasets.
[IDX1,meanproto1]=kmeans(data1,k1);
[IDX2,meanproto2]=kmeans(data2,k2);
[IDX3,meanproto3]=kmeans(data3,k3);

% Now meanproto1 and meanproto1 contain the corresponding 
% mean prototypes. IDX1 and IDX2 contain the assignments.

noFeat1=size(data1,2);
noFeat2=size(data2,2);
noFeat3=size(data3,2);
disp('Number of features in the fist dataset: ');
disp(noFeat1);

disp('Number of features in the second dataset: ');
disp(noFeat2);

disp('Number of features in the second dataset: ');
disp(noFeat3);

disp('Mean prototype 1:')
disp(meanproto1);
disp('Mean prototype 2:')
disp(meanproto2);
disp('Mean prototype 3:')
disp(meanproto3);

[memberships1] = calculatemembershipProbs(data1, meanproto1, rhoByD);
[memberships2] = calculatemembershipProbs(data2, meanproto2, rhoByD);
[memberships3] = calculatemembershipProbs(data3, meanproto2, rhoByD);

% [ contingency1 ] = prepareContingency(memberships1, memberships2,...
%                                               relations, ...
%                                               1);     
% 
% [ contingency2 ] = prepareContingency(memberships1, memberships2,...
%                                               relations, ...
%                                               2);      
% 
% disp('Initial contingency1');
% disp(contingency1);
% 
% disp('Initial contingency2');
% disp(contingency2);

%% Now combine the two meanprototypes
X1=reshape(meanproto1',1,size(meanproto1,1)*size(meanproto1,2));
X2=reshape(meanproto2',1,size(meanproto2,1)*size(meanproto2,2));
X3=reshape(meanproto3',1,size(meanproto3,1)*size(meanproto3,2));
    
X=[X1 X2 X3];
if (sequential==true)
    X=X1;
end
%X=reshape(combined',1,noOfEle);
options = optimset(optimset( 'fmincon' ), ...
                   'LargeScale','off', ...
                   'Algorithm','active-set', ...
                   'Display','iter', ...
                   'MaxFunEvals', 60000, ...
                   'MaxIter', 400,...
                   'UseParallel', 'always');    
               
%% Now take X and send to the optimization routine
%[XX, fval] = fminunc(@ObjFunc_simul_threeDimains,X);


%% %%%%
ub1=max(max(data1));    
ub2=max(max(data2));    
ub3=max(max(data3));
ub=max(ub1,ub2);
ub=max(ub,ub3);

lb1=min(min(data1));    
lb2=min(min(data2));    
lb3=min(min(data3));
lb=min(lb1,lb2);
lb=min(lb,lb3);

mat1=diag(ones(1,length(X)));
mat2=diag(-1*ones(1,length(X)));
    
A=[mat1; mat2];
b1=ub*ones(1,length(X));
b2=-1.0*lb*ones(1,length(X));
b=[b1 b2];

ubVector=ub*ones(1,length(X));
lbVector=lb*ones(1,length(X));

toTransfer.rhoByD=rhoByD;
toTransfer.data1=data1;
toTransfer.data2=data2;
toTransfer.data3=data3;
toTransfer.k1=k1;
toTransfer.k2=k2;
toTransfer.k3=k3;
toTransfer.relations1=relations1;
toTransfer.relations2=relations2;
toTransfer.sequential=sequential;
toTransfer.meanproto2=meanproto2;
toTransfer.meanproto3=meanproto3;
%ObjFunc_simul_threeDimains( X, toTransfer)

objpenalty = @(X) ObjFunc_simul_threeDimains( X, toTransfer);
%[XX, fval] = fmincon(@ObjFunc_seq,X,A,b,[],[],lbVector,ubVector,[],options);
[XX, fval] = fmincon(objpenalty,X,[],[],[],[],lbVector,ubVector,[],options);


%% %%%%

%% Now see if XX gives a good contingency table
if (sequential==false)
    X1Final=XX(1:k1*noFeat1);
    startOfX2=1+k1*noFeat1;
    X2Final=X(startOfX2:startOfX2+noFeat2*k2-1);
    startOfX3=startOfX2+noFeat2*k2;
    X3Final=XX(startOfX3:end);
else
    X1Final=XX;
    X2Final=X2;
    X3Final=X3;    
end

meanproto1=reshape(X1Final,noFeat1,k1)';
meanproto2=reshape(X2Final,noFeat2,k2)';
meanproto3=reshape(X3Final,noFeat3,k3)';

[memberships1] = calculatemembershipProbs(data1, meanproto1, rhoByD);
[memberships2] = calculatemembershipProbs(data2, meanproto2, rhoByD);
[memberships3] = calculatemembershipProbs(data3, meanproto3, rhoByD);

[ contingency1 ] = prepareContingency(memberships1, memberships2,...
                                              relations1, ...
                                              1);     
[ contingency2 ] = prepareContingency(memberships1, memberships2,...
                                              relations1, ...
                                              2);         

disp('After optimization (rowwise contingency): ');
disp(contingency1);
disp('After optimization: colwise contingency');
disp(contingency2);

disp(sprintf('Objective Function=%f', fval));

%% Now fval contains your final fval. Do this for pairs of segments.
%% You might want to wrap it to a function and call it as many times
%% as you want.
clusterAssignmentsForData1=assignmentFromMembershipProbs(memberships1);
dlmwrite('../data_500(minimini)/data1ClusterAssignments.txt', clusterAssignmentsForData1','\t');

clusterAssignmentsForData2=assignmentFromMembershipProbs(memberships2);
dlmwrite('../data_500(minimini)/data2ClusterAssignments.txt', clusterAssignmentsForData2','\t');

clusterAssignmentsForData3=assignmentFromMembershipProbs(memberships3);
dlmwrite('../data_500(minimini)/data3ClusterAssignments.txt', clusterAssignmentsForData3','\t');
