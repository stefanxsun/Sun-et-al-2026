function [varargout] = VEHA_L1_DetectPupil(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Check that the source path to pupil movies is valid
chSourcePath = fullfile(sREC.chPupilMovieSessionPath, sREC.chPupilMovieSessionDir);
if ~exist(chSourcePath, 'dir')
    error('Unable to locate %s in %s\r', sREC.chPupilMovieSessionDir, sREC.chPupilMovieSessionPath);
end

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the imput source path
chSourcePath = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L0_SetPupilMovieParameters');
chSPMPFile = 'VEHA_L0_SetPupilMovieParameters.mat';
if ~exist(fullfile(chSourcePath, chSessionName, chSPMPFile), 'file')
    error('%s does not exist for session %s in %s\r', chSPMPFile, chSessionName, chSourcePath)
end

%Loads pupil movie parameters
sLOAD = load(fullfile(chSourcePath, chSessionName, chSPMPFile), '-mat');

% Checks for the presence of a usable movie
blDoProcessing = 0;
ii = 0;
while blDoProcessing == 0 && ii < length(sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM);
    ii = ii + 1;
    blDoProcessing = sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM(ii).blUsable;
end

if ~blDoProcessing
    fprintf('No usable movie for session %s. Skipped\r', chSessionName)
    return
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L1_DetectPupil';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L1_DetectPupil.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

%Prealocate values of the output structure
sMOVIE_CR(length(sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM)).inMovIdx = [];
sMOVIE_CR(length(sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM)).chMovieFullPath = [];
sMOVIE_CR(length(sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM)).blPupilMovieTrigComplete = [];
sMOVIE_CR(length(sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM)).sCR_PARAM = [];
sMOVIE_CR(length(sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM)).db2CROutput = [];

for ii = 1:length(sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM)
    
    %Copy the file in the work directory to reduce loading time when
    %loading from server. Comment out if the processing is local
    chMovieFullPath = sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM(ii).chMovieFullPath;
    [ignore_1, chMovieName, ignore_2] = fileparts(chMovieFullPath);
    chMovieWorkPath = fullfile(chDestPath, chMovieName);
    copyfile(chMovieFullPath, chMovieWorkPath);
    
    %Sets the parameters of the core routine for pupil detection
    sCR_PARAM = struct();
%     sCR_PARAM.chPathToFile = sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM(ii).chMovieFullPath; %Uncomment if the processing is local
    sCR_PARAM.chPathToFile = chMovieWorkPath; % Comments out if the processing is local
    sCR_PARAM.in1XL = sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM(ii).in1XL;
    sCR_PARAM.in1YL = sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM(ii).in1YL;
    sCR_PARAM.dbMaxPixValForSegmentation = sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM(ii).dbMaxPixValForSegmentation;
    if isfield(sCFG.sPARAM, 'blFuzzyClustering'), sCR_PARAM.blFuzzyClustering = sCFG.sPARAM.blFuzzyClustering; end
    if isfield(sCFG.sPARAM, 'dbFuzzyCutOff'), sCR_PARAM.dbFuzzyCutOff = sCFG.sPARAM.dbFuzzyCutOff; end
    if isfield(sCFG.sPARAM, 'blRemLinearFitOutliers'), sCR_PARAM.blRemLinearFitOutliers = sCFG.sPARAM.blRemLinearFitOutliers; end
    if isfield(sCFG.sPARAM, 'blRemHighLumEdges'), sCR_PARAM.blRemHighLumEdges = sCFG.sPARAM.blRemHighLumEdges; end
    if isfield(sCFG.sPARAM, 'inMaxPixFromHighLum'), sCR_PARAM.inMaxPixFromHighLum = sCFG.sPARAM.inMaxPixFromHighLum; end
    if isfield(sCFG.sPARAM, 'dbQuantileOfHighLum'), sCR_PARAM.dbQuantileOfHighLum = sCFG.sPARAM.dbQuantileOfHighLum; end
    if isfield(sCFG.sPARAM, 'inFramesPerRead'), sCR_PARAM.inFramesPerRead = sCFG.sPARAM.inFramesPerRead; end
    if isfield(sCFG.sPARAM, 'blWriteVid'), sCR_PARAM.blWriteVid = sCFG.sPARAM.blWriteVid; end
    sCR_PARAM.chOutputDir = fullfile(chDestPath, chDestMetaFolder, chSessionName);
    if isfield(sCFG.sPARAM, 'inVidFrameInterval'), sCR_PARAM.inVidFrameInterval = sCFG.sPARAM.inVidFrameInterval; end
    
    % Performs the computation for movie ii an stores it in a structure
    sMOVIE_CR(ii).inMovIdx = sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM(ii).inMovIdx;
    sMOVIE_CR(ii).chMovieFullPath = sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM(ii).chMovieFullPath;
    sMOVIE_CR(ii).blPupilMovieTrigComplete = sLOAD.sCFG.sL0SPMP.sMOVIE_PARAM(ii).blPupilMovieTrigComplete;
    sMOVIE_CR(ii).sCR_PARAM = sCR_PARAM;
    sMOVIE_CR(ii).db2CROutput = VEHA_CR_PupilReadOut(sCR_PARAM); %Core routine
    
    %Deletes the movie file 
    delete(chMovieWorkPath); %Comment out if not processing from server.
end

%Update sREC
sCFG.sREC = sREC;

%Keeps track of the input in CSG
sCFG.sINPUT.sL0SPMP.chScriptName = sLOAD.sCFG.sL0SPMP.chScriptName;
sCFG.sINPUT.sL0SPMP.chTimeComputed = sLOAD.sCFG.sL0SPMP.chTimeComputed;

%Writes the output in CSG
sCFG.sL1DP.sMOVIE_CR = sMOVIE_CR;
sCFG.sL1DP.chScriptName = mfilename('fullpath');
sCFG.sL1DP.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')