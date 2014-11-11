function [co] = HRenyi_kNN_S_initialization(mult,post_init)
%function [co] = HRenyi_kNN_S_initialization(mult)
%function [co] = HRenyi_kNN_S_initialization(mult,post_init)
%Initialization of the generalized k-nearest neighbor (S\subseteq {1,...,k}) based Renyi entropy estimator.
%
%Note:
%   1)The estimator is treated as a cost object (co).
%   2)We use the naming convention 'H<name>_initialization' to ease embedding new entropy estimation methods.
%
%INPUT:
%   mult: is a multiplicative constant relevant (needed) in the estimation; '=1' means yes (='exact' estimation), '=0' no (=estimation up to 'proportionality').
%   post_init: {field_name1,field_value1,field_name2,field_value2,...}; cell array containing the names and the values of the cost object fields that are to be used
%   (instead of their default values). For further details, see 'post_initialization.m'.
%OUTPUT:
%   co: cost object (structure).

%Copyright (C) 2012-2014 Zoltan Szabo ("http://www.gatsby.ucl.ac.uk/~szabo/", "zoltan (dot) szabo (at) gatsby (dot) ucl (dot) ac (dot) uk")
%
%This file is part of the ITE (Information Theoretical Estimators) toolbox.
%
%ITE is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
%the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
%
%This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
%
%You should have received a copy of the GNU General Public License along with ITE. If not, see <http://www.gnu.org/licenses/>.

%mandatory fields (following the template structure of the estimators to make uniform usage of the estimators possible):
    co.name = 'Renyi_kNN_S';
    co.mult = mult;
    
%other fields:
    %Possibilities for 'co.kNNmethod' (see 'kNN_squared_distances.m'): 
        %I: 'knnFP1': fast pairwise distance computation and C++ partial sort; parameter: co.k.        
        %II: 'knnFP2': fast pairwise distance computation; parameter: co.k. 												
        %III: 'knnsearch' (Matlab Statistics Toolbox): parameters: co.k, co.NSmethod ('kdtree' or 'exhaustive').        
        %IV: 'ANN' (approximate nearest neighbor); parameters: co.k, co.epsi.
		%I:
            %co.kNNmethod = 'knnFP1';
            %co.k = [1,2,4];%=S: nearest neighbor set
   	    %II:
            %co.kNNmethod = 'knnFP2';
            %co.k = [1,2,4];%=S: nearest neighbor set
        %III:
            %co.kNNmethod = 'knnsearch';
            %co.k = [1,2,4];%=S: nearest neighbor set
            %co.NSmethod = 'kdtree';
        %IV:
            co.kNNmethod = 'ANN';
            co.k = [1,2,4];%=S: nearest neighbor set
            co.epsi = 0; %=0: exact kNN; >0: approximate kNN, the true (not squared) distances can not exceed the real distance more than a factor of (1+epsi).
				
    co.alpha = 0.99; %alpha \ne 1. The Renyi entropy (H_{R,alpha) equals to the Shannon differential entropy (H) in limit: H_{R,alpha} -> H, as alpha -> 1.
    co.additive_constant_is_relevant = 0; %1:additive constant is relevant (you can precompute it via 'estimate_HRenyi_constant.m'), 0:not relevant    
    
%initialize the ann wrapper in Octave, if needed:
    initialize_Octave_ann_wrapper_if_needed(co.kNNmethod);
    
%post initialization (put it _before_ initialization of the members in case of a meta estimator):    
    if nargin==2 %there are given (name,value) cost object fields
        co = post_initialization(co,post_init);
    end    
