function [varargout] = VEHA_L0_PreProcessWheelRotation(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Sets the source path
chSourcePath = fullfile(sREC.chNlxSessionPath, sREC.chNlxSessionDir);
if ~exist(fullfile(chSourcePath, sREC.chWheelChan), 'file')
    error('%s is missing from the source directory\r', sREC.chWheelChan)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L0_PreProcessWheelRotation';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
chDestFolder = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chDestFolder)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chDestFolder);
end
chDestFile = 'VEHA_L0_PreProcessWheelRotation.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chDestFolder));
    return
else
    fprintf('Processing %s ...', chDestFolder);
end

%Defines the range for the recording, extracts and interpolates the timestamps and extracts the sampling rate
[TStamps, Header] = Nlx2MatCSC(fullfile(chSourcePath, sREC.chWheelChan), [1 0 0 0 0], 1, 1); % Windows
TStamps = NS_TStampSanityCheck(TStamps); %%%% STEFAN ADDED to fix the jitter from Neuralynx 08/07/2023
% [TStamps, Header] = Nlx2MatCSC_v3(fullfile(chSourcePath, sREC.chWheelChan), [1 0 0 0 0], 1, 1); % Linux Mac
[in1BegPts, in1EndPts, inCells] = NS_DoDefineContinuousRecording(TStamps);
in1Range=[in1BegPts(sREC.inRecNum), in1EndPts(sREC.inRecNum)];

TStamps = TStamps(in1Range(1):in1Range(2));
db1TStampsInterval = linspace(0, round(mean(diff(TStamps))), 513);  %% Stefan edited 08/07/2023 to use mean of diff instead of diff of (4)-(3)
db1TStamps = repmat(db1TStampsInterval(1:512)', 1, length(TStamps)) + repmat(TStamps, 512, 1);
db1TStamps = db1TStamps(1:end);

sHEADER = NS_ReadHeader(Header);
inSampleRate = sHEADER.SamplingFrequency;

%Extract te wheel rotation trace
[TSRec, Samples, Header] = Nlx2MatCSC(fullfile(chSourcePath, sREC.chWheelChan) , [1 0 0 0 1], 1, 2, in1Range); % Windows
% [TSRec, Samples, Header] = Nlx2MatCSC_v3(fullfile(chSourcePath, sREC.chWheelChan) , [1 0 0 0 1], 1, 2, in1Range-1); % Mac Linux
if length(TSRec) ~= length(TStamps)
    bl1Sel = ismember(TSRec, TStamps);
    if sum(bl1Sel) ~= length(TStamps); error('TStamps could not be matched'); end
    Samples = Samples(:, bl1Sel);
end

%sets the parameters for downsampling and downsamples everything
inOutputSampleRate = sCFG.sPARAM.inOutputSampleRate;
inDownSamplingFactor = inSampleRate/inOutputSampleRate;
if mod(inDownSamplingFactor, 1)~=0
    error('The sampling rate is not a direct multiple of the output sampling rate')
end
db1WheelRot = NS_DownSampleTrace(Samples(1:end), inDownSamplingFactor);
db1TStamps = NS_DownSampleTrace(db1TStamps, inDownSamplingFactor);

%checks that the value of the voltage trace are not superior to the signal
%range and adjust the signal range if needed
if strcmp(sREC.chWheelDirection, 'backward')
   sCFG.sPARAM.db1WheelVRange = [-sCFG.sPARAM.db1WheelVRange(2) -sCFG.sPARAM.db1WheelVRange(1)];
end
db1Range = [min(db1WheelRot) max(db1WheelRot)];
db1WheelVRange = [min([db1Range(1), sCFG.sPARAM.db1WheelVRange(1)]) ...
    max([db1Range(2), sCFG.sPARAM.db1WheelVRange(2)])];

%Express wheel rotation in radian and corrects for the smoothing of phase
%transition comming from experimental smoothing
db1WheelRotRad = (((db1WheelRot - db1WheelVRange(1))/range(db1WheelVRange))*2*pi) - pi;

%Inverses the trace if the wheel rotates backward
if strcmp(sREC.chWheelDirection, 'backward')
    db1WheelRotRad = -db1WheelRotRad;
end

%Finds the area whre the wheel rotation resets
bl1Reversal = abs(diff(db1WheelRotRad)) > 0.1;
in1BegPt = find(diff(bl1Reversal) == 1); in1EndPt = find(diff(bl1Reversal) == -1);

%Makes sure than beginning are always followed by an end
if ~isempty(in1BegPt)
    if in1BegPt(1) > in1EndPt(1); in1EndPt(1) = []; end
    if in1BegPt(end) > in1EndPt(end); in1BegPt(end) = []; end
end

for i = 1:length(in1BegPt)
    inAntBegPt = max(in1BegPt(i) - round(0.025 * inOutputSampleRate), 1);
    [dummy, inMaxIdx] = max(db1WheelRotRad(inAntBegPt:in1BegPt(i))); 
    in1BegPt(i) = inMaxIdx - 1 + inAntBegPt; %point right after the max
    inPostEndPt = min(in1EndPt(i) + round(0.025 * inOutputSampleRate), length(db1WheelRotRad));
    [dummy, inMinIdx] = min(db1WheelRotRad(in1EndPt(i):inPostEndPt)); 
    in1EndPt(i) = inMinIdx - 1 + in1EndPt(i); %point right befor the max
end

in1MidPt = round(mean([in1BegPt; in1EndPt]));

for i = 1:length(in1BegPt)
    db1WheelRotRad(in1BegPt(i):in1MidPt(i)) = pi*sign(db1WheelRotRad(in1BegPt(i)));
    db1WheelRotRad(in1MidPt(i)+1:in1EndPt(i)) = pi*sign(db1WheelRotRad(in1EndPt(i)));
end

%Unwraps the phase and normalize by diameter to express running distance
db1WheelDist = (unwrap(db1WheelRotRad));
db1RunDistM = (db1WheelDist - db1WheelDist(1) / pi) * sCFG.sPARAM.dbWheelDiameterM; %in meters
if db1RunDistM(end) < db1RunDistM(1)
    db1RunDistM = - db1RunDistM; %Puts the signal back in the right sense if it is inverted
end

%Computes the speed by smoothing the differential of the distance
db1Win = gausswin(inOutputSampleRate*0.5); %for a smoothing of half a millisecond
db1SpeedMpS = conv(diff(db1RunDistM)*inOutputSampleRate, db1Win, 'same')/sum(db1Win); %speed in meters per second
db1SpeedMpS = [db1SpeedMpS db1SpeedMpS(end)];

% plots the result for the purpose of debugging (uncomment if needed)
% figure, ax(1) = subplot(3, 1, 1); plot(db1WheelRotRad), ax(2) = subplot(3, 1, 2); plot(db1RunDistM), ax(3) = subplot(3, 1, 3); plot(db1SpeedMpS)
% linkaxes(ax, 'x')

%Update sREC
sCFG.sREC = sREC;

% Writes the output in CFG
sCFG.sL0PPWR.db1WheelRotRad = db1WheelRotRad;
sCFG.sL0PPWR.db1RunDist = db1RunDistM;
sCFG.sL0PPWR.db1SpeedMpS = db1SpeedMpS;
sCFG.sL0PPWR.db1TStamps = db1TStamps;
sCFG.sL0PPWR.inOutputSampleRate = inOutputSampleRate;
sCFG.sL0PPWR.chScriptName = mfilename('fullpath');
sCFG.sL0PPWR.chTimeComputed = datestr(now);

% Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')