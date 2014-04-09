% Copyright (c) 2013, Basura Fernando
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification, 
% are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this 
%list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice, 
% this list of conditions and the following disclaimer in the documentation and/or 
% other materials provided with the distribution.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR 
% ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON 
% ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% Based on the paper :
% 
% @inproceedings{Fernando2013b,
% author = {Basura Fernando, Amaury Habrard, Marc Sebban, Tinne Tuytelaars},
% title = {Unsupervised Visual Domain Adaptation Using Subspace Alignment},
% booktitle = {ICCV},
% year = {2013},
% } 
%

function Subspace_Alignment(Source_Data,Target_Data,Source_label,Target_label,Subspace_Dim)

% Normalize data
Source_Data = NormalizeData(Source_Data);
Target_Data = NormalizeData(Target_Data);

% PCA
[Xs,D,E] = princomp(Source_Data);
[Xt,D,E] = princomp(Target_Data);

% create subspace
Xs = Xs(:,1:Subspace_Dim);
Xt = Xt(:,1:Subspace_Dim);

% Subspace alignment and projections
Target_Aligned_Source_Data = Source_Data*(Xs * Xs'*Xt);
Target_Projected_Data = Target_Data*Xt;

NN_Neighbours = 1; %  neares neighbour classifier
predicted_Label = cvKnn(Target_Projected_Data', Target_Aligned_Source_Data', Source_label, NN_Neighbours);        
r=find(predicted_Label==Target_label);
accuracy = length(r)/length(Target_label)*100; 

fprintf('SA Accuacry %1.2f \n',accuracy);

end

function Data = NormalizeData(Data)
    Data = Data ./ repmat(sum(Data,2),1,size(Data,2)); 
    Data = zscore(Data,1);  
end
