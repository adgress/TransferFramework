function [p] = z2p(z, mu, sigma)
%function [p] = z2p(z, varargin, mu, sigma)
% function p = z2p(z,tails)
% 
%  Converts normally distributed z-statistic to one- or two-tailed p-value
%  by integrating the standard normal pdf. If no "tails" value is
%  specified, z2p computes the two-tailed value by default. The output p is
%  the same size as z, which can be a scalar, vector, or matrix.
%  
% Inputs:
%
%                    z: normally distributed z-statistic (positive or negative)
%   (optional)  tailed: the number of tails over which to compute the probability value
%                       (Note: by symmetry of the normal distribution, the two-tailed
%                       p-value is twice the one-tailed value.)


% optargin = size(varargin,2);
% if isempty(varargin)
%    tails = 2; 
% elseif optargin~=1    
%     error([ num2str(optargin-1) ' too many input arguments!'])
% else
%     tails = varargin{1};
%     if ~isscalar(tails)
%         error(' ''tails'' input argument must be a scalar value (1 or 2)')
%     elseif ~ismember(tails,[1 2])
%         error('tails must be 1 or 2!')
%     end
% end

tails=1;
p = tails*normcdf(-abs(z), mu, sigma);
