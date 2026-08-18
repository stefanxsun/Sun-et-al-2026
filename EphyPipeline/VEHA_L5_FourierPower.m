function [varargout] = VEHA_L5_FourierPower(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the for visual stimulation meta structure
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L5_Grating_MakeDataStructure');
chMDSFile = 'VEHA_L5_Grating_MakeDataStructure.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chMDSFile), 'file')
    error('%s does not exist for session %s in %s\n', chMDSFile, chSessionName, chSourcePath_1)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L5_FourierPower';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L5_FourierPower.mat';
if sCFG.sPARAM.blPlot
    chDestFile_Fig  = 'VEHA_L5_FourierPower.fig';
end
%Checks that the data does not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\n %s.\n Skipped...\n', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

%Checks for arguments
if isfield(sCFG.sPARAM, 'dbWinLenSec'), dbWinLenSec = sCFG.sPARAM.dbWinLenSec;
else, dbWinLenSec = 0.5; sCFG.sPARAM.dbWinLenSec = 0.5; end
if isfield(sCFG.sPARAM, 'inNStep'), inNStep = sCFG.sPARAM.inNStep;
else, inNStep = 4; sCFG.sPARAM.inNStep = 4; end
if isfield(sCFG.sPARAM, 'blPlot'), blPlot = sCFG.sPARAM.blPlot;
else, blPlot = false; sCFG.sPARAM.blPlot = false; end
if isfield(sCFG.sPARAM, 'inTopFreq'), inTopFreq = sCFG.sPARAM.inTopFreq;
else, inTopFreq = 120; sCFG.sPARAM.inTopFreq = 120; end

%Loads the input
sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chMDSFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;

%Sets the parameters for the computation of power
inSampleRate = sINPUT_1.sL5G_MDS.inWorkSampleRate;

%Computes the dimension of the output in the frequency dimension
inFreqDim = length(0:1/dbWinLenSec:inTopFreq);

%Extracts the LFP
db2LFP = sINPUT_1.sL5G_MDS.sPRES.db2LFP;
db2LFP(2:end, :) = VEHA_U_NormalizeLFP(db2LFP, inSampleRate, 2:size(db2LFP, 1));

%Computes the power of the reference in order to get idea of the
%dimensions of the output and to get the indices of each of the chunk
%where the Fourier transform is compute
[db2RefPower, in1ChunkIdx] = NS_FourierPower(db2LFP(1, :), inSampleRate, dbWinLenSec, inNStep, false);

%Initializes the output variable
db3FourierPower = zeros(inFreqDim, size(db2RefPower, 2), 15);

%Loops through the chunks
for iChan = 2:16
    db2FourierPower = NS_FourierPower(db2LFP(iChan, :), inSampleRate, dbWinLenSec, inNStep, false);
    db3FourierPower(:, :, iChan - 1) = db2FourierPower(1:inFreqDim, :, :);
end

%Gets the indices of when the mouse is running or whisking
bl1RunChunk     = sINPUT_1.sL5G_MDS.sPRES.bl1WheelOn(in1ChunkIdx);

%Extracts the stimulation times
[bl1FullCtr, in1PresOnIdx, in1PresOffIdx] = deal([]);
sPRES 	= sINPUT_1.sL5G_MDS.sPRES;
for iPrs = 1:length(sPRES)
    %Aggregates presentation onset indices
    in1PresOnIdx    = cat(2, in1PresOnIdx, ...
        NS_GetTStampEventIndex(sPRES(iPrs).db1TStamps, sPRES(iPrs).db1PresOnTStamp));
    in1PresOffIdx   = cat(2, in1PresOffIdx, ...
        NS_GetTStampEventIndex(sPRES(iPrs).db1TStamps, sPRES(iPrs).db1PresOffTStamp));
    
    %Gets full contrasts presentation if gratings were presented
    dbStimMat = sPRES(iPrs).dbStimMat;
    bl1FullCtrPres = dbStimMat(2, :) == .04 & dbStimMat(4, :) >= .32 & dbStimMat(5, :) >= 20;
    bl1FullCtr 	= cat(2, bl1FullCtr, bl1FullCtrPres);
end

bl1FullCtr 		= logical(bl1FullCtr);
bl1Stim         = NS_MakeEpochVector(in1PresOnIdx, in1PresOffIdx, length(sINPUT_1.sL5G_MDS.sPRES.db1TStamps));
bl1StimFull     = NS_MakeEpochVector(in1PresOnIdx(bl1FullCtr), in1PresOffIdx(bl1FullCtr), length(sINPUT_1.sL5G_MDS.sPRES.db1TStamps));

%Computes the averages over channels
db2CC_Power = 10*log10(mean(db3FourierPower, 3));

%Computes the average over condition
bl1Run = bl1RunChunk & ~bl1Stim(in1ChunkIdx);
db1MeanPwr_Run          = mean(db2CC_Power(:, bl1Run), 2)';
db1SEMPwr_Run           = sqrt(var(db2CC_Power(:, bl1Run), [], 2)./sum(bl1Run))';
bl1PresOn = ~bl1RunChunk & bl1StimFull(in1ChunkIdx);
db1MeanPwr_Pres         = mean(db2CC_Power(:, bl1PresOn), 2)';
db1SEMPwr_Pres          = sqrt(var(db2CC_Power(:, bl1PresOn), [], 2)./sum(bl1PresOn))';
bl1Quiet = ~bl1RunChunk & ~bl1Stim(in1ChunkIdx);
db1MeanPwr_Quiet        = mean(db2CC_Power(:, bl1Quiet), 2)';
db1SEMPwr_Quiet         = sqrt(var(db2CC_Power(:, bl1Quiet), [], 2)./sum(bl1Quiet))';

%Plots the power for different conditions if needed
if blPlot
    cCOLOR = {[.3 .3 .3], [.8 .4 0], [.8 .1 0], [.8 .3 0], [0 .2 .8]};
    
    db1X    = 0:1/dbWinLenSec:inTopFreq;
    db1XF   = [db1X db1X(end:-1:1)];
    
    hFIG = figure('Position', [100 100 1600 900]);
    
    subplot(1, 2, 1); hold on
    db1Y    = db1MeanPwr_Quiet;
    db1YF   = [db1MeanPwr_Quiet + db1SEMPwr_Quiet db1MeanPwr_Quiet(end:-1:1) - db1SEMPwr_Quiet(end:-1:1)];
    fill(db1XF, db1YF, cCOLOR{1}, 'LineStyle', 'none', 'FaceAlpha', .3);
    hPLT(1) = plot(db1X, db1Y, 'color', cCOLOR{1});
    db1Y    = db1MeanPwr_Run;
    db1YF   = [db1MeanPwr_Run + db1SEMPwr_Run db1MeanPwr_Run(end:-1:1) - db1SEMPwr_Run(end:-1:1)];
    fill(db1XF, db1YF, cCOLOR{4}, 'LineStyle', 'none', 'FaceAlpha', .3);
    hPLT(2) = plot(db1X, db1Y, 'color', cCOLOR{4});
    ylabel('Power (dB)'); xlabel('Frequency (Hz)');
    legend(hPLT, {'Quiet', 'Running'})
    title(sprintf('%s', sREC.chNlxSessionDir))
    
    subplot(1, 2, 2); hold on
    db1Y    = db1MeanPwr_Quiet;
    db1YF   = [db1MeanPwr_Quiet + db1SEMPwr_Quiet db1MeanPwr_Quiet(end:-1:1) - db1SEMPwr_Quiet(end:-1:1)];
    fill(db1XF, db1YF, cCOLOR{1}, 'LineStyle', 'none', 'FaceAlpha', .3);
    hPLT(1) = plot(db1X, db1Y, 'color', cCOLOR{1});
    db1Y    = db1MeanPwr_Pres;
    db1YF   = [db1MeanPwr_Pres + db1SEMPwr_Pres db1MeanPwr_Pres(end:-1:1) - db1SEMPwr_Pres(end:-1:1)];
    fill(db1XF, db1YF, cCOLOR{5}, 'LineStyle', 'none', 'FaceAlpha', .3);
    hPLT(2) = plot(db1X, db1Y, 'color', cCOLOR{5});
    ylabel('Power (dB)'); xlabel('Frequency (Hz)');
    legend(hPLT, {'Quiet', 'FullGrating'})
end

%Keeps track of the input
sCFG.sINPUT.sL5G_MDS.sPARAM = sINPUT_1.sPARAM  ;
sCFG.sINPUT.sL5G_MDS.chScriptName = sINPUT_1.sL5G_MDS.chScriptName  ;
sCFG.sINPUT.sL5G_MDS.chTimeComputed = sINPUT_1.sL5G_MDS.chTimeComputed  ;

%Stores the output vaariable in sCFG
sCFG.sL5FP.db3FourierPower      = db3FourierPower;
sCFG.sL5FP.in1ChunkIdx          = in1ChunkIdx;
sCFG.sL5FP.inNChunkRun          = sum(bl1Run);
sCFG.sL5FP.db1MeanPwr_Run       = db1MeanPwr_Run;
sCFG.sL5FP.db1SEMPwr_Run        = db1SEMPwr_Run;
sCFG.sL5FP.inNChunkPres         = sum(bl1PresOn);
sCFG.sL5FP.db1MeanPwr_Pres      = db1MeanPwr_Pres;
sCFG.sL5FP.db1SEMPwr_Pres       = db1SEMPwr_Pres;
sCFG.sL5FP.inNChunkQuiet        = sum(bl1Quiet);
sCFG.sL5FP.db1MeanPwr_Quiet     = db1MeanPwr_Quiet;
sCFG.sL5FP.db1SEMPwr_Quiet      = db1SEMPwr_Quiet;
sCFG.sL5FP.inTopFreq            = inTopFreq;
sCFG.sL5FP.dbWinLenSec          = dbWinLenSec;
sCFG.sL5FP.inNStep              = inNStep;
sCFG.sL5FP.inTopFreq            = inTopFreq;
sCFG.sL5FP.chScriptName         = mfilename('fullpath');
sCFG.sL5FP.chTimeComputed       = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');
if blPlot
    savefig(hFIG,fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Fig));
end

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('  Done! \n')
