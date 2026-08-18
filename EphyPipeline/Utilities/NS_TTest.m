function dbXP = NS_TTest(dbX1, dbX2, inDim)
%Synopis:
%   DBXP = NS_TTest(DBX1, DBX2, INDIM)
%Utility computing the p-value of the difference between the means 
%of paired samples in the matrices DBX1 and DBX2 along the dimesion 
%INDIM (optional, default is 1).

%Checks optional arguments
narginchk(2, 3);
if nargin < 3, inDim = 1; end

%Checks the size of the sample matrices
if ndims(dbX1) ~= ndims(dbX2), error('dbX1 and dbX2 must have equal size'); end
if any(size(dbX1) ~= size(dbX2)), error('dbX1 and dbX2 must have equal size'); end

%Calculates the mean, var and number of observation of the difference
dbX 	= dbX1 - dbX2;
dbXMu 	= nanmean(dbX, inDim);
dbXVar 	= nanvar(dbX, [], inDim);
inXN 	= sum(~isnan(dbX), inDim);

%Caclulates the t-statistic
dbXT    = abs(dbXMu) ./ sqrt(dbXVar ./ inXN);

%Calculates the degree of freedom
dbXDF   = inXN - 1;

%Calculates the p-value (we multiply by 2 because the test is two tailed)
dbXP    = tcdf(dbXT, dbXDF, 'upper') .* 2; 
