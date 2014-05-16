clear all;
global myData;
global noClust;
global noFeat;
global k1; % Number of clusters in dataset 1
global k2; % Number of clusters in dataset 2
global relations;
global rhoByD;
global memberships1;

noClust=2;
k1=noClust; % For alternative clustering, it is the same as k2
k2=noClust; % For alternative clustering, it is the same as k2
rhoByD=2.0;
%% Data and lebel Reads
myData=dlmread('data/4Gauss.txt', '\t');
labelAssignments=dlmread('data/4Gauss.labels', '\t');

%myData=dlmread('data/ionosphere.txt', '\t');
%labelAssignments=dlmread('data/ionosphere.labels', '\t');

%myData=dlmread('data/glass.txt', '\t');
%labelAssignments=dlmread('data/glass.labels', '\t');

%myData=dlmread('data/magic04.txt', '\t');
%labelAssignments=dlmread('data/magic04.labels', '\t');

%myData=dlmread('data/vehicles.txt', '\t');
%labelAssignments=dlmread('data/vehicles.labels', '\t');

%myData=dlmread('data/CTG.txt', '\t');
%labelAssignments=dlmread('data/CTG.labels', '\t');

%myData=dlmread('data/BreastTissue.txt', '\t');
%labelAssignments=dlmread('data/BreastTissue.labels', '\t');

% myData=dlmread('data/libras_movement.txt', '\t');
% labelAssignments=dlmread('data/libras_movement.labels', '\t');

%myData=dlmread('data/SteelPlatesFaults.txt', '\t');
%labelAssignments=dlmread('data/SteelPlatesFaults.labels', '\t');

% Normalize data
%for i=1:size(myData,2)
%   myData(:,i)=myData(:,i)-mean(myData(:,i)); %msh: subtract from the mean of an attribute to form the new data
%end


%% Add a directory for validity
path(path,'./Codes');
path(path,'./MyCodes');
path(path,'./Codes/validityTests');
%%
% Prepare the relations. For alternative clustering we only need the one to
% one relations
relations=zeros(length(myData),2);
relations(:,1)=1:length(myData);
relations(:,2)=1:length(myData);

%%

labels=unique(labelAssignments);
k=length(labels);

[IDX1,meanproto1]=kmeans(myData,noClust);
%[IDX2,meanproto2]=kmeans(myData,noClust);
meanproto2=meanproto1;
% Now meanproto1 contains the mean prototypes and IDX1 contains the
% assignments

noFeat=size(myData,2);
disp('Number of features in the dataset: ');
disp(noFeat);


disp('Mean prototype 1:')
disp(meanproto1);
disp('Mean prototype 2:')
disp(meanproto2);

[memberships1] = calculatemembershipProbs(myData, meanproto1, rhoByD);
[memberships2] = calculatemembershipProbs(myData, meanproto2, rhoByD);

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


%% Now combine the two meanprototypes
% combined=[meanproto1;meanproto2];
% Then flatten it to one array X.
noOfEle=size(meanproto2,1)*size(meanproto2,2);

X=reshape(meanproto2',1,noOfEle);

%% Now take X and send to the optimization routine
XX = fminunc(@ObjFunc_seq,X);

%% Now see if XX gives a good contingency table
%X1=XX(1:k1*noFeat);
X2=XX(1:end);

%meanproto1=reshape(X1,noFeat,k1)';
meanproto2=reshape(X2,noFeat,k2)';

%[memberships1] = calculatemembershipProbs(myData, meanproto1, rhoByD);
[memberships2] = calculatemembershipProbs(myData, meanproto2, rhoByD);

[ contingency1, w1 ] = prepareContingency(memberships1, memberships2,...
                                              relations, ...
                                              1);     
[ contingency2, w2 ] = prepareContingency(memberships1, memberships2,...
                                              relations, ...
                                              2);         

disp('After optimization (rowwise probabilities): ');
disp(contingency1);
disp('After optimization: (columnwise probabilities)');
disp(contingency2);

disp('After optimization (contingency from rowwise): ');
disp(w1);
disp('After optimization: (contingency from colwise)');
disp(w2);

%clusterAssignments= findAssignmentsFrommemberships(U); % assignments from memberships
%hardMemberships= prepareHardAssignmentProbabilitiesFromU(U);

%dlmwrite('Results/memberships.csv', U);
%dlmwrite('Results/assignments.csv', clusterAssignments);

% idx=kmeans(myData, k);
% jacc=JaccardSimilarity(idx, labelAssignments);
% disp('Jaccard of k-means clustering is:');
% disp(jacc);
% 
% dlmwrite('Results/realLabelNumbersinSequence.csv', labels);
