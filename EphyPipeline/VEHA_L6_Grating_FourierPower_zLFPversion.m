function [varargout] = VEHA_L6_Grating_FourierPower(sCFG)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sCFG.sREC.chNlxSessionDir, '_', num2str(sCFG.sREC.inRecNum));

%Checks the for visual stimulation meta structure
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L5_Grating_MakeDataStructure');
chG_MDSFile = 'VEHA_L5_Grating_MakeDataStructure.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chG_MDSFile), 'file')
    error('%s does not exist for session %s in %s\r', chG_MDSFile, chSessionName, chSourcePath_1)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L6_Grating_FourierPower';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L6_Grating_FourierPower.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

%Loads the input
sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chG_MDSFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;

%Sets the parameters for the computation of power
inWorkSampleRate = sINPUT_1.sL5G_MDS.inWorkSampleRate;
if isfield(sCFG.sPARAM, 'dbWinLenSec'), dbWinLenSec = sCFG.sPARAM.dbWinLenSec;
else dbWinLenSec = 0.5; end
if isfield(sCFG.sPARAM, 'inNStep'), inNStep = sCFG.sPARAM.inNStep;
else inNStep = 4; end
if isfield(sCFG.sPARAM, 'blDoPlot'), blDoPlot = sCFG.sPARAM.blDoPlot;
else blDoPlot = false; end
if isfield(sCFG.sPARAM, 'inTopFreq'), inTopFreq = sCFG.sPARAM.inTopFreq;
else inTopFreq = 120; end

%Initialize the output structure
sPRES(length(sINPUT_1.sL5G_MDS.sPRES)).db3FourierPower = [];

%Computes the dimension of the output in the frequency dimension
inFreqDim = length(0:1/dbWinLenSec:inTopFreq);

%Performs the morlet transform of the signal
for iPres = 1:length(sINPUT_1.sL5G_MDS.sPRES)
    %Extracts the LFP
    db2LFP = sINPUT_1.sL5G_MDS.sPRES(iPres).db2LFP;
    
    %%% This is a TEMPORARY edit Stefan made 07/23/2025 to make a zLFP version powerSpectra 
    db2zLFP=[];
    [~, db2zLFP] = VEHA_U_NormalizeLFP(db2LFP, inWorkSampleRate); % Filters and z-scores the LFP
    db2LFP = db2zLFP;
    %%%%%%%  Might need to change it back!!!!!!!!!!!!!!!!!!!!!
    
    %Computes the power of the reference in order to get idea of the
    %dimensions of the output and to get the indices of each of the chunk
    %where the Fourier transform is compute
    [db2RefPower, in1ChunkIdx] = NS_FourierPower(db2LFP(1, :), inWorkSampleRate, dbWinLenSec, inNStep, blDoPlot);
    
    %Initializes the output variable
    db3FourierPower = zeros(inFreqDim, size(db2RefPower, 2), 15);
    
    %Loops through the chunks
    for iChan = 2:16
        db2FourierPower = NS_FourierPower(db2LFP(iChan, :), inWorkSampleRate, dbWinLenSec, inNStep, blDoPlot);
        db3FourierPower(:, :, iChan - 1) = db2FourierPower(1:inFreqDim, :, :);
    end
    sPRES(iPres).db3FourierPower    = db3FourierPower;
    sPRES(iPres).in1ChunkIdx        = in1ChunkIdx;
end

%Keeps track of the input
sCFG.sINPUT.sL5G_MDS.sPARAM = sINPUT_1.sPARAM;
sCFG.sINPUT.sL5G_MDS.chScriptName = sINPUT_1.sL5G_MDS.chScriptName;
sCFG.sINPUT.sL5G_MDS.chTimeComputed = sINPUT_1.sL5G_MDS.chTimeComputed;

%Stores the output vaariable in sCFG
sCFG.sL6G_FP.sPRES              = sPRES;
sCFG.sL6G_FP.inTopFreq          = inTopFreq;
sCFG.sL6G_FP.dbWinLenSec        = dbWinLenSec;
sCFG.sL6G_FP.inNStep            = inNStep;
sCFG.sL6G_FP.inTopFreq          = inTopFreq;
sCFG.sL6G_FP.chScriptName       = mfilename('fullpath');
sCFG.sL6G_FP.chTimeComputed     = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('  Done! \r')