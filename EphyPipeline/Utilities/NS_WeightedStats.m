function [dbXW_Mean, dbXW_VAR, dbXW_SEM] = NS_WeightedStats(dbXData, dbXWeight, inDim)
%[WeightedMean, WeightedVAR, WeightedSEM] = NS_WeightedStats(Data, Weight, Dim)
%Utility for the calculation of weighted mean and weighted SEM. Weights
%MUST be occurence weight (i.e. number of trials)
narginchk(2, 3);
if nargin < 3, inDim = 1; end

%Checks that the data and the weights have the same size and if dimension
%is properly formated
if mod(inDim, 1) ~= 0 || inDim <= 0; error('Dim must be a positive integer'); end
if numel(size(dbXData)) ~= numel(size(dbXWeight)), bl1FullDim = false;
elseif any(size(dbXData) ~= size(dbXWeight)), bl1FullDim = false; 
else, bl1FullDim = true; 
end
if ~bl1FullDim
    if numel(dbXWeight) ~= size(dbXData, inDim)
        error('inXWeight must be a matrix sized as dbXData or a vector with as many entry as in dbXData along inDim')
    else
        inNDim      = ndims(dbXData);
        in1PermIdx  = 1:inNDim;
        in1PermIdx(1) = inDim; in1PermIdx(inDim) = 1;
        dbXWeight   = permute(dbXWeight(:), in1PermIdx);
        in1RepIdx   = size(dbXData);
        in1RepIdx(inDim) = 1;
        dbXWeight   = repmat(dbXWeight, in1RepIdx);
    end
end

%Sets the weight of all the NaN entries of dbXData to NaN
dbXWeight(isnan(dbXData)) = NaN;

% Sets all the zero or negative weights to NaN 
dbXWeight(dbXWeight <= 0) = NaN;

%Gets the indices of the vectors along inDim where every thing is NaN. Use
%it to create a factor matrix which will be used to set those entries to
%NaN in the output (otherwise they will be zero since nansum([nan]) = 0);
blXNan  = sum(isnan(dbXWeight), inDim) == size(dbXWeight, inDim);
dbXFact = ones(size(blXNan));
dbXFact(blXNan) = NaN;

%Calculates the weighted average
inXRepDim   = ones(1, ndims(dbXData)); inXRepDim(inDim) = size(dbXData, inDim);
dbXWeigth   = dbXWeight./repmat(nansum(dbXWeight, inDim), inXRepDim);
dbXW_Mean   = nansum(dbXData .* dbXWeigth, inDim);
%Calculates the weighted variance and the weighted error of the mean 
dbXW_VAR    = nansum(dbXWeight .* ((dbXData - repmat(dbXW_Mean, inXRepDim)).^2), inDim)./(nansum(dbXWeight, inDim) - 1);
dbXW_SEM    = sqrt(dbXW_VAR .* nansum(dbXWeigth.^2, inDim));
% Converts vectors with zero weights to NaN
dbXW_Mean   = dbXW_Mean .* dbXFact;
dbXW_VAR    = dbXW_VAR .* dbXFact;
dbXW_SEM    = dbXW_SEM .* dbXFact;
