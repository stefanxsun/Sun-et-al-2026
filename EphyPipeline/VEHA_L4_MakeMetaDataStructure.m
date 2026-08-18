function [varargout] = VEHA_L4_MakeMetaDataStructure(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks for LFP 
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L0_PreProcessLFP');
chPPLFPFile = 'VEHA_L0_PreProcessLFP.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chPPLFPFile), 'file')
    error('%s does not exist for session %s in %s\r', chPPLFPFile, chSessionName, chSourcePath_1)
end

%Checks for MUA 
chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L0_PreProcessMUA');
chPPMUAFile = 'VEHA_L0_PreProcessMUA.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chPPMUAFile), 'file')
    error('%s does not exist for session %s in %s\r', chPPMUAFile, chSessionName, chSourcePath_2)
end

%Checks for layer mapping
chSourcePath_3 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L3_LayerMapping');
chLMFile = 'VEHA_L3_LayerMapping.mat';
if ~exist(fullfile(chSourcePath_3, chSessionName, chLMFile), 'file')
    error('%s does not exist for session %s in %s\r', chLMFile, chSessionName, chSourcePath_3)
end

%Checks the for running and non running periods
chSourcePath_O1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L1_DetectWheelChangePoint');
chDWCPFile = 'VEHA_L1_DetectWheelChangePoint.mat';
if ~exist(fullfile(chSourcePath_O1, chSessionName, chDWCPFile), 'file')
    blWheelCP = false;
else
    blWheelCP = true;
end

%Checks the for pupil
chSourcePath_O2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L3_MatchPupilWithCameraTriggers');
chMPCTFile = 'VEHA_L3_MatchPupilWithCameraTriggers.mat';
if ~exist(fullfile(chSourcePath_O2, chSessionName, chMPCTFile), 'file')
    blPupil = false;
else
    blPupil = true;
end

%Checks the for facemap
chSourcePath_O3 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L3_MatchFaceMapWithCameraTriggers');
chMFMCTFile = 'VEHA_L3_MatchFaceMapWithCameraTriggers.mat';
if ~exist(fullfile(chSourcePath_O3, chSessionName, chMFMCTFile), 'file')
    blFMap = false;
else
    blFMap = true;
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L4_MakeMetaDataStructure';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L4_MakeMetaDataStructure.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

%Loads patch clamp, LFP, MUA and Spikes
sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chPPLFPFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
sINPUT_2 = load(fullfile(chSourcePath_2, chSessionName, chPPMUAFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;
sINPUT_3 = load(fullfile(chSourcePath_3, chSessionName, chLMFile), '-mat'); sINPUT_3 = sINPUT_3.sCFG;
%If present, loads wheel change points
if blWheelCP
    sINPUT_O1 = load(fullfile(chSourcePath_O1, chSessionName, chDWCPFile), '-mat'); sINPUT_O1 = sINPUT_O1.sCFG;
end
if blPupil
    sINPUT_O2 = load(fullfile(chSourcePath_O2, chSessionName, chMPCTFile), '-mat'); sINPUT_O2 = sINPUT_O2.sCFG;
end
if blFMap
    sINPUT_O3 = load(fullfile(chSourcePath_O3, chSessionName, chMFMCTFile), '-mat'); sINPUT_O3 = sINPUT_O3.sCFG;
end

%Gets the LFP and downsamples it if needed
inWorkSampleRate    = sINPUT_1.sPARAM.inOutputSampleRate;
db1TStamps          = sINPUT_1.sL0PPLFP.db1TStamps;
db2LFP              = sINPUT_1.sL0PPLFP.db2LFP;

%Finds the indices of the MUA and computes a MUA trace (%Write a function
%to speed up the process)
cMUA_IDX    = cellfun(@(x) NS_GetTStampEventIndex(db1TStamps, x), sINPUT_2.sL0PPMUA.cMUATStamps, 'UniformOutput', false);
in2MUATrace = zeros(length(cMUA_IDX), length(db1TStamps));
for iChan = 1:size(in2MUATrace, 1)
    in2MUATrace(iChan, :) = hist(cMUA_IDX{iChan}, 1:length(db1TStamps));
end

%Assigns layers depth
db1LChan        = sINPUT_3.sL3LM.db1LayerChan;
db1ChannelDepth = sINPUT_3.sL3LM.db1ChannelDepth;
in1Channel      = 1:16;
db1ChanLayer    = 1 + (in1Channel > db1LChan(1)) + (2*(in1Channel > db1LChan(2)))...
    + (in1Channel > db1LChan(3)) + (in1Channel > db1LChan(4));

%Creates the running trace if the data is present otherwise assumes that
%the mouse is alwas sitting
if blWheelCP
    in1WheelOnIdx = NS_GetTStampEventIndex(db1TStamps, sINPUT_O1.sL1DWCP.db1WheelOnTStamp);
    in1WheelOffIdx = NS_GetTStampEventIndex(db1TStamps, sINPUT_O1.sL1DWCP.db1WheelOffTStamp);
    if ~isempty(in1WheelOnIdx)
        if isnan(in1WheelOnIdx(1)), in1WheelOnIdx(1) = 1; end
        if isnan(in1WheelOffIdx(end)), in1WheelOffIdx(end) = length(db1TStamps); end
        bl1WheelOn = NS_MakeEpochVector(in1WheelOnIdx, in1WheelOffIdx, length(db1TStamps));
    else
        bl1WheelOn = false(size(db1TStamps));
    end
else
    bl1WheelOn = false(size(db1TStamps));
end

%Creates the pupil trace if needed
if blPupil   
    db1CatPArea         = [];
    in1CatPTStampsIdx   = [];  
    for iMovie = 1:length(sINPUT_O2.sL3MPCT.sMOVIE_RE)
        %Extracts pupil area and excludes errors
        db1PupilArea = sINPUT_O2.sL3MPCT.sMOVIE_RE(iMovie).db2CROutput(:,3)';
        bl1PupilExclude = sINPUT_O2.sL3MPCT.sMOVIE_RE(iMovie).bl1Exclude;
        db1PupilArea(bl1PupilExclude) = NaN;
        
        %Extracts pupil time stamps
        db1PupilTStamps = sINPUT_O2.sL3MPCT.sMOVIE_RE(iMovie).db1MovieTrigTStamps;
        db1PupilArea(isnan(db1PupilTStamps)) = [];
        db1PupilTStamps(isnan(db1PupilTStamps)) = [];
        
        %Finds the indices of the pupil trace
        in1PupilTStampsIdx = NS_GetTStampEventIndex(db1TStamps, db1PupilTStamps);
        
        %Pad one NaN at the end so as not to interpolated between two separate movies
        db1PupilArea = cat(2,db1PupilArea, NaN);
        in1PupilTStampsIdx = cat(2, in1PupilTStampsIdx, in1PupilTStampsIdx(end) + 1);
        
        %Concatenate the timstamps and area trace
        db1CatPArea = cat(2, db1CatPArea, db1PupilArea);
        in1CatPTStampsIdx = cat(2, in1CatPTStampsIdx, in1PupilTStampsIdx);
    end
    
    if all(isnan(db1CatPArea))
        blPupil = false;
    elseif length(db1CatPArea) ~= length(in1CatPTStampsIdx)
        blPupil = false;
    else
        db1PupilArea = interp1(in1CatPTStampsIdx, db1CatPArea, 1:length(db1TStamps));
    end
end


%Creates the FACEMAP trace
if blFMap   
    db1CatFacePC1       = [];
    bl1CatWhisk         = [];
    in1CatWTStampsIdx   = [];  
    for iMovie = 1:length(sINPUT_O3.sL3.sFMAP)
        %Extracts pupil area and excludes errors
        db1FacePC1  = sINPUT_O3.sL3.sFMAP(iMovie).db1_FacePC1;
        in1OnIdx    = sINPUT_O3.sL3.sFMAP(iMovie).in1OnIdx;
        in1OffIdx   = sINPUT_O3.sL3.sFMAP(iMovie).in1OffIdx;
        bl1Whisk    = NS_MakeEpochVector(in1OnIdx, in1OffIdx, length(db1FacePC1));
        
        %Extracts pupil time stamps
        db1WhiskTStamps = sINPUT_O3.sL3.sFMAP(iMovie).db1MovieTrigTStamps;
        db1FacePC1(isnan(db1WhiskTStamps)) = [];
        bl1Whisk(isnan(db1WhiskTStamps)) = [];
        db1WhiskTStamps(isnan(db1WhiskTStamps)) = [];
        
        %Finds the indices of the pupil trace
        in1WhiskTStampsIdx = NS_GetTStampEventIndex(db1TStamps, db1WhiskTStamps);
        
        %Pad one NaN at the end so as not to interpolated between two separate movies
        db1FacePC1  = cat(2, db1FacePC1, NaN);
        bl1Whisk    = cat(2, bl1Whisk, NaN);
        in1WhiskTStampsIdx = cat(2, in1WhiskTStampsIdx, in1WhiskTStampsIdx(end) + 1);
        
        %Concatenate the timstamps and area trace
        db1CatFacePC1   = cat(2, db1CatFacePC1, db1FacePC1);
        bl1CatWhisk     = cat(2, bl1CatWhisk, bl1Whisk);
        in1CatWTStampsIdx = cat(2, in1CatWTStampsIdx, in1WhiskTStampsIdx);
    end
    
    if all(isnan(db1CatFacePC1))
        blFMap = false;
    elseif length(in1CatWTStampsIdx) ~= length(db1CatFacePC1)
        blFMap = false;
    else
        db1FacePC1  = interp1(in1CatWTStampsIdx, db1CatFacePC1, 1:length(db1TStamps));
        bl1Whisk    = interp1(in1CatWTStampsIdx, bl1CatWhisk, 1:length(db1TStamps));
    end
end

% %Plots the result if needed
% figure, 
% ax(1) = subplot(5, 1, 1:2); plot(db1TStamps, db2LFP  + repmat((0:-0.25:-3.75)', 1, size(db2LFP, 2)), 'k');
% ax(2) = subplot(5, 1, 3);   plot(db1TStamps, conv(sum(in2MUATrace), gausswin(round(inWorkSampleRate*0.1)), 'same'), 'k');
% ax(3) = subplot(5, 1, 4);   plot(db1TStamps, bl1WheelOn, 'k');
% ax(4) = subplot(5, 1, 5);   plot(db1TStamps, db1PupilArea, 'k');
% linkaxes(ax, 'x')

%Update sREC
sCFG.sREC = sREC;

%Keeps track of the input in CSG
sCFG.sINPUT.sL0PPLFP.sPARAM         = sINPUT_1.sPARAM;
sCFG.sINPUT.sL0PPLFP.chScriptName   = sINPUT_1.sL0PPLFP.chScriptName;
sCFG.sINPUT.sL0PPLFP.chTimeComputed = sINPUT_1.sL0PPLFP.chTimeComputed;
sCFG.sINPUT.sL0PPMUA.sPARAM         = sINPUT_2.sPARAM;
sCFG.sINPUT.sL0PPMUA.chScriptName   = sINPUT_2.sL0PPMUA.chScriptName;
sCFG.sINPUT.sL0PPMUA.chTimeComputed = sINPUT_2.sL0PPMUA.chTimeComputed;
sCFG.sINPUT.sL3LM.sPARAM            = sINPUT_3.sPARAM;
sCFG.sINPUT.sL3LM.chScriptName      = sINPUT_3.sL3LM.chScriptName;
sCFG.sINPUT.sL3LM.chTimeComputed    = sINPUT_3.sL3LM.chTimeComputed;
if blWheelCP
    sCFG.sINPUT.sL1DWCP.sPARAM          = sINPUT_O1.sPARAM;
    sCFG.sINPUT.sL1DWCP.chScriptName    = sINPUT_O1.sL1DWCP.chScriptName;
    sCFG.sINPUT.sL1DWCP.chTimeComputed  = sINPUT_O1.sL1DWCP.chTimeComputed;
end
if blPupil
    sCFG.sINPUT.sL3MPCT.sPARAM          = sINPUT_O2.sPARAM;
    sCFG.sINPUT.sL3MPCT.chScriptName    = sINPUT_O2.sL3MPCT.chScriptName;
    sCFG.sINPUT.sL3MPCT.chTimeComputed  = sINPUT_O2.sL3MPCT.chTimeComputed;
end
if blFMap
    sCFG.sINPUT.sL3MFMCT.sPARAM          = sINPUT_O3.sPARAM;
    sCFG.sINPUT.sL3MFMCT.chScriptName    = sINPUT_O3.sL3.chScriptName;
    sCFG.sINPUT.sL3MFMCT.chTimeComputed  = sINPUT_O3.sL3.chTimeComputed;
end

%Record the output
sCFG.sL4MMDS.inWorkSampleRate   = inWorkSampleRate;
sCFG.sL4MMDS.db1TStamps         = db1TStamps;
sCFG.sL4MMDS.db2LFP             = db2LFP;
sCFG.sL4MMDS.in2MUATrace        = in2MUATrace;
sCFG.sL4MMDS.db1LChan           = db1LChan;
sCFG.sL4MMDS.db1ChannelDepth    = db1ChannelDepth;
sCFG.sL4MMDS.db1ChanLayer       = db1ChanLayer;
sCFG.sL4MMDS.bl1WheelOn         = bl1WheelOn;
if blPupil
    sCFG.sL4MMDS.db1PupilArea   = db1PupilArea;
end
if blFMap
    sCFG.sL4MMDS.db1FacePC1     = db1FacePC1;
    sCFG.sL4MMDS.bl1Whisk       = bl1Whisk;
end
sCFG.sL4MMDS.chScriptName   = mfilename('fullpath');
sCFG.sL4MMDS.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('  Done! \r')
