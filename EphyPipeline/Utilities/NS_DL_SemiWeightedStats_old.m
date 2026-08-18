function [dbXSW_Mean, dbXSW_SEM] = NS_DL_SemiWeightedStats(dbXMean, dbXVar, db1N, inDim)
%[DBXSW_MEAN, DBXSW_CI] = NS_DL_SemiWeightedStats(DBXMEAN, DBXVAR, DBXN,
%[INDIM]) Returns the DerSimonian and Laird semiweighted estimator
%DBXSW_MEAN and 95 confidence interval DBXSW_CI of the population mean for
%aggregates measures (studies) whith means DBXMEAN, sample variance DBXVAR
%and number of observations DBXN along the dimension INDIM.
%WARNING: uses implicit array expansion and won't work in versions of
%matlab anterior to 2016b
narginchk(3,4)

%Checks for optional arguments
if nargin < 4, inDim = 1; end

%Checks that the input is properly formated
if ndims(dbXMean) ~= ndims(dbXVar)
    error('dbXMean and dbXVar do not have the same number of dimenstions'); end 
if any(size(dbXMean) ~= size(dbXVar))
    error('dbXMean and dbXVar do not have the same number of dimenstions'); end
if ~ismember(inDim, 1:ndims(dbXMean))
    error('inDim is not a dimension of dbXMean'); end
if ~isvector(db1N); error('db1N must be a vector'); end
if length(db1N) ~= size(dbXMean, inDim)
    error('db1N does not have the proper number of elements'); end

%Nakes sure that db1N is spread along the proper dimension
in1DShift  = 1:ndims(dbXMean); in1DShift(inDim) = 1; in1DShift(1) = inDim;
db1N = permute(db1N(:), in1DShift);
in1MetaN = length(db1N);

%Calculates the sampling variance, the weights and the weighted mean
dbXSamplingVar  = dbXVar ./ db1N;
dbXWeight       = 1 ./ dbXSamplingVar;
dbX_WgtMu       = nansum(dbXWeight .* dbXMean, inDim) ./ nansum(dbXWeight, inDim);

%Computes the DerSimonian and Laird estimate of the between study variance
dbXNum  = nansum(dbXWeight .* (dbXMean - dbX_WgtMu) .^ 2, inDim) - (in1MetaN - 1);
dbTauSq = dbXNum ./ (nansum(dbXWeight, inDim) - nansum(dbXWeight .^ 2, inDim) ./ nansum(dbXWeight, inDim));
dbTauSq(dbTauSq <0 | isnan(dbTauSq)) = 0;

%Computes the semiweighted estimators and their standard error
dbXWeight   = 1./(dbXSamplingVar + dbTauSq);
dbXSW_Mean  = nansum(dbXWeight .* dbXMean, inDim) ./ nansum(dbXWeight, inDim);
dbXSW_SEM   = sqrt(1./nansum(dbXWeight, inDim));