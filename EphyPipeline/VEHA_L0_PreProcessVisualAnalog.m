function [varargout] = VEHA_L0_PreProcessVisualAnalog(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Sets the source path
chSourcePath = fullfile(sREC.chNlxSessionPath, sREC.chNlxSessionDir);
if ~exist(fullfile(chSourcePath, sREC.cVISUALCHAN{1}), 'file')
    error('%s is missing from the source directory\r', sREC.cVISUALCHAN{1})
end

switch sREC.chDisplayScreenLuminance
    case 'high'
        blLowLum = false;
    case 'low'
        blLowLum = true;
    otherwise
        error('The value of chDisplayScreenLuminance was not recognized')
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L0_PreProcessVisualAnalog';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
chDestFolder = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chDestFolder)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chDestFolder);
end
chDestFile = 'VEHA_L0_PreProcessVisualAnalog.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chDestFolder));
    return
else
    fprintf('Processing %s ...', chDestFolder);
end

%Defines the range for the recording, extracts and interpolates the timestamps and extracts the sampling rate
[TStamps, Header] = Nlx2MatCSC(fullfile(chSourcePath, sREC.cVISUALCHAN{1}), [1 0 0 0 0], 1, 1); % Windows
TStamps = NS_TStampSanityCheck(TStamps); %%%% STEFAN ADDED to fix the jitter from Neuralynx 08/07/2023
[in1BegPts, in1EndPts, inCells] = NS_DoDefineContinuousRecording(TStamps);
if strcmp(chDestFolder, '2022-02-25_12-13-46_1'), in1BegPts = in1BegPts(1); in1EndPts = in1EndPts(end); end
in1Range=[in1BegPts(sREC.inRecNum), in1EndPts(sREC.inRecNum)];

%Sets the downsampling parameters
sHEADER = NS_ReadHeader(Header);
inSampleRate = sHEADER.SamplingFrequency;
inDSFactor = round(inSampleRate/sCFG.sPARAM.inWorkingSamplingRate);

TStamps = TStamps(in1Range(1):in1Range(2));
db1TStampsInterval = linspace(0, round(mean(diff(TStamps))), 513);  %% Stefan edited 08/07/2023 to use mean of diff instead of diff of (4)-(3)
db1TStamps = repmat(db1TStampsInterval(1:512)', 1, length(TStamps)) + repmat(TStamps, 512, 1);
db1TStamps = NS_DownSampleTrace(db1TStamps(1:end), inDSFactor);

%Extract and downsamples the visual analog
[TSRec, Samples, Header] = Nlx2MatCSC(fullfile(chSourcePath, sREC.cVISUALCHAN{1}) , [1 0 0 0 1], 1, 2, in1Range); % Windows
% [TSRec, Samples, Header] = Nlx2MatCSC_v3(fullfile(chSourcePath, sREC.cVISUALCHAN{1}) , [1 0 0 0 1], 1, 2, in1Range-1); % Mac Linux
if length(TSRec) ~= length(TStamps)
    bl1Sel = ismember(TSRec, TStamps);
    if sum(bl1Sel) ~= length(TStamps); error('TStamps could not be matched'); end
    Samples = Samples(:, bl1Sel);
end
db1VAnalog = NS_DownSampleTrace(Samples(1:end), inDSFactor);

%If visuals were displayed at low luminance, the visual analog oscillates
%at ~330Hz. The signal needs to be averaged over each cycle. The following
%part does that.
if blLowLum
    inLComp = sCFG.sPARAM.inWorkingSamplingRate/1000; %empirical, works well this way
    
    %Takes the differential of the analog signals
    db1VDAnalog = diff(db1VAnalog);
    
    %Defines the beginning of the frames as points preceeded by inLComp
    %steps 80% of which decreasing and followed by inLComp steps 80% of
    %which increasing
    in2Idx = repmat(1:length(db1VDAnalog)- (inLComp - 1), inLComp, 1) + repmat((0: inLComp - 1)', 1, length(db1VDAnalog)-(inLComp - 1));
    db1MovSumDiffSign = sum(sign(db1VDAnalog(in2Idx)));
    in1FrameBegIdx = inLComp + find(db1MovSumDiffSign(1:end - inLComp) < -inLComp*0.8 & db1MovSumDiffSign(inLComp + 1 :end) > inLComp*0.8);
    
    %Correcting for errors
    %Removes false positives (points that are at a shorter time intervals)
    db1ZDFrameBeg = zscore(diff(in1FrameBegIdx));
    in1FalsPos = find((db1ZDFrameBeg(1:end -1) < -2 | db1ZDFrameBeg(1:end -1) > 2) & (db1ZDFrameBeg(2:end) < -2 | db1ZDFrameBeg(2:end) > 2)) + 1;
%     in1FPFrameBegIdx = in1FrameBegIdx(in1FalsPos); %for plotting purpose
    in1FrameBegIdx(in1FalsPos) = [];
    
    %Interpolates missing points
    db1DFrameBeg = diff(in1FrameBegIdx);
    dbMeanDFrameBeg = nanmean(db1DFrameBeg);
    db1ZDFrameBeg = zscore(db1DFrameBeg);
    inMultiFrame = find(db1ZDFrameBeg > 2);
    in1MFFrameBegIdx = in1FrameBegIdx(inMultiFrame);
    in1XFrameIdx = 1:length(in1FrameBegIdx);
    for idx = 1:length(in1MFFrameBegIdx)
        inNMiss = round(db1DFrameBeg(inMultiFrame(idx))/dbMeanDFrameBeg) - 1;
        in1XFrameIdx = in1XFrameIdx + (inNMiss*(in1FrameBegIdx > in1MFFrameBegIdx(idx)));
    end
    in1FrameBegIdx = round(interp1(in1XFrameIdx, in1FrameBegIdx, 1:max(in1XFrameIdx)));
end

%Update sREC
sCFG.sREC = sREC;

%Writes the output in CFG
sCFG.sL0PPVA.db1VAnalog = db1VAnalog;
sCFG.sL0PPVA.db1TStamps = db1TStamps;
sCFG.sL0PPVA.blLowLum = blLowLum;
if blLowLum, sCFG.sL0PPVA.in1FrameBegIdx = in1FrameBegIdx; end
sCFG.sL0PPVA.chScriptName = mfilename('fullpath');
sCFG.sL0PPVA.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')