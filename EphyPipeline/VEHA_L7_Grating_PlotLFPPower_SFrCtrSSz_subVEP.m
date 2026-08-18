function [varargout] = VEHA_L7_Grating_PlotLFPPower_SFrCtrSSz_subVEP(sCFG)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sCFG.sREC.chNlxSessionDir, '_', num2str(sCFG.sREC.inRecNum));

%Checks the for visual stimulation meta structure
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L5_Grating_MakeDataStructure');
chG_MDSFile = 'VEHA_L5_Grating_MakeDataStructure.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chG_MDSFile), 'file')
    error('%s does not exist for session %s in %s\r', chG_MDSFile, chSessionName, chSourcePath_1)
end

%Checks the for the Morlet transform of the signal
chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L6_Grating_FourierPower');
chG_FPFile = 'VEHA_L6_Grating_FourierPower.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chG_FPFile), 'file')
    error('%s does not exist for session %s in %s\r', chG_FPFile, chSessionName, chSourcePath_2)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L7_Grating_PlotLFPPower_SFrCtrSSz_subVEP';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile_Fig = 'VEHA_L7_Grating_PlotLFPPower_SFrCtrSSz_subVEP.fig';
chDestFile_Mat = 'VEHA_L7_Grating_PlotLFPPower_SFrCtrSSz_subVEP.mat';
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'file') && ~sCFG.sPARAM.blOverwrite
    if sCFG.sPARAM.blDoPlot
        fprintf('Plotting %s ...', chSessionName);
        blDoProc = false;
    else
        fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile_Mat, fullfile(chDestPath, chDestMetaFolder, chSessionName));
        return
    end
else
    fprintf('Processing %s ...', chSessionName);
    blDoProc = true;
end

if blDoProc
    %Loads the input
    sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chG_MDSFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
    sINPUT_2 = load(fullfile(chSourcePath_2, chSessionName, chG_FPFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;
    
    %Does an sorting of condition to initialiaze output Matrix
    [db2Cond, in2PresIdx] = NS_SortTrials(sINPUT_1.sL5G_MDS.sPRES(1).dbStimMat);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Stefan created to seperate states,11/21/2022, added face 2022/12/14
    db1TStamps = sINPUT_1.sL5G_MDS.sPRES.db1TStamps;
    inNSample = length(db1TStamps);
    inNCnd = size(db2Cond,2);
    inSampleRate = sINPUT_1.sL5G_MDS.inWorkSampleRate;  
    % Extract visual stim idx
    in1PresOnIdx = sINPUT_1.sL5G_MDS.sPRES.in1PresOnIdx;
    in1PresOffIdx = sINPUT_1.sL5G_MDS.sPRES.in1PresOffIdx;

    %Extracts stimulation times from all presentation sets
    bl1Stim    = NS_MakeEpochVector(in1PresOnIdx, in1PresOffIdx, length(db1TStamps));
       
    %Extracts the running
    bl1WheelOn  = sINPUT_1.sL5G_MDS.sPRES.bl1WheelOn;  
    % Computes the baseline
    bl1Baseline = ~bl1WheelOn & ~bl1Stim;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Facemap part
    facemap = sINPUT_1.sL5G_MDS.sPRES.db1FacePC1;

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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Stefan created to seperate states,11/21/2022, edited 12/14
    LocThreshhold = sINPUT_1.sL5G_MDS.sPRES(1).sPARAM.StimulusDuration   * inSampleRate *0.95; %%%% arbitrary threshholding Stefan 2022/11
    QuiThreshhold  = sINPUT_1.sL5G_MDS.sPRES(1).sPARAM.StimulusDuration   * inSampleRate *0.05;
    
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
    
    
    %Initialize aggregation variables
    db3FourierPower = [];
    bl1SptFChunk = [];
    sCOND(size(in2PresIdx, 2)).bl1FChunk = [];
    sCOND(size(in2PresIdx, 2)).stateidx = [];
    
    for iPres = 1:length(sINPUT_2.sL6G_FP.sPRES)
        %Extract key variable to simplify code and aggregates spectrum
        %accros presentation sets
        in1PresOnIdx       = sINPUT_1.sL5G_MDS.sPRES(iPres).in1PresOnIdx;
        in1PresOffIdx      = sINPUT_1.sL5G_MDS.sPRES(iPres).in1PresOffIdx;
        db1TStamps         = sINPUT_1.sL5G_MDS.sPRES(iPres).db1TStamps;
        
        db3FourierPower    = cat(2, db3FourierPower, 10*log10(sINPUT_2.sL6G_FP.sPRES(iPres).db3FourierPower));
        in1ChunkIdx        = sINPUT_2.sL6G_FP.sPRES(iPres).in1ChunkIdx;
         
        %Extracts the condition matrix
        [db2Cond, in2PresIdx] = NS_SortTrials(sINPUT_1.sL5G_MDS.sPRES(iPres).dbStimMat);
        
        %Creates an average of the spectrum during baseline and aggregate
        %accross presentations sets
        bl1GratingOffIdx = ~NS_MakeEpochVector(in1PresOnIdx, in1PresOffIdx, length(db1TStamps));
        bl1SptFChunk = logical(cat(2, bl1SptFChunk, bl1GratingOffIdx(in1ChunkIdx) == 1));
        
        %Finds the indices of each trials and aggregates accross
        %presentation sets
        in1PresOnIdx       = in1PresOnIdx +  250;   %% Stefan added 06/15/2025 to subtract the VEP part for each stim
        for iCond = 1:length(sCOND)
            bl1GratingOn = NS_MakeEpochVector(in1PresOnIdx(in2PresIdx(:,iCond)), ...
                in1PresOffIdx(in2PresIdx(:,iCond)), length(db1TStamps));
            sCOND(iCond).bl1FChunk = logical(cat(2, sCOND(iCond).bl1FChunk, bl1GratingOn(in1ChunkIdx) == 1));
            %%%%%%%%%Stefan added 01/09/2023
            sCOND(iCond).stateidx = CndStateIdx(iCond, in1ChunkIdx);
        end
    end
        
    %Does surface plots off the power accross channels for the max of the contrast
    db2AvPower_Spt = permute(mean(db3FourierPower(:,bl1SptFChunk, :), 2), [1 3 2]);
    sCOND(end).db2AvPower = nan(size(db2AvPower_Spt)); %Initialize the output
    sCOND(end).db2AvPower_Diff = nan(size(db2AvPower_Spt)); %Initialize the output
    for iCond = 1:length(sCOND)
        sCOND(iCond).db2AvPower = permute(mean(db3FourierPower(:,sCOND(iCond).bl1FChunk, :), 2), [1 3 2]);
        sCOND(iCond).db2AvPower_Diff = sCOND(iCond).db2AvPower - db2AvPower_Spt;
    end
    
    %Does plots of the average power across channels as a function of
    %stimulus size, spatial frequency and contrast
    db2CCPower = mean(db3FourierPower, 3)'; %CC = cross channel  
    db2AvCCPower_Spt = mean(db2CCPower(bl1SptFChunk, :));
    db2SDCCPower_Spt = std(db2CCPower(bl1SptFChunk, :));
    %Substract the average power during baseline in order to derive the
    %average power
    dbCCPower_Diff = db2CCPower - repmat(db2AvCCPower_Spt, size(db2CCPower, 1), 1);
    
    sCOND(end).db2AvCCPower         = nan(size(db2AvCCPower_Spt)); %Initialize the output
    sCOND(end).db2AvCCPower_Diff    = nan(size(db2AvCCPower_Spt)); %Initialize the output
    sCOND(end).db2SECCPower         = nan(size(db2AvCCPower_Spt)); %Initialize the output
    sCOND(end).db2SECCPower_Diff    = nan(size(db2AvCCPower_Spt)); %Initialize the output
    sCOND(end).inNChunk             = nan(size(db2AvCCPower_Spt)); %Initialize the output
    
    %%%%%%%%%%%%%stefan added state split
    sCOND(end).db2AvCCPowerQLF         = nan(size(db2AvCCPower_Spt)); %Initialize the output
    sCOND(end).db2SECCPowerQLF         = nan(size(db2AvCCPower_Spt)); %Initialize the output
    sCOND(end).db2AvCCPowerQHF         = nan(size(db2AvCCPower_Spt)); %Initialize the output
    sCOND(end).db2SECCPowerQHF         = nan(size(db2AvCCPower_Spt)); %Initialize the output
    sCOND(end).db2AvCCPowerLoc         = nan(size(db2AvCCPower_Spt)); %Initialize the output
    sCOND(end).db2SECCPowerLoc         = nan(size(db2AvCCPower_Spt)); %Initialize the output
    
   
    for iCond = 1:length(sCOND)
        sCOND(iCond).db2AvCCPower       = mean(db2CCPower(sCOND(iCond).bl1FChunk, :));
        sCOND(iCond).db2AvCCPower_Diff  = mean(dbCCPower_Diff(sCOND(iCond).bl1FChunk, :));
        sCOND(iCond).db2SECCPower       = std(db2CCPower(sCOND(iCond).bl1FChunk, :))./sqrt(sum(sCOND(iCond).bl1FChunk));
        sCOND(iCond).db2SECCPower_Diff  = std(dbCCPower_Diff(sCOND(iCond).bl1FChunk, :))./sqrt(sum(sCOND(iCond).bl1FChunk));
        %%%%%%%%%%%%%stefan added state split   01/09/2023
        sCOND(iCond).db2AvCCPowerQLF       = mean(db2CCPower(sCOND(iCond).stateidx==1, :));
        sCOND(iCond).db2SECCPowerQLF       = std(db2CCPower(sCOND(iCond).stateidx==1, :))./sqrt(sum(sCOND(iCond).stateidx==1));
        sCOND(iCond).db2AvCCPowerQHF       = mean(db2CCPower(sCOND(iCond).stateidx==2, :));
        sCOND(iCond).db2SECCPowerQHF       = std(db2CCPower(sCOND(iCond).stateidx==2, :))./sqrt(sum(sCOND(iCond).stateidx==2));
        sCOND(iCond).db2AvCCPowerLoc       = mean(db2CCPower(sCOND(iCond).stateidx==3, :));
        sCOND(iCond).db2SECCPowerLoc       = std(db2CCPower(sCOND(iCond).stateidx==3, :))./sqrt(sum(sCOND(iCond).stateidx==3));
    end
    
    %About the following line -- We know that the output fo the presentation function is formated this way most of the time. Wise to check though. 
    %cPAR = {'Orientation', 'Spatial Frequency', 'Temporal Frequency', 'Contrast', 'Size', 'Opto'};
    cPAR = ["Ori", "SFr", "TFr", "Ctr", "Sze", "Opt"];
    cPAR = cPAR(1:size(db2Cond, 1)); 
    if sCFG.sPARAM.blDoPlot
        hFIG = VEHA_U_PlotStimPower1(sCOND, db2Cond, cPAR);
    end
    
else
    if sCFG.sPARAM.blDoPlot
%         openfig(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Fig));
        hFIG = openfig(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Fig));
    end
end

%Saves the output
if blDoProc
    save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), ...
        'db2AvPower_Spt', 'db2AvCCPower_Spt', 'db2SDCCPower_Spt', 'sCOND', 'db2Cond', ...
        '-v7.3');
    if sCFG.sPARAM.blDoPlot
        savefig(hFIG,fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Fig));
    end
end

%Closes the figure if required
if sCFG.sPARAM.blDoPlot
    close(hFIG);
end

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('  Done! \r')
