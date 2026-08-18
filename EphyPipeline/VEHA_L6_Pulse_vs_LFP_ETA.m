function [varargout] = VEMA_L6_Pulse_vs_LFP_ETA(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the for visual stimulation meta structure
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEMA_L4_MakeMetaDataStructure');
chG_MDSFile = 'VEMA_L4_MakeMetaDataStructure.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chG_MDSFile), 'file')
    error('%s does not exist for session %s in %s\n', chG_MDSFile, chSessionName, chSourcePath_1)
end

%Checks the for visual stimulation meta structure
chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEMA_L5_GetPulse');
chGPFile = 'VEMA_L5_GetPulse.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chGPFile), 'file')
    error('%s does not exist for session %s in %s\n', chGPFile, chSessionName, chSourcePath_2)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEMA_L6_Pulse_vs_LFP_ETA';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile_Mat = 'VEMA_L6_Pulse_vs_LFP_ETA.mat';
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
if isfield(sCFG.sPARAM, 'dbWinLenSec'), dbWinLenSec = sCFG.sPARAM.dbWinLenSec;
else, dbWinLenSec = .4; sCFG.sPARAM.inNCycle_ETA = dbWinLenSec; end

%Loads the input -------------------------------------------------------------------------------------------------------
sINPUT_1    = load(fullfile(chSourcePath_1, chSessionName, chG_MDSFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
sINPUT_2   	= load(fullfile(chSourcePath_2, chSessionName, chGPFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;

%Extracts the input ----------------------------------------------------------------------------------------------------

%Extract the sample rate and time stamps
inSampleRate 	= sINPUT_1.sL4MMDS.inWorkSampleRate;
db1TStamps 		= sINPUT_1.sL4MMDS.db1TStamps;

%Extract LFP 
db2LFP 			= sINPUT_1.sL4MMDS.db2LFP;
db2LFP 			= VEMA_U_NormalizeLFP(db2LFP, inSampleRate, 2:size(db2LFP, 1));

%Gets depth and layers if recorded
if isfield(sINPUT_1.sL4MMDS, 'db1ChannelDepth')
	blLyr = true;
    db1ChannelDepth = sINPUT_1.sL4MMDS.db1ChannelDepth(2:end);
    %in1LayerDepth = [68; 306; 442; 714]; %if total depth = 1020 <----------- For reminder
end

%Extract the band structure
sBND_IN 	= sINPUT_2.sL5.sBAND;
inNBnd 		= length(sBND_IN);

%Computes LFP pulse triggered average for each band in VEMA_L5_GetPulse -------------------------------------------------

%Initialize the output structure
sBAND 	= struct('chBandLabel', cell(inNThr, inNBnd), 'chStateLabel', cell(inNThr, inNBnd), ...
	'chThreshold', cell(inNThr, inNBnd), 'db1ETA_Time', cell(inNThr, inNBnd), ...
	'db2ETA', cell(inNThr, inNBnd), 'db2ETSD', cell(inNThr, inNBnd), ...
    'db2ETA_Rnd', cell(inNThr, inNBnd), 'db2ETSD_Rnd', cell(inNThr, inNBnd), ...
	'inNEvt', cell(inNThr, inNBnd));

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
	 
	    %Computes index vectors for pulse and computes the event triggered average
	    in1PulseIdx = in1Index(db1Score > dbScoreThreshold);
 		[db2ETA, db2ETSD, inNEvt, db1ETA_Time] = NS_ETA(db2LFP, inSampleRate, in1PulseIdx, [-1 1] .* dbWinLenSec);
        
        %Selects some random troughs and computes the event triggered average
	    %in1RndPIdx = in1Index(sort(datasample(1:length(in1Index), inNEvt, 'Replace', false)));
        %[db2ETA_Rnd, db2ETSD_Rnd] = NS_ETA(db2LFP, inSampleRate, in1RndPIdx, [-1 1] .* dbWinLenSec);
        %Alternatively, selects a random set of points on the recording
	    in1RndPIdx = sort(datasample(1:size(db2LFP, 2), inNEvt, 'Replace', false));
        [db2ETA_Rnd, db2ETSD_Rnd] = NS_ETA(db2LFP, inSampleRate, in1RndPIdx, [-1 1] .* dbWinLenSec);

		%Stores variable indexing the band, what state and threshold were
		%used to define CLAMS pulses
		sBAND(iThr, iBnd).chBandLabel 		= sBND_IN(iThr, iBnd).chBandLabel;
		sBAND(iThr, iBnd).chStateLabel 		= sBND_IN(iThr, iBnd).chStateLabel;
		sBAND(iThr, iBnd).chThreshold 		= cTHRESHOLD{iThr};

		%Stores variable indexing the band, what state and threshold were
		%used to define CLAMS pulses
		sBAND(iThr, iBnd).db1ETA_Time 		= db1ETA_Time;
		sBAND(iThr, iBnd).db2ETA 			= db2ETA;
		sBAND(iThr, iBnd).db2ETSD 			= db2ETSD;
        sBAND(iThr, iBnd).db2ETA_Rnd        = db2ETA_Rnd;
		sBAND(iThr, iBnd).db2ETSD_Rnd 		= db2ETSD_Rnd;
		sBAND(iThr, iBnd).inNEvt 			= inNEvt;
	end
end

%Add sREC to sCFG for record
sCFG.sREC = sREC;

%Keeps track of the input
sCFG.sINPUT.sL4MMDS.sPARAM 			= sINPUT_1.sPARAM;
sCFG.sINPUT.sL4MMDS.chScriptName 	= sINPUT_1.sL4MMDS.chScriptName;
sCFG.sINPUT.sL4MMDS.chTimeComputed 	= sINPUT_1.sL4MMDS.chTimeComputed;
sCFG.sINPUT.sL5.sPARAM 				= sINPUT_2.sPARAM;
sCFG.sINPUT.sL5.chScriptName 		= sINPUT_2.sL5.chScriptName;
sCFG.sINPUT.sL5.chTimeComputed 		= sINPUT_2.sL5.chTimeComputed;

%Stores the output vaariable in sCFG
sCFG.sL6.sBAND             = sBAND;
sCFG.sL6.db1ChannelDepth   = db1ChannelDepth;
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