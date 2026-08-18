function [dbXGrandAv, dbXGrandVar] = NS_GrandStats(dbXMean, dbXVar, inXN, inDim)
%[DBXGRANDAV, DBXGRANDVAR] = NS_GrandStats(DBXMEAN, DBXVAR, INXN, INDIM)
%
%Utility to compute the grand average DBXGRANDAV and the grand variance
%DBXGRANDVARof a population that is divided in subpopulation for which the
%mean DBXMEAN, the variance DBXVAR and the number of observations INXN are
%known. Calculation are made along dimension INDIM.
%

% if ~ismember(inDim, 1:ndims(dbXVar))
%     error('inDim is not a dimension of dbXMean'); end
if isempty(dbXMean) & isempty(dbXVar) & isempty(inXN)
    dbXGrandAv = []; dbXGrandVar = []; return; 
end

%Checks that the input is properly formated
if ndims(dbXMean) ~= ndims(dbXVar)
    error('dbXMean and dbXVar must have the same size'); end 
if any(size(dbXMean) ~= size(dbXVar))
    error('dbXMean and dbXVar must have the same size'); end
blVec = sum(size(inXN) ~= 1) <= 1;
if ~blVec
    if ndims(dbXMean) ~= ndims(inXN)
        error('in1N must have the same size as dbXMean or be a vector with the same number of elements along inDim'); end 
    if any(size(dbXMean) ~= size(inXN))
        error('in1N must have the same size as dbXMean or be a vector with the same number of elements along inDim'); end
else
    if length(inXN) ~= numel(inXN), error('in1N must have the same size as dbXMean or be a vector with the same number of elements along inDim'); end
    if length(inXN(:)) ~= size(dbXMean, inDim)
        error('in1N must have the same size as dbXMean or be a vector with the same number of elements along inDim'); end
end

%Nakes sure that db1N is spread along the proper dimension
if blVec
    in1DShift  = 1:ndims(dbXMean); in1DShift(inDim) = 1; in1DShift(1) = inDim;
    inXN = permute(inXN(:), in1DShift);
end

%Calculates the grand average
dbXGrandAv = nansum(dbXMean .* inXN, inDim)./nansum(inXN, inDim);
if nargout < 2; return; end

%Calculates the grand variance:
    %Explanation: 
    % GrandVar = SST / (N - 1)
    % Where SST: Sum of the squared deviation to the grandmean of each observation
    %       N: Total number of observation
    % SST = SST1 + SST2 + ... STTN
    % Where SSTP = The sum of the squared deviation to the grandmean of
    % observations in subset P.
    % It can be shown that SSTP = (Np - 1) * VARp + Np*(Avp - grandmean).^2
    % Where Np: Observations in subset P
    %       VARp: Sample variance of subset P
    %       Avp: Sample mean of subset P
    
SSTPs = ((inXN - 1) .* dbXVar) + (inXN  .* ((dbXMean - dbXGrandAv).^2));
dbXGrandVar = nansum(SSTPs, inDim) ./ (nansum(inXN, inDim) - 1); % i.e.: SST / (N - 1)