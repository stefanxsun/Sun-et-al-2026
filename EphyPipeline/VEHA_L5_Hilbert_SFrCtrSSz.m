function [varargout] = VEHA_L5_Hilbert_SFrCtrSSz(sCFG)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sCFG.sREC.chNlxSessionDir, '_', num2str(sCFG.sREC.inRecNum));

%Checks the for visual stimulation meta structure
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L2_MatchStimLogWithPresentationSet');
chMSLPSFile = 'VEHA_L2_MatchStimLogWithPresentationSet.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chMSLPSFile), 'file')
    error('%s does not exist for session %s in %s\r', chMSLPSFile, chSessionName, chSourcePath_1)
end

%Checks the for L4
chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L4_MakeMetaDataStructure');
chMMDSFile = 'VEHA_L4_MakeMetaDataStructure.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chMMDSFile), 'file')
    error('%s does not exist for session %s in %s\r', chMMDSFile, chSessionName, chSourcePath_2)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L5_Hilbert_SFrCtrSSz';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile_Mat = 'VEHA_L5_Hilbert_SFrCtrSSz.mat';
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'file') && ~sCFG.sPARAM.blOverwrite
	fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile_Mat, fullfile(chDestPath, chDestMetaFolder, chSessionName));
	return
else
    fprintf('Processing %s ...', chSessionName);
end

%Checks for optional arguments
if isfield(sCFG.sPARAM, 'cBAND'), cBAND = sCFG.sPARAM.cBAND;
else, cBAND = {[4 7] [15 30], [30 80]}; sCFG.sPARAM.cBAND = cBAND; end
inNBnd 	= length(cBAND);

%Loads the input
sINPUT_1    = load(fullfile(chSourcePath_1, chSessionName, chMSLPSFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;   %visual stim
if ~isfield(sINPUT_1.sL2MSLPS.sSTIMLOG, 'sGRATING')
    rmdir(fullfile(chDestPath, chDestMetaFolder, chSessionName));
    fprintf('Gratings were not presented for %s\r', chSessionName)
    return
end
sINPUT_2    = load(fullfile(chSourcePath_2, chSessionName, chMMDSFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;  %LFP and MUA data
chanLayer = sINPUT_2.sL4MMDS.db1ChanLayer;  %% ADDED by STEFAN

%Extracts times stamps and sampling rate
db1TStamps      = sINPUT_2.sL4MMDS.db1TStamps;
inNSample       = length(db1TStamps);
inSampleRate   	= sINPUT_2.sL4MMDS.inWorkSampleRate;

%Extract the LFP
db2LFP = sINPUT_2.sL4MMDS.db2LFP; %Exctracts the LFP matrix
db2LFP = db2LFP(2:end, :); % Removes the first channel of the LFP which is set as the reference. We are left with 15 channels.
chanLayer = chanLayer(2:end); %% ADDED by STEFAN

%%% select layers   temporarily modified by Stefan 07/31/2025
% db2LFP = db2LFP(chanLayer==4, :);
% chanLayer  = chanLayer(chanLayer==4);
%%%

db2zLFP=[];
[db2LFP, db2zLFP] = VEHA_U_NormalizeLFP(db2LFP, inSampleRate); % Filters and z-scores the LFP

%Extracts the grating structure
sGRAT       = sINPUT_1.sL2MSLPS.sSTIMLOG.sGRATING;

%%%% STEFAN edited to fix the stupid problem from old data set where
%%%% sometimes there are two stimuli log
if length(sGRAT)>1
    NewGRAT = sGRAT(1);
    for i = 2: length(sGRAT)
       NewGRAT.sPARAM.NumberOfPresentations = NewGRAT.sPARAM.NumberOfPresentations  + sGRAT(i).sPARAM.NumberOfPresentations;
       NewGRAT.dbStimMat = cat(2,NewGRAT.dbStimMat,sGRAT(i).dbStimMat);
       NewGRAT.db1PresOnTStamp = cat(2,NewGRAT.db1PresOnTStamp,sGRAT(i).db1PresOnTStamp);
       NewGRAT.db1PresOffTStamp = cat(2,NewGRAT.db1PresOffTStamp,sGRAT(i).db1PresOffTStamp);
       NewGRAT.cFRAMEONTSTAMP = cat(2,NewGRAT.cFRAMEONTSTAMP,sGRAT(i).cFRAMEONTSTAMP);
       NewGRAT.cSTIMLOG = cat(2,NewGRAT.cSTIMLOG,sGRAT(i).cSTIMLOG);
    end
    sGRAT = NewGRAT;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
        % Maps condifortion in the current presentation to the general
        % presentation and append presentations to the output structure
        bl1Cnd                  = all(db2Cond == db2CondPrs(:, iCnd), 1); 
        sCND_IDX(bl1Cnd).bl1Pres   = sCND_IDX(bl1Cnd).bl1Pres | bl1GratingOn;
    end
end

%Extracts the running
bl1WheelOn  = sINPUT_2.sL4MMDS.bl1WheelOn;

%Extracts stimulation times from all presentation sets
bl1Stim         = NS_MakeEpochVector(in1PresOnIdx, in1PresOffIdx, length(sINPUT_2.sL4MMDS.db1TStamps));

% Computes the baseline
bl1Baseline = ~bl1WheelOn & ~bl1Stim;


%%%%%%%%%%%%%%%%%%%%%%%%%%% Stefan created to seperate states,11/21/2022,
%%%%%%%%%%%%%%%%%%%%%%%%%%% added face 2022/12/14
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Facemap part
facemap = sINPUT_2.sL4MMDS.db1FacePC1;
%%%PC1 could be negative, need to flip
if abs(min(facemap))>max(facemap)
    facemap=-facemap;
end

% Calculate z score by bottom 10% and get quartile threshhold
% get the baseline
sortface=sort(facemap);
baseline=sortface(1:round(0.1*length(sortface)));
zface=(facemap-mean(baseline))/std(baseline);
quart=quantile(zface,3);

CndStateIdx=zeros(inNCnd,inNSample);
for iCnd = 1:inNCnd
    CndStateIdx(iCnd,:) = sCND_IDX(iCnd).bl1Pres;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LocThreshhold = sGRAT(1).sPARAM.StimulusDuration * inSampleRate *0.95; %%%% arbitrary threshholding Stefan 2022/11
QuiThreshhold  = sGRAT(1).sPARAM.StimulusDuration * inSampleRate *0.05;

for iCnd = 1:inNCnd
    for itrial = 1:size(in2PresIdx,1)
        trialnum = in2PresIdx(itrial,iCnd);
        WheelOnScore = sum(bl1WheelOn(in1PresOnIdx(trialnum):in1PresOffIdx(trialnum)));
        if WheelOnScore < QuiThreshhold
            % Calculate the mean in stimulus on 3 seconds plus pre 1 sec, of only quiescense trials
            facescore = mean(zface(in1PresOnIdx(trialnum)-inSampleRate*1:in1PresOffIdx(trialnum)));
            if facescore<quart(2)
                CndStateIdx(iCnd,in1PresOnIdx(trialnum):in1PresOffIdx(trialnum)) = 1;
            else
                CndStateIdx(iCnd,in1PresOnIdx(trialnum):in1PresOffIdx(trialnum)) = 2;
            end
        elseif WheelOnScore > LocThreshhold
            CndStateIdx(iCnd,in1PresOnIdx(trialnum):in1PresOffIdx(trialnum)) = 3;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initializes output structure
sCOND  = struct('dbPower', cell(1, inNCnd), 'dbZ_Power', cell(1, inNCnd));
sCONDState  = struct('QuiescenceLowface', cell(1, inNCnd), 'QuiescenceLowface_Z', cell(1, inNCnd),...
    'QuiescenceLHighface', cell(1, inNCnd), 'QuiescenceHighface_Z', cell(1, inNCnd),...
    'Locomotion', cell(1, inNCnd), 'Locomotion_Z', cell(1, inNCnd));
fns = fieldnames(sCONDState);
sBAND   = struct('db1Band', cell(1, inNBnd), 'chBandLabel', cell(1, inNBnd), ...
    'dbBasPower', cell(1, inNBnd), 'dbBasPower_SD', cell(1, inNBnd), ... 
	'sCOND', repmat({sCOND}, 1, inNBnd),'sCONDTrial', repmat({sCOND}, 1, inNBnd), 'sCONDState', repmat({sCONDState}, 1, inNBnd));

%%%%%%%%%%%%%%%% STEFAN ADDED TO SEPERATE EACH TRIAL FOR EACH STIMULUS
%%%%%%%%%% to compare the earlier and later trials 11/14/2023
trialPerStim = sGRAT.sPARAM.NumberOfPresentations ;
for iCnd = 1:inNCnd
    IdxWithTrialNum (iCnd,:)= int8(sCND_IDX(iCnd).bl1Pres);
    for irep =1:trialPerStim
        idx =in1PresOnIdx(in2PresIdxPrs(irep, iCnd)):in1PresOffIdx(in2PresIdxPrs(irep,iCnd));
        IdxWithTrialNum (iCnd,idx)  = irep;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Loops through bands
for iBnd = 1:inNBnd

	%Computes the activity in the band of interest
    [B, A]      = butter(2, 2*cBAND{iBnd}/inSampleRate); %Low pass for regular CSD
    db1Power 	= sum(abs(hilbert(filtfilt(B, A, db2LFP'))).^2, 2);

    % Keeps track of band and band label
    sBAND(iBnd).db1Band 		= cBAND{iBnd};
    sBAND(iBnd).chBandLabel 	= sprintf('%d-%dHz', cBAND{iBnd});

	%Computes the baseline pulse rate
    sBAND(iBnd).dbBasPower 		= mean(db1Power(bl1Baseline));
    sBAND(iBnd).dbBasPower_SD 	= std(db1Power(bl1Baseline));

	%Computes the pulse rate for each condition
    for iCnd = 1:inNCnd
        dbPower 	= mean(db1Power(sCND_IDX(iCnd).bl1Pres));
        dbZ_Power = (dbPower - sBAND(iBnd).dbBasPower) ./ sBAND(iBnd).dbBasPower_SD;
        sBAND(iBnd).sCOND(iCnd).dbPower 	= dbPower;
        sBAND(iBnd).sCOND(iCnd).dbZ_Power 	= dbZ_Power;
        
        %%%% STEFAN added 11/14/2023 to take mean of each trial 
        for irep =1:trialPerStim
            dbPower 	= mean(db1Power(IdxWithTrialNum(iCnd,:)==irep));
            dbZ_Power = (dbPower - sBAND(iBnd).dbBasPower) ./ sBAND(iBnd).dbBasPower_SD;
            sBAND(iBnd).sCONDTrial(iCnd).dbPower(irep)   = dbPower ;
            sBAND(iBnd).sCONDTrial(iCnd).dbZ_Power(irep) = dbZ_Power;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%
            
        for istate = 1:3  %%%%%%% Stefan created to seperate states,11/21/2022, edited 12/14
            dbPower = mean(db1Power(CndStateIdx(iCnd,:)==istate));
            dbZ_Power = (dbPower - sBAND(iBnd).dbBasPower) ./ sBAND(iBnd).dbBasPower_SD;
            sBAND(iBnd).sCONDState(iCnd).(fns{istate*2-1}) 	= dbPower;
            sBAND(iBnd).sCONDState(iCnd).(fns{istate*2})	= dbZ_Power;
        end
    end
    
end


%%%%%%%%%%%%%% ADDED by STEFAN 07/2022
% get the LFP traces and take average for each condition and channel 
% Be careful that it sorts the stimuli conditions!
[SFs,~,isf] = unique(db2CondPrs(2,:));
[Size,~,isz] = unique(db2CondPrs(5,:));
[Ctr,~,ictr] = unique(db2CondPrs(4,:));

stimduration = sGRAT.sPARAM.StimulusDuration;
tracelength = stimduration*inSampleRate*3; 
trialPerStim = sGRAT.sPARAM.NumberOfPresentations ;

alltrace = cell(length(SFs),length(Size),length(Ctr));
for iCnd = 1:inNCnd
    stimOn = in1PresOnIdx(in2PresIdxPrs(:, iCnd));
    meantrace = zeros(size(db2LFP,1), tracelength);
    for ichan = 1:size(db2LFP,1)
        trace =  zeros(trialPerStim,tracelength);
        for itrial = 1:trialPerStim
            trace (itrial,:)= db2LFP(ichan,stimOn(itrial)-tracelength/3:stimOn(itrial)+tracelength*2/3-1);
        end
        meantrace(ichan,:)= mean(trace,1);
    end
    alltrace{isf(iCnd),isz(iCnd),ictr(iCnd)} = meantrace;
end



%%%% STEFAN ADDED 11/14/2023 to uniform the stimuli parameters %%%%%%%%%%%%
db2Cond(2,db2Cond(2,:) == SFs(1)) =0.01;
db2Cond(2,db2Cond(2,:) == SFs(2)) =0.04;
db2Cond(2,db2Cond(2,:) == SFs(3)) =0.16;
db2Cond(2,db2Cond(2,:) == SFs(4)) =0.64;

db2Cond(5,db2Cond(5,:) == Size(1)) =5;
db2Cond(5,db2Cond(5,:) == Size(2)) =10;
db2Cond(5,db2Cond(5,:) == Size(3)) =20;
db2Cond(5,db2Cond(5,:) == Size(4)) =40;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'sBAND', 'db2Cond', 'alltrace','db2CondPrs','chanLayer','-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('  Done! \r')
end
