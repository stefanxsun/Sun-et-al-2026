function [dbxDPrime, dbxCrit] = NS_DPrime(dbxHitR, dbxFAR)
% Synopsis:
%   [DBXDPRIME, DBXCRIT] = NS_DPRIME(DBXHITR, DBXFAR)
% Returns d' and criterions matrices calculated using the z-transform of
% the input matrix DBDHITR and DBXFAR. The z-transform is the inverse
% cumulative normal distribution.

% Check that both input matrix are the same size and bounded between zero
% and 1
if numel(size(dbxHitR)) ~= length(size(dbxFAR)), error('dbxHitRate and dbxFAR must have the same size');
elseif any(size(dbxHitR) ~= size(dbxFAR)), error('dbxHitRate and dbxFAR must have the same size'); end
if any(dbxHitR(:))  > 1 | any(dbxHitR(:)) < 0; error('dbxHitR must be bounded between 0 and 1'); end
if any(dbxFAR(:))  > 1 | any(dbxFAR(:)) < 0; error('dbxFAR must be bounded between 0 and 1'); end

% Sets 1 to .99 and 0 to .01 to avoid infinity in the z-transform
dbxHitR(dbxHitR < .01) = .01;
dbxHitR(dbxHitR > .99) = .99;
dbxFAR(dbxFAR < .01) = .01;
dbxFAR(dbxFAR > .99) = .99;

% Calculte the z-transfrom
dbxZ_Hit    = norminv(dbxHitR);
dbxZ_FAR    = norminv(dbxFAR);

% Calculates d' and criterion
dbxDPrime   = dbxZ_Hit - dbxZ_FAR;
dbxCrit     = -(dbxZ_Hit + dbxZ_FAR)/2;