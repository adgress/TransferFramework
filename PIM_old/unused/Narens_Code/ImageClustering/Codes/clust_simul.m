clear all;
global data1;
global data2;
global k1; % Number of clusters in dataset 1
global k2; % Number of clusters in dataset 2
global relations;
global rhoByD;
global memberships1;
global memberships2;

k1=5; % number of desired cclusters in dataset1
k2=5; % number of desired cclusters in dataset2
rhoByD=100.0;
%% Read dataset1
threeColumnMatrix=dlmread('../data_500(minimini)/SimilarityMatrix_ForImages.txt');
simMat=convertSparseColumnsToSparseMat(threeColumnMatrix);
[eigVectors,eigValues] = eigs(simMat,k1+1);
data1=eigVectors(:,2:k1+1);

%data1=dlmread('../data_500(minimini)/4Gauss.txt', '\t');

scatter3(data1(:,2),data1(:,3),data1(:,4));
title('Just Image');
figure
%% Read dataset2
% Note that I am reading the same dataset here. But
% you need to read two different datasets with 1-to-1
% relationships between them.
threeColumnMatrix=dlmread('../data_500(minimini)/SimilarityMatrix_ForLocation.txt');
simMat=convertSparseColumnsToSparseMat(threeColumnMatrix);
[eigVectors,eigValues] = eigs(simMat,k1+1);
data2=eigVectors(:,2:k1+1);
%data2=dlmread('../data_500(minimini)/4Gauss.txt', '\t');

%labelAssignments2=dlmread('data/4P.labels', '\t');

scatter3(data2(:,2),data2(:,3),data2(:,4));
title('Just Location');

figure

%% Add a directory for validity
path(path,'./Codes');
path(path,'./MyCodes');
path(path,'./Codes/validityTests');
%%
% For disparate clustering in this scene we only need the 1-to-1
% relationships. So, prepare the 1-to-1 relatiosnships.
% relations=zeros(length(data1),2);
% relations(:,1)=1:length(data1);
% relations(:,2)=1:length(data1);

relations=dlmread('../data_500(minimini)/ImageLocations.txt');



%% Since we are considering one-to-one relationships
% we have to see if data1 and data2 has same number of 
% rows.

size1=length(data1);
size2=length(data2);

%% Now apply k-means on both the datasets.
[IDX1,meanproto1]=kmeans(data1,k1);
[IDX2,meanproto2]=kmeans(data2,k2);

% Now meanproto1 and meanproto1 contain the corresponding 
% mean prototypes. IDX1 and IDX2 contain the assignments.

noFeat1=size(data1,2);
noFeat2=size(data2,2);
disp('Number of features in the fist dataset: ');
disp(noFeat1);

disp('Number of features in the second dataset: ');
disp(noFeat2);

disp('Mean prototype 1:')
disp(meanproto1);
disp('Mean prototype 2:')
disp(meanproto2);

[memberships1] = calculatemembershipProbs(data1, meanproto1, rhoByD);
[memberships2] = calculatemembershipProbs(data2, meanproto2, rhoByD);

[ contingency1 ] = prepareContingency(memberships1, memberships2,...
                                              relations, ...
                                              1);     

[ contingency2 ] = prepareContingency(memberships1, memberships2,...
                                              relations, ...
                                              2);      
                                          
disp('Initial contingency1');
disp(contingency1);

disp('Initial contingency2');
disp(contingency2);

%% Now prepare the symbolic F
% symMinProto1 = sym('m');
% for i=1:length(meanproto1)
%      for j=1:size(meanproto1,2)
%          symMinProto1(i,j)=strcat('m(',int2str(i),',',int2str(j),')');
%      end
% end
% 
% symMinProto2 = sym('m');
% for i=1:length(meanproto2)
%     for j=1:size(meanproto2,2)
%         symMinProto2(i,j)=strcat('m(',int2str(i),',',int2str(j),')');
%     end
% end
% 
% [symF]=prepareSymbolicF(symMinProto1, symMinProto2);

% error('Program exit');

%% Now combine the two meanprototypes
combined=[meanproto1;meanproto2];
% Then flatten it to one array X.
noOfEle=size(meanproto1,1)*size(meanproto1,2)+...
        size(meanproto2,1)*size(meanproto2,2);
X=reshape(combined',1,noOfEle);


%% Now take X and send to the optimization routine
[XX, fval] = fminunc(@ObjFunc_simul,X);

%% Now see if XX gives a good contingency table
X1=XX(1:k1*noFeat1);
X2=XX(1+k1*noFeat1:end);

meanproto1=reshape(X1,noFeat1,k1)';
meanproto2=reshape(X2,noFeat2,k2)';

[memberships1] = calculatemembershipProbs(data1, meanproto1, rhoByD);
[memberships2] = calculatemembershipProbs(data2, meanproto2, rhoByD);

[ contingency1 ] = prepareContingency(memberships1, memberships2,...
                                              relations, ...
                                              1);     
[ contingency2 ] = prepareContingency(memberships1, memberships2,...
                                              relations, ...
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


