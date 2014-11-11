function [co] = HqRenyi_CDSS_initialization(mult)
%function [co] = HqRenyi_CDSS_initialization(mult)
%Initialization of the quadratic (i.e., co.alpha = 2: fixed) Renyi entropy (H) estimator based on continuously differentiable sample spacing.
%
%Note:
%   1)The estimator is treated as a cost object (co).
%   2)We use the naming convention 'H<name>_initialization' to ease embedding new entropy estimation methods.
%
%INPUT:
%   mult: is a multiplicative constant relevant (needed) in the estimation; '=1' means yes (='exact' estimation), '=0' no (=estimation up to 'proportionality').
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
    co.name = 'qRenyi_CDSS';
    co.mult = mult;   
    

