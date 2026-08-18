function [varargout] = VEHA_L6_Pulse_vs_MUA_ETA(sCFG, sREC)
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

%Checks for Single units
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
chDestMetaFolder = 'VEHA_L6_Pulse_vs_MUA_ETA';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder);
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName))
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile_Mat  = 'VEHA_L6_Pulse_vs_MUA_ETA.mat';
% Checks that the data do not exist
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
if isfield(sCFG.sPARAM, 'inNBin'), inNBin = sCFG.sPARAM.inNBin;
else, inNBin = 20; sCFG.sPARAM.inNBin = inNBin; end
if isfield(sCFG.sPARAM, 'inNCycle'), inNCycle = sCFG.sPARAM.inNCycle;
else, inNCycle = 2; sCFG.sPARAM.inNCycle = inNCycle; end

%Loads the input -------------------------------------------------------------------------------------------------------
sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chSrcFile1), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
sINPUT_2 = load(fullfile(chSourcePath_2, chSessionName, chMSLPSFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;   %visual stim
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
db2LFP 			= sINPUT_1.sL4MMDS.db2LFP;
db2LFP 			= VEHA_U_NormalizeLFP(db2LFP, inSampleRate);
[inNSample, inNChan] = size(db2LFP);

%Extract multi units   %%%%%%%%%%STEFAN edited
sMUA.MUA  = sINPUT_1.sL4MMDS.in2MUATrace;
sMUA.layer = sINPUT_1.sL4MMDS.db1ChanLayer;

%Extract the band structure
sBAND 			= sINPUT_3.sL5.sBAND;
inNBnd 			= length(sINPUT_3.sL5.sBAND);
sBAND           = repmat(sBAND, inNThr, 1);

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

%Computes presentation times for each type of grating presented --------------------------------------------------------

%Does an sorting of condition to initialiaze output Matrix
[db2Cond, in2PresIdx] = NS_SortTrials([sGRAT.dbStimMat]);
inNCnd  = size(in2PresIdx, 2);

%Creates a vector indexing the condition. The vector is -1 everywhere else
db1CondTSeries = -ones(size(db1TStamps));
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

% Defines states
in1FullPresIdx 	= find(db2Cond(2, :) <= .16 & db2Cond(4, :) >= .32 & db2Cond(5, :) >= 20);   %% arbituary choice Stefan examined 2024/09/18
bl1Stim 		= ismember(db1CondTSeries, in1FullPresIdx);
bl1Baseline 	= ~bl1WheelOn & db1CondTSeries == -1;

%Computes pulses for each band and threshold ---------------------------------------------------------------------------

% Loops through trials and bands and aggregates the pulse data for each band
for iThr = 1:inNThr
	for iBnd = 1:inNBnd
	    %Extracts input variables
	    in1Index 		= sINPUT_3.sL5.sBAND(iBnd).in1Index;
	    db1Score 		= sINPUT_3.sL5.sBAND(iBnd).db1Score;
	    db1Score_Rnd 	= sINPUT_3.sL5.sBAND(iBnd).db1Score_Rnd;
	
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
	    in1PulseIdx 	= in1Index(db1Score > dbScoreThreshold);
		in1OutTrough 	= in1Index(db1Score < dbScoreThreshold);
        sBAND(iThr, iBnd).in1PulseIdx       = in1PulseIdx;
        sBAND(iThr, iBnd).in1OutTrough      = in1OutTrough;
	end
end

%Formats Unit related data ---------------------------------------------------------------------------------------------

%Initializes the cluster band structure  
sBND_CLU    = sBAND;
sBND_CLU    = rmfield(sBND_CLU, {'in1Index', 'db1Score', 'dbThreshold', 'db1Score_Rnd'});
[sMUA.sBAND] = deal(sBND_CLU);

%Sets conditions
cCOND 	= {'Baseline', 'Stimulation', 'Running', 'All'};
inNCnd 	= length(cCOND);

%Intiallize 
%Creates a MUA trace
%Calculates the mean and sd of the intertrials interval during baseline
% STEFAN EDITED 06/25 to calculate for each layer (only 2 ,4, 5 and 6)

% this orignial version would be ideal but don't always have layer 1 data so just discard layer 1
% layerTotal = length(unique(sMUA.layer)); 
% MUAcount = nan(layerTotal,length(sMUA.MUA)); 
% layerCnt =0; 
% for ilayer = unique(sMUA.layer)
%     lyrIdx = sMUA.layer == ilayer;
%     layerCnt =layerCnt+1;
%     MUAcount(layerCnt,:) = sum(sMUA.MUA(lyrIdx,:), 1);
%     [dbFRate(layerCnt,:), dbFRate_SD(layerCnt,:)] = BaselinePulseRate(MUAcount(layerCnt,:), inSampleRate);
%     sMUA.dbFRate(layerCnt,:)      = dbFRate(layerCnt,:);
%     sMUA.dbFRate_SD(layerCnt,:)   = dbFRate_SD(layerCnt,:);
% end
layerTotal = 5;
MUAcount = nan(4,length(sMUA.MUA));
layerCnt =0; 
for ilayer = [2 4 5 6]
    lyrIdx = sMUA.layer == ilayer;
    layerCnt =layerCnt+1;
    MUAcount(layerCnt,:) = mean(sMUA.MUA(lyrIdx,:), 1);
    [dbFRate(layerCnt,:), dbFRate_SD(layerCnt,:)] = BaselinePulseRate(MUAcount(layerCnt,:), inSampleRate);
    sMUA.dbFRate(layerCnt,:)      = dbFRate(layerCnt,:);
    sMUA.dbFRate_SD(layerCnt,:)   = dbFRate_SD(layerCnt,:);
end

%%% add one more row to MUAcount and FRate etc, with all channels average
MUAcount = [MUAcount; mean(sMUA.MUA, 1)];
[dbFRate(layerCnt+1), dbFRate_SD(layerCnt+1)] = BaselinePulseRate(MUAcount(layerCnt+1, bl1Baseline), inSampleRate);
sMUA.dbFRate(layerCnt+1,:)      = dbFRate(layerCnt+1,:);
sMUA.dbFRate_SD(layerCnt+1,:)   = dbFRate_SD(layerCnt+1,:);

%Loops through band and threshold
for iThr = 1:inNThr
    for iBnd = 1:inNBnd
        %Defines the ETA window
        dbPeriod_sec    = ceil(1 ./ median(sBAND(iBnd).db1Band) * 100) ./ 100; %Period in s ceiled to the closest centesimal
        db1ETA_WinSec   = [-.5 .5] * inNCycle * dbPeriod_sec;
        
        %Gets pulse on non pulse troughs indices
        in1PulseIdx       = sBAND(iThr, iBnd).in1PulseIdx;
        in1OutTrough      = sBAND(iThr, iBnd).in1OutTrough;
        rng(11); % Sets the seed for reproduciblr results. Stefan 2024/09/18
        in1PulseIdxRnd    = randi([100 length(db1TStamps)-100], 1, length(in1PulseIdx));% create random index that has the same length with pulse index 
        in1PulseIdxRnd    = sort(in1PulseIdxRnd);
        
        %Loops over conditions
        for iCnd = 1:inNCnd
            
            %Loops over conditions
            if strcmp(cCOND{iCnd}, 'Baseline'), bl1Cnd = bl1Baseline;
            elseif strcmp(cCOND{iCnd}, 'Stimulation'), bl1Cnd = bl1Stim;
            elseif strcmp(cCOND{iCnd}, 'Running'), bl1Cnd = bl1WheelOn;
            elseif strcmp(cCOND{iCnd}, 'All'), bl1Cnd = true(size(bl1Baseline));
            end
            
            %Defines the pulses and the trough oustsides of pulses
            in1Pulse_Cnd	= in1PulseIdx(bl1Cnd(in1PulseIdx));
            in1OutT_Cnd 	= in1OutTrough(bl1Cnd(in1OutTrough));
            in1PulseRnd_Cnd	= in1PulseIdxRnd(bl1Cnd(in1PulseIdxRnd));
            
            %Computes the ETA
            [db1ETA_In, ~, inNEvt_In, db1Time] = NS_ETA(MUAcount, inSampleRate, in1Pulse_Cnd, db1ETA_WinSec);
            [db1ETA_Out, ~, inNEvt_Out] = NS_ETA(MUAcount, inSampleRate, in1OutT_Cnd, db1ETA_WinSec);
            [db1ETA_Rnd, ~, inNEvt_Rnd] = NS_ETA(MUAcount, inSampleRate, in1PulseRnd_Cnd, db1ETA_WinSec);
            
            %Compute the ETA histogram by binning it
            [db1ETA_H_In_Raw, db1ETA_H_Out_Raw, db1ETA_H_Rnd_Raw] = deal(nan(layerTotal, inNBin));
            db1ETA_H_Time = deal(nan(1, inNBin));
            inBinNSmp 	= (length(db1Time) - 1) ./ inNBin;
            in1RelIdx 	= 1:inBinNSmp;
            in1StartIdx = 1:inBinNSmp:length(db1Time) - inBinNSmp;
            for iBin = 1:inNBin
                bl1Bin = in1StartIdx(iBin) + in1RelIdx;
                db1ETA_H_In_Raw(:,iBin) 	= sum(db1ETA_In(:,bl1Bin),2);
                db1ETA_H_Out_Raw(:,iBin) 	= sum(db1ETA_Out(:,bl1Bin),2);
                db1ETA_H_Rnd_Raw(:,iBin) 	= sum(db1ETA_Rnd(:,bl1Bin),2);
                db1ETA_H_Time(iBin) 	= median(db1Time(bl1Bin));
            end
            %Transform raws histomgrams to get the absolute spike count
            db1Spk_H_In 	= db1ETA_H_In_Raw * inNEvt_In;
            db1Spk_H_Out 	= db1ETA_H_Out_Raw * inNEvt_Out;
            db1Spk_H_Rnd 	= db1ETA_H_Rnd_Raw * inNEvt_Rnd;
            
            %Transform raws histomgrams to get the average spike rate
            db1ETA_H_In 	= db1ETA_H_In_Raw * inSampleRate ./ inBinNSmp;
            db1ETA_H_Out 	= db1ETA_H_Out_Raw * inSampleRate ./ inBinNSmp;
            db1ETA_H_Rnd 	= db1ETA_H_Rnd_Raw * inSampleRate ./ inBinNSmp;
            
            %Normalizes the bin histogram by bin counts
            db1ETA_H_Nrm_In 	= (db1ETA_H_In - dbFRate) ./ (dbFRate_SD ./ sqrt(inBinNSmp .* inNEvt_In));
            db1ETA_H_Nrm_Out 	= (db1ETA_H_Out - dbFRate) ./ (dbFRate_SD ./ sqrt(inBinNSmp .* inNEvt_Out));
            db1ETA_H_Nrm_Rnd 	= (db1ETA_H_Rnd - dbFRate) ./ (dbFRate_SD ./ sqrt(inBinNSmp .* inNEvt_Rnd));
            
            %Appends ETA variables to the output structure
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1Spk_H_In 		= db1Spk_H_In;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1Spk_H_Out 		= db1Spk_H_Out;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1Spk_H_Rnd 		= db1Spk_H_Rnd;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1ETA_In 			= db1ETA_In;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).inNEvt_In 			= inNEvt_In;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1ETA_H_In 		= db1ETA_H_In;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1ETA_H_Nrm_In 	= db1ETA_H_Nrm_In;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1ETA_Out 		= db1ETA_Out;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).inNEvt_Out 		= inNEvt_Out;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1ETA_H_Out 		= db1ETA_H_Out;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1ETA_H_Nrm_Out 	= db1ETA_H_Nrm_Out;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1ETA_Rnd 			= db1ETA_Rnd;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).inNEvt_Rnd 			= inNEvt_Rnd;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1ETA_H_Rnd 		= db1ETA_H_Rnd;
            sMUA.sBAND(iThr, iBnd).sCOND(iCnd).db1ETA_H_Nrm_Rnd 	= db1ETA_H_Nrm_Rnd;
        end
        sMUA.sBAND(iThr, iBnd).inBinNSmp 		= inBinNSmp;
        sMUA.sBAND(iThr, iBnd).db1Time 		= db1Time;
        sMUA.sBAND(iThr, iBnd).db1ETA_H_Time 	= db1ETA_H_Time;
    end
end

%Keeps track of the input in CSG
sCFG.sINPUT.sL4MMDS.sPARAM          	= sINPUT_1.sPARAM;
sCFG.sINPUT.sL4MMDS.chScriptName    	= sINPUT_1.sL4MMDS.chScriptName;
sCFG.sINPUT.sL4MMDS.chTimeComputed  	= sINPUT_1.sL4MMDS.chTimeComputed;
sCFG.sINPUT.sL5.sPARAM          		= sINPUT_3.sPARAM;
sCFG.sINPUT.sL5.chScriptName    		= sINPUT_3.sL5.chScriptName;
sCFG.sINPUT.sL5.chTimeComputed  		= sINPUT_3.sL5.chTimeComputed;

%Keeps track of the output
sCFG.sL6.sMUA       = sMUA;
sCFG.sL6.cCOND       	= cCOND;
sCFG.sL6.inSampleRate   = inSampleRate;
sCFG.sL6.chScriptName   = mfilename('fullpath');
sCFG.sL6.chTimeComputed = datestr(now);

%Adds sREC to the output
sCFG.sREC = sREC;

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \n');
end
function [dbBasRate, dbBasRate_SD] = BaselinePulseRate(bl1Pulse, inSampleRate)
%Utility estimating the baseline rate and the S.D. of the rate of a set of pulse 
%over a given window of time using a binomial distribution
%---- WARNING ----: the s.d. is the for the rate over a single time sample. 
%To get an estimate of the S.D. over a window of time multiply the value by 
% 		1 / sqrt(inNSample) 
%where inNSample is the number of samples in the window.

%Computes the number of points in the baseline
inNSmpBas 	= length(bl1Pulse);

%Computes the number of pulses in the baseline
inNPlsBas 	= sum(bl1Pulse);

%Estimates the rate and variance of the rate using a binomial distribution 
dbP 	= inNPlsBas / inNSmpBas;
dbSD 	= sqrt(dbP * (1 - dbP)); 

%Scales the rate and SD
dbBasRate 		= dbP * inSampleRate;
dbBasRate_SD	= dbSD * inSampleRate;
end