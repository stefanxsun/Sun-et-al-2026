function dbXPOut = NS_FisherMethod(dbXPIn, inDim)
%DXBP = NS_FisherMethod(DBXP, INDIM)
%Evalutates the overall significance DXBP of a group of p-values DBXP using
%Fisher's method along dimension INDIM (optional, default is 1);

% Checks for optional arguments
narginchk(1, 2);
if ~exist('inDim', 'var'), inDim = 1; end

% Checks for NaNs.
if any(isnan(dbXPIn(:)))
    warning('db1P contains NaN values\r');
end

% Calculates aggregate p-value;
dbXChi  = -2 * nansum(log(dbXPIn), inDim);
dbXPOut = 1 - chi2cdf(dbXChi, 2 * sum(~isnan(dbXPIn), inDim)); 
dbXPOut(all(isnan(dbXPIn), inDim)) = NaN;
