%Script downloaded from https://code.google.com/p/smitoolbox/source/browse/pmodels/topics/tf_idf_weight.m?spec=svn965de01efdeb08c9a5f1dc812dd4d085e746b7e7&r=965de01efdeb08c9a5f1dc812dd4d085e746b7e7

function [W, idf] = tf_idf_weight(C, op)
%TF_IDF_WEIGHT Computes TF-IDF Weights
%
%   W = TF_IDF_WEIGHT(C);
%
%       calculates the TF-IDF weights for each pair of word and document
%       in a corpus.
%
%       Input arguments:
%       - C:        The word-count table of the corpus. Suppose there
%                   are V words and n documents, then the size of C is
%                   V x n.
%       
%       Output arguments:
%       - W:        The TF-IDF weight matrix, of size V x n.
%                   W(v, d) is the tf-idf weight of the word v in the
%                   d-th document.
%
%   W = TF_IDF_WEIGHT(C, 'normalize');
%       
%       Normalize the word-counts before calculating the TF-IDF weights.
%
%       Here, C will be first normalized, such that each column of C 
%       sums to one.
%
%   [W, idf] = TF_IDF_WEIGHT( ... );
%
%       additionally returns the IDF values, as a column vector of 
%       size V x 1.
%

% Created by Dahua Lin, on Feb 19, 2011
%

%% verify input arguments

if ~(isfloat(C) && isreal(C) && ismatrix(C))
    error('tf_idf_weight:invalidarg', 'C should be a real matrix.');
end

if nargin < 2
    to_normalize = 0;
else
    if ~(ischar(op) && strcmp(op, 'normalize'))
        error('tf_idf_weight:invalidarg', ...
            'The second argument can only be ''normalize''.');
    end
    to_normalize = 1;
end

%% main

if to_normalize
    C = bsxfun(@times, C, 1 ./ full(sum(C, 1)));
end

a = full(sum(C > 0, 2));
n = size(C, 2);

idf = log(n ./ a);
W = bsxfun(@times, C, idf);