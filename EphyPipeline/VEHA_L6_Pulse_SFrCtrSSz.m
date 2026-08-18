function [varargout] = VEHA_L6_Pulse_SFrCtrSSz(sCFG,sREC)
%%%%%%% STEFAN edited as it has two bug 1/9/2024
sCFG.sREC = sREC;

%Recreates the session folder name
chSessionName = strcat(sCFG.sREC.chNlxSessionDir, '_', num2str(sCFG.sREC.inRecNum));

%Checks for visual presentation
chSourcePath_0 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L2_MatchStimLogWithPresentationSet');
chDPSFile = 'VEHA_L2_MatchStimLogWithPresentationSet.mat';
if ~exist(fullfile(chSourcePath_0, chSessionName, chDPSFile), 'file')
    disp('%s does not exist for session %s in %s\r', chDPSFile, chSessionName, chSourcePath_0)
    blPres = false;
else
    blPres = true;
end
    
%Checks the for visual stimulation meta structure
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L4_MakeMetaDataStructure');
chMMDSFile = 'VEHA_L4_MakeMetaDataStructure.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chMMDSFile), 'file')
    error('%s does not exist for session %s in %s\r', chMMDSFile, chSessionName, chSourcePath_1)
end

%Checks the for the Morlet transform of the signal
chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L5_GetPulse');
chGPFile = 'VEHA_L5_GetPulse.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chGPFile), 'file')
    error('%s does not exist for session %s in %s\r', chGPFile, chSessionName, chSourcePath_2)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L6_Pulse_SFrCtrSSz';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile_Mat = 'VEHA_L6_Pulse_SFrCtrSSz.mat';
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'file') && ~sCFG.sPARAM.blOverwrite
	fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile_Mat, fullfile(chDestPath, chDestMetaFolder, chSessionName));
	return
else
    fprintf('Processing %s ...', chSessionName);
end

%Checks for optional arguments
if isfield(sCFG.sPARAM, 'cTHRESHOLD'), cTHRESHOLD = sCFG.sPARAM.cTHRESHOLD;
else, cTHRESHOLD = {'MahalDNorm', '3SDRandData', 'ScoreRate', '.30', '.50', '.70'}; sCFG.sPARAM.cTHRESHOLD = cTHRESHOLD; end
inNThr 	= length(cTHRESHOLD); 

%Load the input
sINPUT_0 = load(fullfile(chSourcePath_0, chSessionName, chDPSFile), '-mat'); 
sINPUT_0 = sINPUT_0.sCFG;  


%Loads the input
sINPUT_1    = load(fullfile(chSourcePath_1, chSessionName, chMMDSFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
if ~isfield(sINPUT_0.sL2MSLPS.sSTIMLOG, 'sGRATING')
    rmdir(fullfile(chDestPath, chDestMetaFolder, chSessionName));
    fprintf('Gratings were not presented for %s\r', chSessionName)
    return
end
sINPUT_2    = load(fullfile(chSourcePath_2, chSessionName, chGPFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;

%Extracts times stamps and sampling rate
db1TStamps      = sINPUT_1.sL4MMDS.db1TStamps;
inNSample       = length(db1TStamps);
inSampleRate    = sINPUT_1.sL4MMDS.inWorkSampleRate;

%Extracts the grating structure
sGRAT       =sINPUT_0.sL2MSLPS.sSTIMLOG.sGRATING;

%%%STEFAN ADDED 2024/1/18 to fix the problem of having wrong numbers of input in stimuli parameters
for iSet = 1:length(sGRAT)
    [SFs,~,~] = unique(sGRAT(iSet).dbStimMat(2,:));
    [Size,~,~] = unique(sGRAT(iSet).dbStimMat(5,:));
    
    sGRAT(iSet).dbStimMat(2,sGRAT(iSet).dbStimMat(2,:) == SFs(1)) =0.01;
    sGRAT(iSet).dbStimMat(2,sGRAT(iSet).dbStimMat(2,:) == SFs(2)) =0.04;
    sGRAT(iSet).dbStimMat(2,sGRAT(iSet).dbStimMat(2,:) == SFs(3)) =0.16;
    sGRAT(iSet).dbStimMat(2,sGRAT(iSet).dbStimMat(2,:) == SFs(4)) =0.64;
    
    sGRAT(iSet).dbStimMat(5,sGRAT(iSet).dbStimMat(5,:) == Size(1)) =5;
    sGRAT(iSet).dbStimMat(5,sGRAT(iSet).dbStimMat(5,:) == Size(2)) =10;
    sGRAT(iSet).dbStimMat(5,sGRAT(iSet).dbStimMat(5,:) == Size(3)) =20;
    sGRAT(iSet).dbStimMat(5,sGRAT(iSet).dbStimMat(5,:) == Size(4)) =40;
end

%Does an sorting of condition to initialiaze output Matrix
[db2Cond, in2PresIdx] = NS_SortTrials([sGRAT.dbStimMat]);
inNCnd  = size(in2PresIdx, 2);

%Initialize a structure indexing each condition
sCND_IDX    = struct('bl1Pres', repmat({false(size(db1TStamps))}, 1, inNCnd));   
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
        bl1Cnd                  = all(db2Cond == db2CondPrs(:, iCnd), 1); 
        sCND_IDX(bl1Cnd).bl1Pres   = sCND_IDX(bl1Cnd).bl1Pres | bl1GratingOn;
    end
end

%Extracts the states
bl1WheelOn  = sINPUT_1.sL4MMDS.bl1WheelOn;
%Extracts stimulation times from all presentation sets
bl1Stim         = NS_MakeEpochVector(in1PresOnIdx, in1PresOffIdx, length(db1TStamps));

bl1Baseline = ~bl1WheelOn & ~bl1Stim;

%Extracts the pulses
sBAND   = sINPUT_2.sL5.sBAND;
inNBnd 	= length(sBAND);

% Initializes output structure
sCOND  = struct('dbPowr', cell(1, inNCnd), 'dbZ_Powr', cell(1, inNCnd), ...
	'dbRate', cell(1, inNCnd), 'dbZ_Rate', cell(1, inNCnd));
sBAND   = struct('db1Band', cell(inNThr, inNBnd), 'chBandLabel', cell(inNThr, inNBnd), ...
	'chStateLabel', cell(inNThr, inNBnd), 'chThreshold', cell(inNThr, inNBnd), ...
    'dbBasPowr', cell(inNThr, inNBnd), 'dbBasPowr_SD', cell(inNThr, inNBnd), ...
    'dbBasRate', cell(inNThr, inNBnd), 'dbBasRate_SD', cell(inNThr, inNBnd), ...
	'sCOND', repmat({sCOND}, inNThr, inNBnd));

% Loops through bands
for iBnd = 1:inNBnd
   	
    %Extracts input variables
    in1Index 		= sINPUT_2.sL5.sBAND(iBnd).in1Index;
    db1Power 		= sINPUT_2.sL5.sBAND(iBnd).db1Power;
    db1Score 		= sINPUT_2.sL5.sBAND(iBnd).db1Score;
    db1Score_Rnd 	= sINPUT_2.sL5.sBAND(iBnd).db1Score_Rnd;

	% Loops through threshold
	for iThr = 1:inNThr

        %Extract the score threshold
        if strcmp(cTHRESHOLD{iThr}, 'MahalDNorm')
			dbScoreThreshold = sINPUT_2.sL5.sBAND(iBnd).dbThreshold;
        elseif strcmp(cTHRESHOLD{iThr}, 'ScoreRate')
            dbScoreThreshold = quantile(db1Score, 1 - (sum(db1Score)/length(db1Score)));
		elseif strcmp(cTHRESHOLD{iThr}, '3SDRandData')
			dbScoreThreshold = max(db1Score_Rnd) + (3 * std(db1Score_Rnd));
        else
            dbScoreThreshold = str2double(cTHRESHOLD{iThr});% Otherwise uses the score as weights
        end
    
        %Computes pulse vector
        bl1Pulse 	= false(1, size(db1TStamps, 2));
        in1PulseIdx = in1Index(db1Score > dbScoreThreshold); 
        bl1Pulse(in1PulseIdx) = true; %%%%%%% STEFAN edited as it was wrong 1/9/2024
		
		%Find pulse amplitude	
        db1PulsePowr 	= db1Power(db1Score > dbScoreThreshold);

	    %Keeps track of band and band label
	    sBAND(iThr, iBnd).db1Band 		= sINPUT_2.sL5.sBAND(iBnd).db1Band;
	    sBAND(iThr, iBnd).chBandLabel 	= sINPUT_2.sL5.sBAND(iBnd).chBandLabel;
	    sBAND(iThr, iBnd).chStateLabel 	= sINPUT_2.sL5.sBAND(iBnd).chStateLabel;
	    sBAND(iThr, iBnd).chThreshold 	= cTHRESHOLD{iThr};
	
		%Computes the baseline pulse rate
		db1BasPowr = db1PulsePowr(ismember(in1PulseIdx, find(bl1Baseline))); %%%%%%% STEFAN edited as it was wrong 1/9/2024
		dbBasPowr 		= mean(db1BasPowr);
		dbBasPowr_SD 	= std(db1BasPowr);
	    sBAND(iThr, iBnd).dbBasPowr 	= dbBasPowr;
	    sBAND(iThr, iBnd).dbBasPowr_SD 	= dbBasPowr_SD;

		%Computes the baseline pulse rate
		[dbBasRate, dbBasRate_SD] = BaselinePulseRate(bl1Pulse, bl1Baseline, inSampleRate);
	    sBAND(iThr, iBnd).dbBasRate 	= dbBasRate;
	    sBAND(iThr, iBnd).dbBasRate_SD 	= dbBasRate_SD;

		%Computes the mean pulse amplitude and pulse rate for each condition
		for iCnd = 1:inNCnd
			%Computes mean pulse amplitude
			db1CndPowr 	= db1PulsePowr(ismember(in1PulseIdx, find(sCND_IDX(iCnd).bl1Pres)));
			dbPowr 		= mean(db1CndPowr);
			dbZ_Powr 	= (dbPowr - dbBasPowr) ./ dbBasPowr_SD;
	    	sBAND(iThr, iBnd).sCOND(iCnd).dbPowr 	= dbPowr;
	    	sBAND(iThr, iBnd).sCOND(iCnd).dbZ_Powr 	= dbZ_Powr;
			%Computes mean pluse rate
			dbRate 	= sum(bl1Pulse & sCND_IDX(iCnd).bl1Pres) .* inSampleRate ./ sum(sCND_IDX(iCnd).bl1Pres);
			dbZ_Rate = (dbRate - dbBasRate) ./ (dbBasRate_SD ./ sqrt(sum(sCND_IDX(iCnd).bl1Pres))); 
	    	sBAND(iThr, iBnd).sCOND(iCnd).dbRate 	= dbRate;
	    	sBAND(iThr, iBnd).sCOND(iCnd).dbZ_Rate 	= dbZ_Rate;
		end
	end
end

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'sBAND', 'db2Cond', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('  Done! \r')

%----- Utility functions -----------------------------------------------------------------------------------------------
function [dbBasRate, dbBasRate_SD] = BaselinePulseRate(bl1Pulse, bl1Baseline, inSampleRate)
%Utility estimating the baseline rate and the S.D. of the rate of a set of pulse 
%over a given window of time using a binomial distribution
%---- WARNING ----: the s.d. is the for the rate over a single time sample. 
%To get an estimate of the S.D. over a window of time multiply the value by 
% 		1 / sqrt(inNSample) 
%where inNSample is the number of samples in the window.

%Computes the number of points in the baseline
inNSmpBas 	= sum(bl1Baseline);

%Computes the number of pulses in the baseline
inNPlsBas 	= sum(bl1Pulse & bl1Baseline);

%Estimates the rate and variance of the rate using a binomial distribution 
dbP 	= inNPlsBas / inNSmpBas;
dbSD 	= sqrt(dbP * (1 - dbP)); 

%Scales the rate and SD
dbBasRate 		= dbP * inSampleRate;
dbBasRate_SD	= dbSD * inSampleRate;

% Old version ------
% in1PulseIdx = find(bl1Pulse);
% bl1BasPulse = bl1Baseline(in1PulseIdx);
% 
% db1_1onISI  	= inSampleRate ./ diff(in1PulseIdx);
% bl1Sel 			= bl1BasPulse(1:end - 1) & bl1BasPulse(2:end);
% dbBasRate 		= mean(db1_1onISI(bl1Sel));
% dbBasRate_SD 	= std(db1_1onISI(bl1Sel));
