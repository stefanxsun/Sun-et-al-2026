function [dbXSum, dbXSumVar] = NS_JackKnifeNormSum(dbXValue, inDim, blNorm)
%Synopsis:
%	[DBXSUM, DBXSUMVAR] = NS_JackKnifeNormSum(DBXVALUE, INDIM, BLNORM)
%Computes the normalized sum DBXSUM and variance DBXSUMVAR for the values in 
%DBXVALUE along dimension INDIM. The variance is calculated in each bin by 
%removing the contribution of each plane in DBXVALUE with a leave one out 
%Jackknife approach. The optional boolean BLNORM determine if the sum is 
%normalized by total of the values is DBXVALUE. Default is true.

%Checks the input
narginchk(1, 3);
if nargin < 2, inDim = 1; end
if nargin < 3, blNorm = true; end
inNDims = ndims(dbXValue);
if inDim > inNDims;
	error('inDim must be a dimension of dbXValue');
end

%Compute the sum
dbXSum = DoNormSum(dbXValue, inDim, blNorm);

%Computes the number of planes to sum
inNGp = size(dbXValue, inDim);

%Computes histogram variance
if inNGp == 1
	%If there is only one group returns a zero variance
	dbXSumVar	 = zeros(size(db1H));
else
	%Else computes the histogram while removing each group
	dbXSum_Jck = zeros(size(dbXValue));
	cIDX = repmat({':'}, 1, inNDims);
	for iGp = 1:inNGp
		cIDX{inDim} = iGp;
		dbXVal_Jck 	= dbXValue;
		dbXVal_Jck(cIDX{:}) = [];
		dbXSum_Jck(cIDX{:}) = DoNormSum(dbXVal_Jck, inDim, blNorm);
	end
	%Then computes the variance with a JackKnife procedure
	dbXSumVar = ((inNGp - 1) / inNGp) .* sum((dbXSum_Jck - dbXSum) .^ 2, inDim);
end

function dbXSum = DoNormSum(dbXValue, inDim, blNorm);
dbXSum = nansum(dbXValue, inDim);
if blNorm, dbXSum = dbXSum ./ nansum(dbXValue(:)); end
