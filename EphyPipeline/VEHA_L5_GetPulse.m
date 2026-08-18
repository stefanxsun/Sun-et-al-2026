function [varargout] = VEHA_L5_GetPulse(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks for LFP
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L4_MakeMetaDataStructure');
chMMDSFile = 'VEHA_L4_MakeMetaDataStructure.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chMMDSFile), 'file')
    error('%s does not exist for session %s in %s\r', chMMDSFile, chSessionName, chSourcePath_1)
end

%Checks the for visual stimulation meta structure
chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L2_MatchStimLogWithPresentationSet');
chMSLPSFile = 'VEHA_L2_MatchStimLogWithPresentationSet.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chMSLPSFile), 'file')
    error('%s does not exist for session %s in %s\r', chMSLPSFile, chSessionName, chSourcePath_2)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L5_GetPulse';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName))
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile_Mat  = 'VEHA_L5_GetPulse.mat';
% Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile_Mat, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

%Load the input
sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chMMDSFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
%Loads the input
sINPUT_2    = load(fullfile(chSourcePath_2, chSessionName, chMSLPSFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;   %visual stim
if ~isfield(sINPUT_2.sL2MSLPS.sSTIMLOG, 'sGRATING')
    rmdir(fullfile(chDestPath, chDestMetaFolder, chSessionName));
    fprintf('Gratings were not presented for %s\r', chSessionName)
    return
end
sGRATING = sINPUT_2.sL2MSLPS.sSTIMLOG.sGRATING;

%Get the overal sample rate
inSampleRate = sINPUT_1.sL4MMDS.inWorkSampleRate;

%Extract the LFP
db2LFP = sINPUT_1.sL4MMDS.db2LFP; %Exctracts the LFP matrix
db2LFP = VEHA_U_NormalizeLFP(db2LFP, inSampleRate); % Filters and z-scores the LFP
db2LFP = db2LFP(2:end, :); % Removes the first channel of the LFP which is set as the reference. We are left with 15 channels.
inNChan = size(db2LFP, 1); 

%If required high pass the LFP to remove low frequency movement components
if sCFG.sPARAM.blHPass_MovArtefact
    dbHighBound = sCFG.sPARAM.dbHighBound;
    [B, A] = butter(2, 2*dbHighBound/inSampleRate, 'high');
    db2LFP = filtfilt(B, A, db2LFP')';
end

%Chooses the reference channel for trough extractions
if isfield(sINPUT_1.sL4MMDS, 'db1ChannelDepth')
    db1ChannelDepth = sINPUT_1.sL4MMDS.db1ChannelDepth(2:end);
    [~, inRefChan] = min(abs(db1ChannelDepth - 374));
    %in1LayerDepth = [68; 306; 442; 714]; %if total depth = 1020 <----------- For reminder
else
    inRefChan = 5;
end

%Extracts the wheel time 
bl1WheelOn 	= sINPUT_1.sL4MMDS.bl1WheelOn;

%Extracts the stimulation times
[bl1FullCtr, in1PresOnIdx, in1PresOffIdx] = deal([]);

for iPrs = 1:length(sGRATING)
    %Aggregates presentation onset indices
    in1PresOnIdx    = cat(2, in1PresOnIdx, ...
        NS_GetTStampEventIndex(sINPUT_1.sL4MMDS.db1TStamps, sGRATING(iPrs).db1PresOnTStamp));
    in1PresOffIdx   = cat(2, in1PresOffIdx, ...
        NS_GetTStampEventIndex(sINPUT_1.sL4MMDS.db1TStamps, sGRATING(iPrs).db1PresOffTStamp));
end
        

%Gets full contrasts presentation if gratings were presented

dbStimMat = sGRATING.dbStimMat;
%%%% STEFAN ADDED 12/28/2023 to uniform the stimuli parameters %%%%%%%%%%%%
[SFs,~,~] = unique(dbStimMat(2,:));
[Size,~,~] = unique(dbStimMat(5,:));
[Ctr,~,~] = unique(dbStimMat(4,:));

dbStimMat(2,dbStimMat(2,:) == SFs(1)) =0.01;
dbStimMat(2,dbStimMat(2,:) == SFs(2)) =0.04;
dbStimMat(2,dbStimMat(2,:) == SFs(3)) =0.16;
dbStimMat(2,dbStimMat(2,:) == SFs(4)) =0.64;

dbStimMat(5,dbStimMat(5,:) == Size(1)) =5;
dbStimMat(5,dbStimMat(5,:) == Size(2)) =10;
dbStimMat(5,dbStimMat(5,:) == Size(3)) =20;
dbStimMat(5,dbStimMat(5,:) == Size(4)) =40;

% bl1FullCtrPres = dbStimMat(2, :) == .04 & dbStimMat(4, :) >= .32 & dbStimMat(5, :) >= 20;
bl1FullCtrPres = dbStimMat(4, :) >= .32;


bl1FullCtr 	= cat(2, bl1FullCtr, bl1FullCtrPres);
   
bl1FullCtr 		= logical(bl1FullCtr);
bl1Stim         = NS_MakeEpochVector(in1PresOnIdx, in1PresOffIdx, length(sINPUT_1.sL4MMDS.db1TStamps));
bl1StimFull     = NS_MakeEpochVector(in1PresOnIdx(bl1FullCtr), in1PresOffIdx(bl1FullCtr), length(sINPUT_1.sL4MMDS.db1TStamps));

%Computes states
bl1RunOnly 		= bl1WheelOn & ~bl1Stim; 
bl1StimOnly 	= ~bl1WheelOn & bl1StimFull; 
bl1Quiet		= ~bl1WheelOn & ~bl1Stim; 

%Extracts band parameters
cBAND       	= sCFG.sPARAM.cBAND;
cBAND_LABEL 	= sCFG.sPARAM.cBAND_LABEL;
cSTATE_LABEL    = sCFG.sPARAM.cSTATE;

%Set state vectors for each band
cSTATE 			= cell(size(cBAND_LABEL));
bl1Rem 			= false(size(cBAND_LABEL));

%Loops through bands of interest
for iBnd = 1:length(cBAND)
    % Choose the state of interest
    switch cSTATE_LABEL{iBnd}
        case 'Running'
           	cSTATE{iBnd}  	= bl1RunOnly;
        case 'Stim'
			cSTATE{iBnd} 	= bl1StimOnly;
        otherwise
            fprintf('%s state not recognized for Band %s ... skipped\r', cSTATE{iBnd}, cBAND{iBnd});
            bl1Rem(iBnd) = true;
    end
end
cBAND(bl1Rem) = []; cBAND_LABEL(bl1Rem) = []; cSTATE(bl1Rem) = []; cSTATE_LABEL(bl1Rem) = []; % Removes instances were the state was not recognized

%Initializes the output structure
sBAND = struct('db1Band', cell(1, length(cBAND)), 'chBandLabel', cell(1, length(cBAND)), 'chStateLabel', ...
	cell(1, length(cBAND)), 'in1Index', cell(1, length(cBAND)), 'db1Score', cell(1, length(cBAND)), ...
    'db1Score_Rnd', cell(1, length(cBAND)));
sBAND = struct('db1Band', cell(1, length(cBAND)), 'chBandLabel', cell(1, length(cBAND)), 'chStateLabel', ...
	cell(1, length(cBAND)), 'in1Index', cell(1, length(cBAND)), ...
	'db1Score', cell(1, length(cBAND)),  'db1Score_Rnd', cell(1, length(cBAND)),...
	'db1Power', cell(1, length(cBAND)), 'dbThreshold', cell(1, length(cBAND)));
%Loops through bands - get troughs - compute enrichment score and stores it in the output structure sBAND
for iBnd = 1:length(cBAND)
	
	% Computes a phase randomized surrogate LFP
	rng(1949); % Sets the seed for reproduciblr results
	[db2Coeff, db2LFP_Rnd] = pca(db2LFP');
	db2LFP_Rnd = CLAMS_U_PhaseRandomize1D(db2LFP_Rnd, 1);
	db2LFP_Rnd = (db2LFP_Rnd/db2Coeff)'; 
    
	% Computes troughs for the LFP and the phase randomized LFP
	sTROUGH	 	= CLAMS_L1_GetTrough(db2LFP, inSampleRate, cBAND{iBnd}, inRefChan, cBAND_LABEL{iBnd}, 'complex');
	sTRGH_RND 	= CLAMS_L1_GetTrough(db2LFP_Rnd, inSampleRate, cBAND{iBnd}, inRefChan, cBAND_LABEL{iBnd}, 'complex');
        
    % Computes the amplitude of the each trough  %% STEFAN added from other version
	db2Hilbert 	= complex(sTROUGH.db2Trough(:, 1:inNChan), sTROUGH.db2Trough(:, inNChan + 1:end));
	db1Power 	= sum(abs(db2Hilbert).^2, 2);
    
	% Computes the enrichment score of the troughs
	db1Score 		= CLAMS_U_EnrichmentScore(sTROUGH.db2Trough, cSTATE{iBnd}(sTROUGH.in1Index), bl1Quiet(sTROUGH.in1Index), ...
		sCFG.sPARAM.inNClu, sCFG.sPARAM.dbSigThrs);
	db1Score_Rnd 	= CLAMS_U_EnrichmentScore(sTRGH_RND.db2Trough, cSTATE{iBnd}(sTRGH_RND.in1Index), bl1Quiet(sTRGH_RND.in1Index), ...
		sCFG.sPARAM.inNClu, sCFG.sPARAM.dbSigThrs);
    dbThreshold 	= CLAMS_U_ScoreThreshold(sTROUGH.db2Trough, db1Score);

	% Store the output in a structure sBAND
	sBAND(iBnd).db1Band 		= cBAND{iBnd};
	sBAND(iBnd).chBandLabel 	= cBAND_LABEL{iBnd};
	sBAND(iBnd).chStateLabel 	= cSTATE_LABEL{iBnd};
	sBAND(iBnd).in1Index 		= sTROUGH.in1Index;
	sBAND(iBnd).db1Score 		= db1Score;
	sBAND(iBnd).db1Score_Rnd 	= db1Score_Rnd;
    sBAND(iBnd).db1Power 		= db1Power;   %%%STEFAN edited 12/28/23
	sBAND(iBnd).dbThreshold 	= dbThreshold;
end

%Keeps track of the input in CSG
sCFG.sINPUT.sL4MMDS.sPARAM          = sINPUT_1.sPARAM;
sCFG.sINPUT.sL4MMDS.chScriptName    = sINPUT_1.sL4MMDS.chScriptName;
sCFG.sINPUT.sL4MMDS.chTimeComputed  = sINPUT_1.sL4MMDS.chTimeComputed;

%Record the output
sCFG.sL5.sBAND              = sBAND;
sCFG.sL5.inSampleRate       = inSampleRate;
if isfield(sINPUT_1.sL4MMDS, 'db1ChannelDepth')
	sCFG.sL5.db1Depth       = db1ChannelDepth;
end
sCFG.sL5.inRefChan          = inRefChan;
sCFG.sL5.chScriptName       = mfilename('fullpath');
sCFG.sL5.chTimeComputed     = datestr(now);
sCFG.sL5.bl1StimFull       =bl1StimOnly;
sCFG.sL5.bl1WheelOn        =bl1RunOnly;
sCFG.sL5.bl1Quiet        =bl1Quiet;
%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
	varargout{1} = sCFG;
end

fprintf('Done! \r')
