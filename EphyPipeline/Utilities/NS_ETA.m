function [db2ETA, db2ETSD, inNEvt, db1Time] = NS_ETA(db2LFP, inSampleRate, in1EventIdx, db1WinSec, blCentered)
% Synopsis:
%   [DB2ET_AV, DB2ET_SD, INNEVT, DB1TIME] = NS_ETA(DB2LFP, INSAMPLERATE, IN1EVENTIDX, DB1WINSEC, [BLCENTERED]);
%
%Calculate the event triggered average DB2ET_AV and S.D. DB2ET_SD of the
%signal DB2LFP (a channel x time-sample matrix) sampled at INSAMPLERATE in
%a time window DB1WINSEC around the indices stored in the vector
%IN1EVENTIDX. If the optional variable BLCENTERED is set to 'true', the 
%event triggered average is centered on the event.

%Checks arguments
narginchk(4, 5);
if nargin < 5, blCentered = false; end

% Gets the size of the LFP
[inNChan, inNSample] = size(db2LFP);

% Defines the window
in1RelIdx      = round(inSampleRate * db1WinSec(1)) : ...
    round(inSampleRate .* db1WinSec(2));

% Return a time vector
db1Time = in1RelIdx ./ inSampleRate;

% Removes events if they are too close to the edge
bl1Rem              = in1EventIdx <= -in1RelIdx(1) | in1EventIdx >= inNSample - in1RelIdx(end);
in1EventIdx(bl1Rem) = [];
inNEvt              = length(in1EventIdx);

% Creates the ETA
[db2ETA, db2ETSD] = deal(nan(inNChan, length(in1RelIdx)));
for iChan = 1:inNChan
    db1Chan = db2LFP(iChan, :);
	if blCentered
		try
    	db2ETA(iChan, :)    = nanmean(db1Chan(in1EventIdx(:) + in1RelIdx) - db1Chan(in1EventIdx)', 1);
    	db2ETSD(iChan, :)   = nanstd(db1Chan(in1EventIdx(:) + in1RelIdx) - db1Chan(in1EventIdx)', [], 1);
		catch, keyboard, end
	else
    	db2ETA(iChan, :)    = nanmean(db1Chan(in1EventIdx(:) + in1RelIdx), 1);
    	db2ETSD(iChan, :)   = nanstd(db1Chan(in1EventIdx(:) + in1RelIdx), [], 1);
	end
end
    
% %Old code that tends to overload the memory
% db3LFP_ETA = nan(inNChan, length(in1RelIdx), inNEvt);
% for iEvt = 1:inNEvt
%     db3LFP_ETA(:, :, iEvt) = db2LFP(:, in1EventIdx(iEvt) + in1RelIdx);
% end
% db2ETA 	= nanmean(db3LFP_ETA, 3);
% db2ETSD = nanstd(db3LFP_ETA, [], 3);
