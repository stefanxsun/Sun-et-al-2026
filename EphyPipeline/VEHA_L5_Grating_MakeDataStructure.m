function [varargout] = VEHA_L5_Grating_MakeDataStructure(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the for visual stimulation meta structure
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L2_MatchStimLogWithPresentationSet');
chMSLPSFile = 'VEHA_L2_MatchStimLogWithPresentationSet.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chMSLPSFile), 'file')
    error('%s does not exist for session %s in %s\r', chMSLPSFile, chSessionName, chSourcePath_1)
end

%Checks for the metastructure
chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L4_MakeMetaDataStructure');
chMMDSFile = 'VEHA_L4_MakeMetaDataStructure.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chMMDSFile), 'file')
    error('%s does not exist for session %s in %s\r', chMMDSFile, chSessionName, chSourcePath_2)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L5_Grating_MakeDataStructure';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L5_Grating_MakeDataStructure.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

%Checks if grating were presented and loads the global meta data structure
%if it is the case
sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chMSLPSFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
if ~isfield(sINPUT_1.sL2MSLPS.sSTIMLOG, 'sGRATING')
    rmdir(fullfile(chDestPath, chDestMetaFolder, chSessionName));
    fprintf('Gratings were not presented for %s\r', chSessionName)
    return
end
sINPUT_2 = load(fullfile(chSourcePath_2, chSessionName, chMMDSFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;

%Gets the work sample rate and computes the length of the margin 
inWorkSampleRate    = sINPUT_2.sL4MMDS.inWorkSampleRate;
inMarginLen         = round(sCFG.sPARAM.dbMarginSec * inWorkSampleRate);

%Determines if the pupil was detected or not
blPupil = isfield(sINPUT_2.sL4MMDS, 'db1PupilArea');

%cuts the data around presentation sets and puts the result in a structure sPRES
sPRES = sINPUT_1.sL2MSLPS.sSTIMLOG.sGRATING;
blRemove = false(1, length(sPRES));
for iPres = 1:length(sPRES)
     
    inStartIdx     = NS_GetTStampEventIndex(sINPUT_2.sL4MMDS.db1TStamps, sPRES(iPres).db1PresOnTStamp(1)) - inMarginLen;
    inEndIdx       = NS_GetTStampEventIndex(sINPUT_2.sL4MMDS.db1TStamps, sPRES(iPres).db1PresOffTStamp(end)) + inMarginLen;
    sPRES(iPres).db1TStamps     = sINPUT_2.sL4MMDS.db1TStamps(inStartIdx:inEndIdx);
    sPRES(iPres).db2LFP         = sINPUT_2.sL4MMDS.db2LFP(:, inStartIdx:inEndIdx);
    sPRES(iPres).in2MUATrace    = sINPUT_2.sL4MMDS.in2MUATrace(:, inStartIdx:inEndIdx);%Update sREC
    sPRES(iPres).bl1WheelOn     = sINPUT_2.sL4MMDS.bl1WheelOn(inStartIdx:inEndIdx);
    sPRES(iPres).db1FacePC1     = sINPUT_2.sL4MMDS.db1FacePC1(inStartIdx:inEndIdx); 
    if blPupil
        sPRES(iPres).db1PupilArea = sINPUT_2.sL4MMDS.db1PupilArea(inStartIdx:inEndIdx);
    end
    sPRES(iPres).in1PresOnIdx   = NS_GetTStampEventIndex(sPRES(iPres).db1TStamps, sPRES(iPres).db1PresOnTStamp);
    sPRES(iPres).in1PresOffIdx  = NS_GetTStampEventIndex(sPRES(iPres).db1TStamps, sPRES(iPres).db1PresOffTStamp);
end
sPRES(blRemove) = [];


%Update sREC
sCFG.sREC = sREC;

%Keeps track of the input
sCFG.sINPUT.sL0PPLFP.sPARAM = sINPUT_1.sPARAM;
sCFG.sINPUT.sL0PPLFP.chScriptName = sINPUT_1.sL2MSLPS.chScriptName;
sCFG.sINPUT.sL0PPLFP.chTimeComputed = sINPUT_1.sL2MSLPS.chTimeComputed;
sCFG.sINPUT.sL0PPMUA.sPARAM = sINPUT_2.sPARAM;
sCFG.sINPUT.sL0PPMUA.chScriptName = sINPUT_2.sL4MMDS.chScriptName;
sCFG.sINPUT.sL0PPMUA.chTimeComputed = sINPUT_2.sL4MMDS.chTimeComputed;

%Stores the output vaariable in sCFG
sCFG.sL5G_MDS.inWorkSampleRate   = inWorkSampleRate;
sCFG.sL5G_MDS.sPRES              = sPRES;
sCFG.sL5G_MDS.chScriptName       = mfilename('fullpath');
sCFG.sL5G_MDS.chTimeComputed     = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('  Done! \r')