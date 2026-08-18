function [varargout] = VEHA_L6_Pulse_vs_LFP_FourierPower(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the for visual stimulation meta structure
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L4_MakeMetaDataStructure');
chMDSFile = 'VEHA_L4_MakeMetaDataStructure.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chMDSFile), 'file')
    error('%s does not exist for session %s in %s\n', chMDSFile, chSessionName, chSourcePath_1)
end

%Checks the for visual stimulation meta structure
chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L5_GetPulse');
chGPFile = 'VEHA_L5_GetPulse.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chGPFile), 'file')
    error('%s does not exist for session %s in %s\n', chGPFile, chSessionName, chSourcePath_2)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L6_Pulse_vs_LFP_FourierPower';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName))
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L6_Pulse_vs_LFP_FourierPower.mat';
%Checks that the data does not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\n %s.\n Skipped...\n', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

%Checks for optional arguments -----------------------------------------------------------------------------------------
if isfield(sCFG.sPARAM, 'cTHRESHOLD'), cTHRESHOLD = sCFG.sPARAM.cTHRESHOLD;
else, cTHRESHOLD = {'MahalDNorm'}; sCFG.sPARAM.cTHRESHOLD = cTHRESHOLD; end
inNThr = length(cTHRESHOLD);
if isfield(sCFG.sPARAM, 'dbWinLenSec'), dbWinLenSec = sCFG.sPARAM.dbWinLenSec;
else, dbWinLenSec = 0.5; sCFG.sPARAM.dbWinLenSec = 0.5; end
if isfield(sCFG.sPARAM, 'inNStep'), inNStep = sCFG.sPARAM.inNStep;
else, inNStep = 4; sCFG.sPARAM.inNStep = 4; end
if isfield(sCFG.sPARAM, 'inTopFreq'), inTopFreq = sCFG.sPARAM.inTopFreq;
else, inTopFreq = 120; sCFG.sPARAM.inTopFreq = 120; end
if isfield(sCFG.sPARAM, 'blPlot'), blPlot = sCFG.sPARAM.blPlot;
else, blPlot = false; sCFG.sPARAM.blPlot = false; end
if isfield(sCFG.sPARAM, 'blVisible'), blVisible = sCFG.sPARAM.blVisible;
else, blVisible = false; sCFG.sPARAM.blVisible = false; end
if blPlot
    chDestFile_Fig  = 'VEHA_L6_Pulse_vs_LFP_FourierPower.fig';
end

%Loads the input -------------------------------------------------------------------------------------------------------
sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chMDSFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
sINPUT_2 = load(fullfile(chSourcePath_2, chSessionName, chGPFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;

%Extracts the input ----------------------------------------------------------------------------------------------------

%Sets the parameters for the computation of power
inSampleRate = sINPUT_1.sL4MMDS.inWorkSampleRate;

%Computes the dimension of the output in the frequency dimension
db1Freq     = 0:1/dbWinLenSec:inTopFreq;
inFreqDim   = length(db1Freq);

%Extracts the LFP
db2LFP = sINPUT_1.sL4MMDS.db2LFP;
db2LFP(2:end, :) = VEHA_U_NormalizeLFP(db2LFP, inSampleRate, 2:size(db2LFP, 1));

%Extract the band structure
sBND_IN 	= sINPUT_2.sL5.sBAND;
inNBnd 		= length(sBND_IN);

%Computes overal power and indices of chunks ---------------------------------------------------------------------------

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

%Computes the averages over channels
db2CC_Power = 10*log10(mean(db3FourierPower, 3));

%Computes Power as a function of pulses rate for each band and threshold ------------------------------------------------

%Initialize the output structure
sBAND 	= struct('chBandLabel', cell(inNThr, inNBnd), 'chStateLabel', cell(inNThr, inNBnd), ...
    'chThreshold', cell(inNThr, inNBnd), 'db80pct', cell(inNThr, inNBnd), ...
    'db1MeanPwr_80plus', cell(inNThr, inNBnd), 'db1SEMPwr_80plus', cell(inNThr, inNBnd), ...
    'inNChnk_80plus', cell(inNThr, inNBnd), 'db1MeanPwr_80min', cell(inNThr, inNBnd), ...
    'db1SEMPwr_80min', cell(inNThr, inNBnd), 'inNChnk_80min', cell(inNThr, inNBnd));

%Initializes plot counter if needed
if blPlot, iFig = 0; end

% Loops through trials and bands and aggregates the pulse data for each band
for iThr = 1:inNThr
    for iBnd = 1:inNBnd
        %Extracts input variables
        in1Index 		= sBND_IN(iBnd).in1Index;
        db1Score 		= sBND_IN(iBnd).db1Score;
        db1Score_Rnd 	= sBND_IN(iBnd).db1Score_Rnd;

        %Extract the score threshold
        if strcmp(cTHRESHOLD{iThr}, 'MahalDNorm')
            dbScoreThreshold = sBND_IN(iBnd).dbThreshold;
        elseif strcmp(cTHRESHOLD{iThr}, 'ScoreRate')
            dbScoreThreshold = quantile(db1Score, 1 - (sum(db1Score)/length(db1Score)));
        elseif strcmp(cTHRESHOLD{iThr}, '3SDRandData')
            dbScoreThreshold = max(db1Score_Rnd) + (3 * std(db1Score_Rnd));
        else
            dbScoreThreshold = str2double(cTHRESHOLD{iThr});
        end
        
        %Computes index vectors for pulse (P) and trough out of pulse (TO)
        in1PulseIdx = in1Index(db1Score > dbScoreThreshold);
        bl1Pulse    = false(1, size(db2LFP, 2));
        bl1Pulse(in1PulseIdx) = true;
        
        %Estimtates the number pulse at all points of the trace and
        %determines the 80pc percentile
        db1Win          = rectwin(dbWinLenSec * inSampleRate);
        db1PulseRate    = conv(bl1Pulse, db1Win, 'same')./dbWinLenSec;
        db80pct         = quantile(db1PulseRate, .8);
        bl180pctPlus    = db1PulseRate > db80pct;
        
        %Calculates the power above and under the threshold
        bl1Plus             = bl180pctPlus(in1ChunkIdx);
        db1MeanPwr_80plus   = mean(db2CC_Power(:, bl1Plus), 2)';
        db1SEMPwr_80plus    = sqrt(var(db2CC_Power(:, bl1Plus), [], 2)./sum(bl1Plus))';
        inNChnk_80plus      = sum(bl1Plus);
        bl1Min              = ~bl180pctPlus(in1ChunkIdx);
        db1MeanPwr_80min    = mean(db2CC_Power(:, bl1Min), 2)';
        db1SEMPwr_80min     = sqrt(var(db2CC_Power(:, bl1Min), [], 2)./sum(bl1Min))';
        inNChnk_80min       = sum(bl1Min);
        
        %Stores variable indexing the band, what state and threshold were
		%used to define CLAMS pulses
		sBAND(iThr, iBnd).chBandLabel 		= sBND_IN(iThr, iBnd).chBandLabel;
		sBAND(iThr, iBnd).chStateLabel 		= sBND_IN(iThr, iBnd).chStateLabel;
		sBAND(iThr, iBnd).chThreshold 		= cTHRESHOLD{iThr};

		%Stores variable indexing the band, what state and threshold were
		%used to define CLAMS pulses
        sBAND(iThr, iBnd).db80pct           = db80pct;
		sBAND(iThr, iBnd).db1MeanPwr_80plus = db1MeanPwr_80plus;
		sBAND(iThr, iBnd).db1SEMPwr_80plus 	= db1SEMPwr_80plus;
		sBAND(iThr, iBnd).inNChnk_80plus 	= inNChnk_80plus;
        sBAND(iThr, iBnd).db1MeanPwr_80min 	= db1MeanPwr_80min;
		sBAND(iThr, iBnd).db1SEMPwr_80min 	= db1SEMPwr_80min;
		sBAND(iThr, iBnd).inNChnk_80min     = inNChnk_80min;
          
        %Plots the power for different conditions if needed
        if blPlot
            %Extract band labels
            chBndLbl    = sBND_IN(iBnd).chBandLabel;
            
            %Computes the significance between up and down with a Wech test
            db1P    = NS_WelchTest(db1MeanPwr_80plus, db1MeanPwr_80min, db1SEMPwr_80plus .^ 2 .* inNChnk_80plus, ...
                db1SEMPwr_80min .^ 2 .* inNChnk_80min, inNChnk_80plus, inNChnk_80min);
            bl1Sig  = logical(fdr_bh(db1P));
           
            %Initializes the figure
            iFig = iFig + 1;
            hFIG(iFig)      = figure('Position', [100 100 1600 900], 'Visible', blVisible);
            cFIGNAME{iFig}  = sprintf('%s_%s', chBndLbl, cTHRESHOLD{iThr});
            
            %Sets the colors
            if ismember(chBndLbl, '15-30Hz'), cCOLOR = {[.5 .5 .5], [0 .2 1]};
            elseif ismember(chBndLbl, '30-80Hz'),  cCOLOR = {[.5 .5 .5], [1 .4 0]};
            else, cCOLOR =   {[.5 .5 .5], [.6 .2 .1]}; end
            
            hPLT(1) = NS_MeanErrPlot(db1Freq, db1MeanPwr_80min, db1SEMPwr_80min, cCOLOR{1});
            hPLT(2) = NS_MeanErrPlot(db1Freq, db1MeanPwr_80plus, db1SEMPwr_80plus, cCOLOR{2});
            dbY = -10; db1SigVec = nan(size(db1Freq)); db1SigVec(bl1Sig) = 1;
            hold on, plot(db1Freq, dbY * db1SigVec, 'k', 'LineWidth', 2);  
            ylabel('Power (dB)'); xlabel('Frequency (Hz)');
            legend(hPLT, {sprintf('<%.1f Hz', db80pct), sprintf('>%.1f Hz', db80pct)})
            title(sprintf('Mouse %d: %s: Powr vs %s Pulse Rate', sREC.inMouseID, datestr(sREC.chNlxSessionDir(1:10)), chBndLbl))
        end
    end
end

%Adds sREC to sCFG
sCFG.sREC = sREC;

%Keeps track of the input
sCFG.sINPUT.sL4MMDS.sPARAM = sINPUT_1.sPARAM;
sCFG.sINPUT.sL4MMDS.chScriptName = sINPUT_1.sL4MMDS.chScriptName;
sCFG.sINPUT.sL4MMDS.chTimeComputed = sINPUT_1.sL4MMDS.chTimeComputed;

%Stores the output vaariable in sCFG
sCFG.sL6.sBAND          = sBAND;
sCFG.sL6.inTopFreq      = inTopFreq;
sCFG.sL6.inSampleRate   = inSampleRate;
sCFG.sL6.db1Freq        = db1Freq;
sCFG.sL6.chScriptName   = mfilename('fullpath');
sCFG.sL6.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');
if blPlot
    savefig(hFIG, fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Fig));
    NS_SaveFig(fullfile(chDestPath, chDestMetaFolder, chSessionName), hFIG, cFIGNAME);
end

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('  Done! \n')
