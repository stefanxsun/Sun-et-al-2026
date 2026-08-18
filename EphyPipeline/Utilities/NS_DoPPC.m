function [db2PPC, varargout] = NS_DoPPC(cp3SpikeSTR, varargin)
%[DB1PPC, [DB1PPCVAR]] = NS_DoPPC(CP3SPIKESTR, [DB1SPIKEGROUP]) computes
%the pairwise phase consistency(1) of the input matrix CP3SPIKESTR. The
%computation uses the fact that cos(a1 - a2) + cos(a1 - a3) + ... cos(aN-1
%- aN) = 2 * ((cos(a1) + cos(a2) + ... + cos(aN))^2 + (sin(a1) + sin(a2) +
%... + sin(aN))^2 - N) to solve the problem in polynomial time instead of
%exponential time. 
%Input:
%   -CP3SPIKESTR: a complex valued matrix of the spectrotemporal
%   representation of spikes for particular freqency bands and particular
%   channels organized as (spike x freq x channel) 
%   -DB1SPIKEGROUP (optional): a vector assigning each spike a group value
%   to derive the confindence interval (C.I) of the estimate with a
%   jackkife procedure. The group value should be numerical. If not
%   provided, the C.I. is estimate by leaving each spike out (each spike is
%   its own group).
%Output:
%   -DB2PPC: a real valued matrix of the ppc organized as (freq x channel)
%   -DB2PPCVAR: a real valued matrix of the variance of ppc estimates
%   derived whith a jackknife procedure and organized as (freq x channel)
%
%(1): Vinck M, van Wingerden M, Womelsdorf T, Fries P, Pennartz CM. The
%pairwise phase consistency: a bias-free measure of rhythmic neuronal
%synchronization. Neuroimage. 2010

%Quentin Perrenoud: 2017/02/21, last modified: 2018/08/28

nargoutchk(0, 2); narginchk(1, 2);

if nargout > 1 && nargin > 1
    db1SpikeGroup   = varargin{1}(:);
    if numel(db1SpikeGroup) ~= size(cp3SpikeSTR, 1); error('Spikes and spike group assignment do not have the same number of entries'); end
end

inNSpk      = size(cp3SpikeSTR, 1);
if inNSpk == 0
    disp('No spikes')
    db2PPC = NaN;
    if nargout > 1
        varargout{1} = NaN;
    end
elseif inNSpk < 2
    disp('PPC cannot be computed with less then 2 spikes')                  
    db2PPC = nan([size(cp3SpikeSTR, 2) size(cp3SpikeSTR, 3)]);
    if nargout > 1
        varargout{1} = nan([size(cp3SpikeSTR, 2) size(cp3SpikeSTR, 3)]);
    end
else
    cp3NormSTR  = cp3SpikeSTR ./ abs(cp3SpikeSTR); %the real and complex part of the normalized input value correspond to the cos and sin of the phase
    cp2SumSTR   = nansum(cp3NormSTR); % Sums the cos and sin
    db2PPC      = (cp2SumSTR .* conj(cp2SumSTR) - inNSpk) / (inNSpk * (inNSpk - 1)); %It can be shown algebraically that PPC is equal to that
    
    if nargout > 1
        if nargin > 1
%             db1SpikeGroup   = varargin{1}(:);
            db1USpkGp       = unique(db1SpikeGroup);
            inNGp           = length(db1USpkGp);
            db3PPCLOO       = complex(nan(inNGp, size(cp3SpikeSTR, 2), size(cp3SpikeSTR, 3)));
            for iGp = 1:inNGp
                bl1Spk = db1SpikeGroup ~= db1USpkGp(iGp);
                inNSpk = sum(bl1Spk);
                cp2SumSTRLOO = nansum(cp3NormSTR(bl1Spk, :, :));
                db3PPCLOO(iGp, 1, 1) = (cp2SumSTRLOO .* conj(cp2SumSTRLOO) - inNSpk) / (inNSpk * (inNSpk - 1));
            end
        else
            cp3SumSTRLOO    = repmat(cp2SumSTR, inNSpk, 1, 1) - cp3NormSTR; %removes the contribution of each spike to the sum (LOO: Leave One Out)
            db3PPCLOO       = (cp3SumSTRLOO .* conj(cp3SumSTRLOO) - (inNSpk - 1)) / ((inNSpk - 1) * (inNSpk - 2)); %computes PPC for each spike removal
            inNGp           = inNSpk;
        end
        db3DSqr_PPCLOO  = (db3PPCLOO - repmat(db2PPC, inNGp, 1, 1)) .^ 2; %Computes the squared difference of the estimate of each spike removal
        db2PPCVar       = (inNGp - 1) * nansum(db3DSqr_PPCLOO) / inNGp; %Estimate the variance of the estimate with a jacknife
        varargout{1}    = reshape(db2PPCVar, [size(cp3SpikeSTR, 2) size(cp3SpikeSTR, 3)]); %Removes singualar dimensions
    end
    
    db2PPC      = reshape(db2PPC, [size(cp3SpikeSTR, 2) size(cp3SpikeSTR, 3)]); %Removes singualar dimensions
end