function [z,mu,sigma] = nanzscore(x,flag,dim)
%NANZSCORE Standardized z score removint nan.
%   Z = NANZSCORE(X) returns a centered, scaled version of X, the same size
%   as X. For vector input X, Z is the vector of z-scores (X-MEAN(X)) ./
%   STD(X). For matrix X, z-scores are computed using the mean and standard
%   deviation along each column of X.  For higher-dimensional arrays,
%   z-scores are computed using the mean and standard deviation along the
%   first non-singleton dimension.
%
%   The columns of Z have sample mean zero and sample standard deviation
%   one (unless a column of X is constant, in which case that column of Z
%   is constant at 0).
%
%   [Z,MU,SIGMA] = NANZSCORE(X) also returns NANMEAN(X) in MU and NANSTD(X)
%   in SIGMA.
%
%   [...] = NANZSCORE(X,1) normalizes X using NANSTD(X,1), i.e., by
%   computing the standard deviation(s) using N rather than N-1, where N is
%   the length of the dimension along which NANZSCORE works.
%   NANZSCORE(X,0) is the same as NANZSCORE(X).
%
%   [...] = NANZSCORE(X,FLAG,DIM) standardizes X by working along the
%   dimension DIM of X. Pass in FLAG==0 to use the default normalization by
%   N-1, or 1 to use N.
%
%   See also NANMEAN, NANSTD.

%   Copyright 1993-2015 The MathWorks, Inc. Quentin Perrenoud 2018-11-06
%   adapted from zscore

% [] is a special case for std and mean, just handle it out here.
if isequal(x,[]), z = x; return; end

if nargin < 2
    flag = 0;
end
if nargin < 3
    % Figure out which dimension to work along.
    dim = find(size(x) ~= 1, 1);
    if isempty(dim), dim = 1; end
end

% Compute X's mean and sd, and standardize it
mu = nanmean(x, dim);
sigma = nanstd(x, flag, dim);
sigma0 = sigma;
sigma0(sigma0==0) = 1;
z = bsxfun(@minus, x, mu);
z = bsxfun(@rdivide, z, sigma0);