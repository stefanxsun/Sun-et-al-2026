function [varargout] = VEHA_L6_Pulse_vs_MUA_PPC_Hilbert(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks for LFP
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L4_MakeMetaDataStructure');
chSrcFile1 = 'VEHA_L4_MakeMetaDataStructure.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chSrcFile1), 'file')
    error('%s does not exist for session %s in %s\n', chSrcFile1, chSessionName, chSourcePath_1)
end

%Checks for visual stimuli
chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L2_MatchStimLogWithPresentationSet');
chMSLPSFile = 'VEHA_L2_MatchStimLogWithPresentationSet.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chMSLPSFile), 'file')
    error('%s does not exist for session %s in %s\r', chMSLPSFile, chSessionName, chSourcePath_2)
end

%Checks for the pulses
chSourcePath_3 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L5_GetPulse');
chSrcFile3 = 'VEHA_L5_GetPulse.mat';
if ~exist(fullfile(chSourcePath_3, chSessionName, chSrcFile3), 'file')
    error('%s does not exist for session %s in %s\n', chSrcFile3, chSessionName, chSourcePath_3)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L6_Pulse_vs_MUA_PPC_Hilbert';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName))
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile_Mat  = 'VEHA_L6_Pulse_vs_MUA_PPC_Hilbert.mat';
% Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\n %s.\n Skipped...\n', chDestFile_Mat, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

%Checks for optional arguments -----------------------------------------------------------------------------------------
if isfield(sCFG.sPARAM, 'cTHRESHOLD'), cTHRESHOLD = sCFG.sPARAM.cTHRESHOLD;
else, cTHRESHOLD = {'MahalDNorm'}; sCFG.sPARAM.cTHRESHOLD = cTHRESHOLD; end
inNThr = length(cTHRESHOLD);
if isfield(sCFG.sPARAM, 'db1Freq'), db1Freq = sCFG.sPARAM.db1Freq;
else, db1Freq = 2:2:120; sCFG.sPARAM.db1Freq = db1Freq; end
inNFreq     = length(db1Freq);
if isfield(sCFG.sPARAM, 'inMrltSRate'), inMrltSRate = sCFG.sPARAM.inMrltSRate;
else, inMrltSRate = 250; sCFG.sPARAM.inMrltSRate = inMrltSRate; end
if isfield(sCFG.sPARAM, 'in1SpkRemInt_ms'), in1SpkRemInt_ms = sCFG.sPARAM.in1SpkRemInt_ms;
else, in1SpkRemInt_ms = [-3 7]; sCFG.sPARAM.in1SpkRemInt_ms = in1SpkRemInt_ms; end

%Loads the input -------------------------------------------------------------------------------------------------------
sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chSrcFile1), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
sINPUT_2 = load(fullfile(chSourcePath_2, chSessionName, chMSLPSFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;
sINPUT_3 = load(fullfile(chSourcePath_3, chSessionName, chSrcFile3), '-mat'); sINPUT_3 = sINPUT_3.sCFG;

%Extracts the input ----------------------------------------------------------------------------------------------------

%Extract the sample rate and time stamps
inSampleRate 	= sINPUT_1.sL4MMDS.inWorkSampleRate;
db1TStamps 		= sINPUT_1.sL4MMDS.db1TStamps;

%Checks if the wheel trace is present. Aborts if not
if isfield(sINPUT_1.sL4MMDS, 'bl1WheelOn')
    bl1WheelOn      = sINPUT_1.sL4MMDS.bl1WheelOn;
else
    fprintf('No wheel data has been detected for %s. Aborted\n', chSessionName)
    rmdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
    return
end

%Extracts the LFP and the MUA
db2LFP 			= sINPUT_1.sL4MMDS.db2LFP(2:16, :);
db2LFP 			= VEHA_U_NormalizeLFP(db2LFP, inSampleRate);
[inNSample, inNChan] = size(db2LFP);

%Extract multi units   %%%%%%%%%%STEFAN edited
MUA  = sINPUT_1.sL4MMDS.in2MUATrace;
layers = sINPUT_1.sL4MMDS.db1ChanLayer;

%Extract the band structure
sBAND 			= sINPUT_3.sL5.sBAND;
inNBnd 			= length(sINPUT_3.sL5.sBAND);
sBAND           = repmat(sBAND, inNThr, 1);
inRefChan 		= sINPUT_3.sL5.inRefChan;

%Computes baseline time when no presentation is on ---------------------------------------------------------------------

%Extracts the grating structure
sGRAT   = sINPUT_2.sL2MSLPS.sSTIMLOG.sGRATING;

%Extracts the stimulation times
[in1PresOnIdx, in1PresOffIdx] = deal([]);
for iPrs = 1:length(sGRAT)
    %Aggregates presentation onset indices
    in1PresOnIdx    = cat(2, in1PresOnIdx, ...
        NS_GetTStampEventIndex(sINPUT_1.sL4MMDS.db1TStamps, sGRAT(iPrs).db1PresOnTStamp));
    in1PresOffIdx   = cat(2, in1PresOffIdx, ...
        NS_GetTStampEventIndex(sINPUT_1.sL4MMDS.db1TStamps, sGRAT(iPrs).db1PresOffTStamp));
end

bl1Baseline  = ~NS_MakeEpochVector(in1PresOnIdx, in1PresOffIdx, length(sINPUT_1.sL4MMDS.db1TStamps));

%Computes presentation times for each type of grating presented --------------------------------------------------------

%Does an sorting of condition to initialiaze output Matrix
[db2Cond, in2PresIdx] = NS_SortTrials([sGRAT.dbStimMat]);
inNCnd  = size(in2PresIdx, 2);

%Creates a vector indexing the condition. The vector is -1 everywhere else
db1CondTSeries = -ones(size(bl1Baseline));
for iSet = 1:length(sGRAT)
    %Extract key variable to simplify code and aggregates spectrum
    %accros presentation sets
    in1PresOnIdx       = NS_GetTStampEventIndex(db1TStamps, sGRAT(iSet).db1PresOnTStamp);
    in1PresOffIdx      = NS_GetTStampEventIndex(db1TStamps, sGRAT(iSet).db1PresOffTStamp);

    %Extracts the condition matrix
    [db2CondPrs, in2PresIdxPrs] = NS_SortTrials(sGRAT(iSet).dbStimMat);
   
    %Finds the indices of each trials and aggregates accross
    %presentation sets
    for iCnd = 1:size(db2CondPrs, 2)
        % Computes an epoch vector for presentation of the condition of
        % interest
        bl1GratingOn            = NS_MakeEpochVector(in1PresOnIdx(in2PresIdxPrs(:, iCnd)), ...
            in1PresOffIdx(in2PresIdxPrs(:,iCnd)), inNSample);
        % Maps condition in the current presentation to the general
        % presentation and append presentations to the output structure
        inCndAll             		= find(all(db2Cond == db2CondPrs(:, iCnd), 1)); 
		db1CondTSeries(bl1GratingOn)	= inCndAll;
    end
end

%Computes pulses for each band and threshold ---------------------------------------------------------------------------

% Loops through trials and bands and aggregates the pulse data for each band
for iThr = 1:inNThr
	for iBnd = 1:inNBnd
	    %Extracts input variables
	    in1Index 		= sBAND(iThr, iBnd).in1Index;
	    db1Score 		= sBAND(iThr, iBnd).db1Score;
	    db1Score_Rnd 	= sBAND(iThr, iBnd).db1Score_Rnd;
	
	    %Extract the score threshold
        if strcmp(cTHRESHOLD{iThr}, 'MahalDNorm')
            dbScoreThreshold = sINPUT_3.sL5.sBAND(iBnd).dbThreshold;
        elseif strcmp(cTHRESHOLD{iThr}, 'ScoreRate')
            dbScoreThreshold = quantile(db1Score, 1 - (sum(db1Score)/length(db1Score)));
        elseif strcmp(cTHRESHOLD{iThr}, '3SDRandData')
            dbScoreThreshold = max(db1Score_Rnd) + (3 * std(db1Score_Rnd));
        else
            dbScoreThreshold = str2double(cTHRESHOLD{iThr});
        end
        sBAND(iThr, iBnd).chThreshold       = cTHRESHOLD{iThr};
	 
	    %Computes pulse vector
	    in1PulseIdx = in1Index(db1Score > dbScoreThreshold);
        sBAND(iThr, iBnd).in1PulseIdx       = in1PulseIdx;
	end
end

%Formats Unit related data ---------------------------------------------------------------------------------------------

%Initializes the cluster band structure
sBAND    = rmfield(sBAND, {'in1Index', 'db1Score', 'dbThreshold', 'db1Score_Rnd'});
[sBAND.bl1Bout]  = deal([]);

% Calculate the MUA count
layerTotal = 4;
MUAcount = nan(4,length(MUA));
layerCnt =0; 
for ilayer = [2 4 5 6]
    lyrIdx = layers == ilayer;
    layerCnt =layerCnt+1;
    MUAcount(layerCnt,:) = mean(MUA(lyrIdx,:), 1);
end

%%% add one more row to MUAcount and FRate etc, with all channels average
MUAcount = [MUAcount; mean(MUA, 1)];
layerCnt =layerCnt+1;

for iLyr = 1:layerCnt
    %Calculates the firing rate when the animals is quiet and when it runs
    %Get spike indices
    bl1SpkIdx      	= MUAcount(iLyr,:) ~= 0  ;
    bl1SpkRun   = bl1WheelOn(bl1SpkIdx);
    dbFRate     = sum(bl1SpkIdx) * inSampleRate / length(db1TStamps);
    dbFRate_Sit = sum(~bl1SpkRun) * inSampleRate / sum(~bl1WheelOn);  %% Stefan re-examined 03/20/2025, this is correct
    dbFRate_Run = sum(bl1SpkRun) * inSampleRate / sum(bl1WheelOn);
    
    % Determines if spikes were emited during a stimulation of a given
    % contrast and if it was a hit or a miss trial
    bl1SpkBas 	= bl1Baseline(bl1SpkIdx);
    db1SpkCnd   = db1CondTSeries(bl1SpkIdx);
    
    % Uptadates the cluster with the metrics and initializes the output
    % structure
    sMUA(iLyr).dbFRate      = dbFRate;
    sMUA(iLyr).dbFRate_Sit  = dbFRate_Sit;
    sMUA(iLyr).dbFRate_Run  = dbFRate_Run;
    sMUA(iLyr).bl1SpkRun    = bl1SpkRun;
    sMUA(iLyr).db1SpkCnd    = db1SpkCnd;
    sMUA(iLyr).bl1SpkBas    = bl1SpkBas;
    [sMUA(iLyr).sBAND] = deal(sBAND);
end

%Calculates PPC for each layer and each iteration of CLAMS --------------------------------------------------------------

% Iterates through bands
for iThr = 1:inNThr
    for iBnd = 1:inNBnd
        %Extracts data for the band of interest
        db1Band 		= sBAND(iThr, iBnd).db1Band;
        in1PulseIdx 	= sBAND(iThr, iBnd).in1PulseIdx;
        
        %Computes the phase and bouts for the iteration of CLAMS of interest
        [~, bl1Bout] = CLAMS_U_PulsePhase(db2LFP, inSampleRate, inRefChan, db1Band, in1PulseIdx);
        
        %Performs the Hilbert transform of the CSD and Vm
        %Sets the filters
        [B, A] = butter(2, 2 .* db1Band ./ inSampleRate);
        %Performs the morlet transfrom on the LFP
        cp2LFP_Analytic = hilbert(filtfilt(B, A, db2LFP'));
         
        for iLyr = 1:5
            bl1SpkIdx      	= MUAcount(iLyr,:) ~= 0  ;
            sMUA(iLyr).sBAND(iThr, iBnd).bl1Bout  = bl1Bout(bl1SpkIdx);
            
            %Computes the phase of spikes for each channel - the matrix is organized
            %(Spike x 1 x layer) to be compatible with the PPC function
            sMUA(iLyr).sBAND(iThr, iBnd).cp3Spk_STR = permute(cp2LFP_Analytic(bl1SpkIdx, :), [1 3 2]);
        end
    end
end

%Keeps track of the input in CSG
sCFG.sINPUT.sL4MMDS.sPARAM          	= sINPUT_1.sPARAM;
sCFG.sINPUT.sL4MMDS.chScriptName    	= sINPUT_1.sL4MMDS.chScriptName;
sCFG.sINPUT.sL4MMDS.chTimeComputed  	= sINPUT_1.sL4MMDS.chTimeComputed;
sCFG.sINPUT.sL5.sPARAM          		= sINPUT_3.sPARAM;
sCFG.sINPUT.sL5.chScriptName    		= sINPUT_3.sL5.chScriptName;
sCFG.sINPUT.sL5.chTimeComputed  		= sINPUT_3.sL5.chTimeComputed;

%Record the output
sCFG.sL6.sMUA        	    = sMUA;
sCFG.sL6.db2Cond 			= db2Cond;
sCFG.sL6.inSampleRate       = inSampleRate;
sCFG.sL6.chScriptName       = mfilename('fullpath');
sCFG.sL6.chTimeComputed     = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \n')
