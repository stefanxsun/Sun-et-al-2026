function [dbXSW_Mean, dbXSW_SEM] = NS_DL_SemiWeightedStats(dbXMean, dbXSampVar, inDim)
%[DBXSW_MEAN, DBXSW_CI] = NS_DL_SemiWeightedStats(DBXMEAN, DBXSAMPVAR,
%[INDIM]) Returns the DerSimonian and Laird semiweighted estimator
%DBXSW_MEAN and 95 confidence interval DBXSW_CI of the population mean for
%aggregates measures (studies) whith means DBXMEAN, sampling variance
%DBXSAMPVAR and number of observations DBXN along the dimension INDIM.
%WARNING: uses implicit array expansion and won't work in versions of
%matlab anterior to 2016b
narginchk(2,3)

%Checks for optional arguments
if nargin < 3, inDim = 1; end

%Checks that the input is properly formated
if ndims(dbXMean) ~= ndims(dbXSampVar)
    error('dbXMean and dbXVar do not have the same number of dimenstions'); end 
if any(size(dbXMean) ~= size(dbXSampVar))
    error('dbXMean and dbXVar do not have the same number of dimenstions'); end
if ~ismember(inDim, 1:ndims(dbXMean))
    error('inDim is not a dimension of dbXMean'); end

%Calculates the sampling variance, the weights and the weighted mean
dbXWeight       = 1 ./ dbXSampVar;
dbXWeight(dbXWeight <= 0 | ~isfinite(dbXWeight)) = nan;
dbX_WgtMu       = nansum(dbXWeight .* dbXMean, inDim) ./ nansum(dbXWeight, inDim);

%Computes the overall sample size
inXMetaN = sum(isnan(dbXWeight), inDim);

%Computes the DerSimonian and Laird estimate of the between study variance
dbXNum  = max(0, nansum(dbXWeight .* (dbXMean - dbX_WgtMu) .^ 2, inDim) - (inXMetaN - 1));
dbTauSq = dbXNum ./ (nansum(dbXWeight, inDim) - (nansum(dbXWeight .^ 2, inDim) ./ nansum(dbXWeight, inDim)));

%Computes the semiweighted estimators and their standard error
dbXWeight   = 1./(dbXSampVar + dbTauSq);
dbXWeight(dbXWeight <= 0 | ~isfinite(dbXWeight)) = nan;
dbXSW_Mean  = nansum(dbXWeight .* dbXMean, inDim) ./ nansum(dbXWeight, inDim);
dbXSW_SEM   = sqrt(1./nansum(dbXWeight, inDim));