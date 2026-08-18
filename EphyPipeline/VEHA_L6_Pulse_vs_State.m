function [varargout] = VEHA_L6_Pulse_vs_State(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the for visual stimulation meta structure
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L5_GetPulse');
chGPFile = 'VEHA_L5_GetPulse.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chGPFile), 'file')
    error('%s does not exist for session %s in %s\n', chGPFile, chSessionName, chSourcePath_1)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L6_Pulse_vs_State';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile_Mat = 'VEHA_L6_Pulse_vs_State.mat';
%Checks that the data do not exist
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
if isfield(sCFG.sPARAM, 'dbConvWinSec'), dbConvWinSec = sCFG.sPARAM.dbConvWinSec;
else, dbConvWinSec = .1; sCFG.sPARAM.dbConvWinSec = dbConvWinSec; end
if isfield(sCFG.sPARAM, 'db1ETAWinSec'), db1ETAWinSec = sCFG.sPARAM.db1ETAWinSec;
else, db1ETAWinSec = [-1 3]; sCFG.sPARAM.db1ETAWinSec = db1ETAWinSec; end

%Loads the input -------------------------------------------------------------------------------------------------------
sINPUT_1   	= load(fullfile(chSourcePath_1, chSessionName, chGPFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;

%Extracts the input ----------------------------------------------------------------------------------------------------

%Extract the sample rate and time stamps
inSampleRate 	= sINPUT_1.sL5.inSampleRate;

%Extract the band structure
sBND_IN 	= sINPUT_1.sL5.sBAND;
inNBnd 		= length(sBND_IN);

%Extracts states
bl1Stim 	= sINPUT_1.sL5.bl1StimFull;
bl1Run 		= sINPUT_1.sL5.bl1WheelOn;

%Computes LFP pulse triggered average for each band in VEHA_L5_GetPulse -------------------------------------------------

%Initialize the output structure
sBAND 	= struct('chBandLabel', cell(inNThr, inNBnd), 'chStateLabel', cell(inNThr, inNBnd), ...
	'chThreshold', cell(inNThr, inNBnd), 'db1ETA_Time', cell(inNThr, inNBnd), ...
	'db1ETA', cell(inNThr, inNBnd), 'db1ETSD', cell(inNThr, inNBnd), ...
	'inNEvt', cell(inNThr, inNBnd), 'dbRateIn', cell(inNThr, inNBnd), ... 
	'dbRateOut', cell(inNThr, inNBnd));

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
		
		%Gets the state of interest
		if strcmp(sBND_IN(iBnd).chStateLabel, 'Stim')
			bl1State = bl1Stim;
		elseif strcmp(sBND_IN(iBnd).chStateLabel, 'Running')
			bl1State = bl1Run;
		else
			fprintf('State: %s non recognized in sBAND(%d)', sBND(iBnd).chaStateLabel, iBnd);
			continue;
		end

		%Gets the onsets of the state of interest
		in1StateOnIdx = 1 + find(diff(bl1State) == 1);

	    %Computes index vectors for pulse (P) and trough out of pulse (TO) 
	    in1PulseIdx = in1Index(db1Score > dbScoreThreshold);
        bl1Pulse    = false(1, size(bl1State, 2));
        bl1Pulse(in1PulseIdx) = true;

		%Smooth the pulse rate by computing a moving average
        db1Win          = rectwin(dbConvWinSec .* inSampleRate);
        db1PulseRate    = conv(double(bl1Pulse), db1Win, 'same')./dbConvWinSec;

		%Computes the event triggered average
 		[db1ETA, db1ETSD, inNEvt, db1ETA_Time] = NS_ETA(db1PulseRate, inSampleRate, in1StateOnIdx, db1ETAWinSec);

		%Stores variable indexing the band, what state and threshold were
		%used to define CLAMS pulses
		sBAND(iThr, iBnd).chBandLabel 		= sBND_IN(iBnd).chBandLabel;
		sBAND(iThr, iBnd).chStateLabel 		= sBND_IN(iBnd).chStateLabel;
		sBAND(iThr, iBnd).chThreshold 		= cTHRESHOLD{iThr};

		%Stores variables related to the ETA of the pulse rate to state onset
		sBAND(iThr, iBnd).db1ETA_Time 		= db1ETA_Time;
		sBAND(iThr, iBnd).db1ETA 			= db1ETA;
		sBAND(iThr, iBnd).db1ETSD 			= db1ETSD;
		sBAND(iThr, iBnd).inNEvt 			= inNEvt;
   
		%Stores the rate of the pulses in and out of the state of interest
		sBAND(iThr, iBnd).dbRateIn 			= sum(bl1Pulse(bl1State)) .* inSampleRate ./ sum(bl1State);
		sBAND(iThr, iBnd).dbRateOut 		= sum(bl1Pulse(~bl1State)) .* inSampleRate ./ sum(~bl1State);
	end
end

%Add sREC to sCFG for record
sCFG.sREC = sREC;

%Keeps track of the input
sCFG.sINPUT.sL5.sPARAM 				= sINPUT_1.sPARAM;
sCFG.sINPUT.sL5.chScriptName 		= sINPUT_1.sL5.chScriptName;
sCFG.sINPUT.sL5.chTimeComputed 		= sINPUT_1.sL5.chTimeComputed;

%Stores the output vaariable in sCFG
sCFG.sL6.sBAND             = sBAND;
sCFG.sL6.inSampleRate      = inSampleRate;
sCFG.sL6.chScriptName      = mfilename('fullpath');
sCFG.sL6.chTimeComputed    = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('  Done! \n')
