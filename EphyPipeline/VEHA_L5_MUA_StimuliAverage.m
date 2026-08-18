function [varargout] = VEHA_L5_MUA_StimuliAverage(sCFG)
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
chDestMetaFolder = 'VEHA_L5_MUA_StimuliAverage';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile_Mat = 'VEHA_L5_MUA_StimuliAverage.mat';
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'file') && ~sCFG.sPARAM.blOverwrite
	fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile_Mat, fullfile(chDestPath, chDestMetaFolder, chSessionName));
	return
else
    fprintf('Processing %s ...', chSessionName);
end

%Checks for optional arguments
cLyr = {'23','4','5','6'}; 
sCFG.sPARAM.cLyr = cLyr;
inNLyr 	= length(cLyr);

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


%Extracts the grating structure
sGRAT  = sINPUT_1.sL2MSLPS.sSTIMLOG.sGRATING;

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

%Extract the MUA
MUA = sINPUT_2.sL4MMDS.in2MUATrace;
MUAcount = nan(4,length(MUA));
layerCnt =0; 
for ilayer = [2 4 5 6]
    lyrIdx = chanLayer == ilayer;
    layerCnt =layerCnt+1;
    MUAcount(layerCnt,:) = mean(MUA(lyrIdx,:), 1);
    [FRate(layerCnt), FRate_SD(layerCnt)] = BaselinePulseRate(MUAcount(layerCnt, bl1Baseline), inSampleRate);
end

%%% add one more row to MUAcount and FRate etc, with all channels average
MUAcount = [MUAcount; mean(MUA, 1)];
[FRate(layerCnt+1), FRate_SD(layerCnt+1)] = BaselinePulseRate(MUAcount(layerCnt+1, bl1Baseline), inSampleRate);

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
            % Calculate the mean in stimulus on 2 seconds plus pre 1 sec, of only quiescense trials
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
sCOND  = struct('FR', cell(1, inNCnd), 'Z_FR', cell(1, inNCnd));
sCONDState  = struct('QuiescenceLowface', cell(1, inNCnd), 'QuiescenceLowface_Z', cell(1, inNCnd),...
    'QuiescenceLHighface', cell(1, inNCnd), 'QuiescenceHighface_Z', cell(1, inNCnd),...
    'Locomotion', cell(1, inNCnd), 'Locomotion_Z', cell(1, inNCnd));
fns = fieldnames(sCONDState);
sLyr   = struct('LayerLabel', cell(1, inNLyr), 'BasFR', cell(1, inNLyr), 'BasFR_SD', cell(1, inNLyr), ...     
    'sCOND', repmat({sCOND}, 1, inNLyr),'sCONDTrial', repmat({sCOND}, 1, inNLyr), ...
    'sCONDState', repmat({sCONDState}, 1, inNLyr));


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


% Loops through layers
for iLyr = 1:inNLyr+1

    % Keeps track of layer label
    if iLyr == 5
        sLyr(iLyr).LayerLabel = 'All';
    else
        sLyr(iLyr).LayerLabel 	= cLyr{iLyr};
    end
    sLyr(iLyr).BasFR = FRate(iLyr);   % not needed (Stefan)
    sLyr(iLyr).BasFR_SD = FRate_SD(iLyr); 

% 	%Computes the pulse rate for each condition
    for iCnd = 1:inNCnd
        FRcnd 	= mean(MUAcount(iLyr, sCND_IDX(iCnd).bl1Pres))* inSampleRate;
        zFRcnd 	= (FRcnd - FRate(iLyr)) ./ (FRate_SD(iLyr) ./ sqrt(sum(sCND_IDX(iCnd).bl1Pres)));
        sLyr(iLyr).sCOND(iCnd).FR 	= FRcnd;
        sLyr(iLyr).sCOND(iCnd).Z_FR 	= zFRcnd;
        
        %%%% STEFAN added 11/14/2023 to take mean of each trial 
        for irep =1:trialPerStim
            FRcnd 	= mean(MUAcount(iLyr, IdxWithTrialNum(iCnd,:)==irep));
            zFRcnd 	= (FRcnd - FRate(iLyr)) ./ (FRate_SD(iLyr) ./ sqrt(sum(IdxWithTrialNum(iCnd,:)==irep)));
            sLyr(iLyr).sCONDTrial(iCnd).FR(irep)   = FRcnd ;
            sLyr(iLyr).sCONDTrial(iCnd).Z_FR(irep) = zFRcnd;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%
            
        for istate = 1:3  %%%%%%% Stefan created to seperate states,11/21/2022, edited 12/14
            FRcnd 	= mean(MUAcount(iLyr, CndStateIdx(iCnd,:)==istate))* inSampleRate;
            zFRcnd 	= (FRcnd - FRate(iLyr)) ./ (FRate_SD(iLyr) ./ sqrt(sum(CndStateIdx(iCnd,:)==istate)));
            sLyr(iLyr).sCONDState(iCnd).(fns{istate*2-1}) 	= FRcnd;
            sLyr(iLyr).sCONDState(iCnd).(fns{istate*2})	= zFRcnd;
        end
    end
    
end


% get the MUA traces and take average for each condition and channel 
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
    meantrace = zeros(5, tracelength); % 4 layers + all layers
    for ilyr = 1:5
        trace =  zeros(trialPerStim,tracelength);
        for itrial = 1:trialPerStim
            trace (itrial,:)= MUAcount(ilyr,stimOn(itrial)-tracelength/3:stimOn(itrial)+tracelength*2/3-1);
        end
        meantrace(ilyr,:)= mean(trace,1);
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
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'sLyr', 'db2Cond', 'alltrace','db2CondPrs','chanLayer','-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('  Done! \r')
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