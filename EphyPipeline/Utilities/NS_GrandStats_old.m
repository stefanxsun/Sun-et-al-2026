function [dbXGrandAv, dbXGrandVar] = NS_GrandStats(dbXMean, dbXVar, in1N, inDim)
%[DBXGRANDAV, DBXGRANDVAR] = NS_GrandStats(DBXMEAN, DBXVAR, IN1N, INDIM)
%
%Utility to compute the grand average DBXGRANDAV and the grand variance
%DBXGRANDVARof a population that is divided in subpopulation for which the
%mean DBXMEAN, the variance DBXVAR and the number of observations IN1N are
%known. Calculation are made along dimension INDIM.
%

% if ~ismember(inDim, 1:ndims(dbXVar))
%     error('inDim is not a dimension of dbXMean'); end
if isempty(dbXMean) & isempty(dbXVar) & isempty(in1N)
    dbXGrandAv = []; dbXGrandVar = []; return; 
end
if length(in1N) ~= numel(in1N), error('in1N must be a vector'); end
if length(in1N(:)) ~= size(dbXMean, inDim)
    error('in1N does not have the proper number of elements'); end

%Nakes sure that db1N is spread along the proper dimension
in1DShift  = 1:ndims(dbXMean); in1DShift(inDim) = 1; in1DShift(1) = inDim;
in1N = permute(in1N(:), in1DShift);

%Calculates the grand average
dbXGrandAv = nansum(dbXMean .* in1N, inDim)./nansum(in1N);
if nargout < 2; return; end

%Checks that the input is properly formated
if ndims(dbXMean) ~= ndims(dbXVar)
    error('dbXMean and dbXVar do not have the same number of dimenstions'); end 
if any(size(dbXMean) ~= size(dbXVar))
    error('dbXMean and dbXVar do not have the same number of dimenstions'); end

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
    
SSTPs = ((in1N - 1) .* dbXVar) + (in1N  .* ((dbXMean - dbXGrandAv).^2));
dbXGrandVar = nansum(SSTPs, inDim) ./ (nansum(in1N) - 1); % i.e.: SST / (N - 1)