function [in1BOn, in1BOff, db1BDur, db1Amp, db1Phase] = NS_LFPBout(db2LFP, inSampleRate, db1Band, dbQThr, inMinCycle)
% [INBON, INBOFF, [DB1DUR], [DB1AMP], [DB1PHASE]] = NS_LFPBout(DB2LFP, INSAMPLERATE, DB1BAND, [DBQTHR], [INMINCYCLE])
% Utilities computing bouts of activity in the range DB1BAND, in the
% multichannel LFP matrix DB2LFP representing an LFP signal sampled at
% INSAMPLERATE.
% Inputs:
%   -DB2LFP: a 2d matrix representing LFP signal in distinct channels. The
%   highest dimension is assumed to be the samples and the lowest is
%   assumed to be the channels.
%   -INSAMPLERATE: the sampling rate of DB2LFP.
%   -DB1BAND: A 2 element vector defining the band of interest in HZ
%   (example: [25 35] for 25Hz to 35Hz.
%   -DB1QTHR (optional): threshold of amplitude (expressed in cumulative
%   probability) that needs to be exceeded to be considered in a bout
%   (default: .8)
%   -INMINCYCLE (optional): Minimum number of cycle that a bout must to
%   have to be kept (default: 1)
% Outputs:
%   -IN1BON: vector of the indices of the onset of bouts
%   -IN1BOFF: vector of the indices of the offset of bouts
%   -DB1BDUR: vector indicating the duration of bouts in cycles
%   -DB1AMP: Amplitude of the hilbert transform of the last channel of db2LFP
%   -DB1PHASE: Phase of the hilbert transform of the last channel fo db2LFP

%Makes sure that the LFP is formated (sample x channels). The samples are
%supposed to be more numerous than the channels.
db1Size = size(db2LFP);
if diff(db1Size) > 0; db2LFP = db2LFP'; end

%Sets optional parameters if needed
if nargin < 4, dbQThr = .8; end
if nargin < 5, inMinCycle = 1; end

%Defines the filter
[B1, A1]    = butter(2, 2*db1Band/inSampleRate); %Low pass for regular CSD

% -------------------------------------------------------------------------
% % Filters the LFP in the low gamma range and computes its hilbert transform
% % to extracts its amplitude and phase
% db2LFP_filt = filtfilt(B1, A1, db2LFP); %Removes the first channel and transpose to filter and take the hilbert
% cp2LFP_Hil  = hilbert(db2LFP_filt);
% db2Amp      = abs(cp2LFP_Hil); %Gets the amplitude envelope,
% % db2Phase    = unwrap(angle(mean(cp2LFP_Hil, 2)))/pi; %Unwrapped average phase accross channel expressed in cycles
% db2Phase    = unwrap(angle(cp2LFP_Hil(:, end)))/pi; %Alternatively: unwrapped average phase of the deepest channel expressed in cycles

% % Plots things
% dbSpace = 1.2 * max(range(db2Amp));
% in2PltY = repmat((1:size(db2Amp, 2)) * dbSpace, size(db2Amp, 1), 1);
% figure, plot(db2Amp + in2PltY, 'k');

% Looks for bouts on all single trace than computes an accross channel bout
% vector set to true when a bout is present on any channel
% bl2Bout = false(size(db2Amp));
% for iChan = 1:size(db2Amp, 2)
%     dbThr   = quantile(db2Amp(:, iChan), dbQThr);
%     bl2Bout(:, iChan) = db2Amp(:, iChan) > dbThr;
% end
% % bl1Bout = logical(sum(bl2Bout, 2));
% bl1Bout = sum(bl2Bout, 2) > size(db2Amp, 2) * 0.5;

% -------------------------------------------------------------------------
% Alternatively only looks at the last channel which is generally where the
% LFP is strongest

% Filters the LFP in the low gamma range and computes its hilbert transform
% to extracts its amplitude and phase
db1LFP_filt = filtfilt(B1, A1, db2LFP(:, end)); %Removes the first channel and transpose to filter and take the hilbert
cp1LFP_Hil  = hilbert(db1LFP_filt);
db1Amp      = abs(cp1LFP_Hil); %Gets the amplitude envelope,
db1Phase    = angle(cp1LFP_Hil);
db1Cycles   = unwrap(db1Phase)./(2 * pi); %Alternatively: unwrapped average phase of the deepest channel expressed in cycles
dbThr       = quantile(db1Amp, dbQThr);
bl1Bout     = db1Amp > dbThr;
    
% Computes the statistics of bouts
in1BOn  = find(diff([0 ; bl1Bout]) == 1);
in1BOff = find(diff([bl1Bout; 0]) == -1);
db1BDur = db1Cycles(in1BOff) - db1Cycles(in1BOn); % Duration of the bouts in cycles
bl1Excl = db1BDur < inMinCycle; % Exclude bouts that are under the minum cycle duration
in1BOn(bl1Excl) = []; in1BOff(bl1Excl) = []; db1BDur(bl1Excl) = [];
% bl1Bout = NS_MakeEpochVector(in1BOn, in1BOff, size(db2Amp, 1));