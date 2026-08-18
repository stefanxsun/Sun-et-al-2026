function [varargout] = VEHA_L1_DetectOptoStimSet(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the source visual analog
chSourcePath = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L0_PreProcessOptoAnalog');
chPPOAFile = 'VEHA_L0_PreProcessOptoAnalog.mat';
if ~exist(fullfile(chSourcePath, chSessionName, chPPOAFile), 'file')
    error('%s does not exist for session %s in %s\r', chPPOAFile, chSessionName, chSourcePath)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L1_DetectOptoStimSet';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L1_DetectOptoStimSet.mat';
%Checks that the data do not exist, if so skips unless blDoPlot is true, If
%so loads the data and plots them
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    if sCFG.sPARAM.blDoPlot
        blDoProc = false;
        fprintf('Plotting %s ...', chSessionName);
    else
        fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
        return
    end
else
    fprintf('Processing %s ...', chSessionName);
    blDoProc = true;
end

%Loads the preprocessed visual analog recordings and extracts what is needed
sLOAD = load(fullfile(chSourcePath, chSessionName, chPPOAFile), '-mat');
db1OAnalog = sLOAD.sCFG.sL0PPOA.db1OAnalog;
db1TStamps = sLOAD.sCFG.sL0PPOA.db1TStamps;

%Computes time index in minutes
db1Time = (1:length(db1TStamps))/sLOAD.sCFG.sPARAM.inWorkingSamplingRate;

if blDoProc
    % Sets the parameters for the detection of laser triggers
    inFR = sLOAD.sCFG.sPARAM.inWorkingSamplingRate;
    dbZThreshold = 50;
    inClosureOrder = inFR/200;
    
    %Computes the statistic of the baseline (assumes that no stimulus is
    %displayed during the first 4 seconds of the recording)
    dbBLDurSec = 4;    
    dbMeanBL = mean(db1OAnalog(1:inFR*dbBLDurSec));
    dbStdBL = std(db1OAnalog(1:inFR*dbBLDurSec));
%     dbMeanBL = mean(db1FrameLum((end-inFR*dbBLDurSec):end));
%     dbStdBL = std(db1FrameLum((end-inFR*dbBLDurSec):end));

    %Detects epochs when a stimulus is on (epochs where the visual analog is
    %dbZThreshold s.d above or under baseline with a tolerance for false
    %negative defined by inClosure order)
    db1ZOAnalog = (db1OAnalog - dbMeanBL)./dbStdBL;
    bl1NonBL = db1ZOAnalog > dbZThreshold | db1ZOAnalog < -dbZThreshold;
    bl1NonBL = NS_CloseBoolean(bl1NonBL, inClosureOrder);
%     bl1NonBL = NS_OpenBoolean(bl1NonBL, inClosureOrder); %Added only for 2016-10-11_10-14-22_2
    
    %Find the index of the time when the presentation turns on or off
    in1OptoOnIdx = find(bl1NonBL(1:end-1) == 0 & bl1NonBL(2:end) == 1)+ 1;
    in1OptoOffIdx = find(bl1NonBL(1:end-1) == 1 & bl1NonBL(2:end) == 0)+ 1;
    
    if ~isempty(in1OptoOnIdx)
        %Removes presentations if their begining or their end is outside the
        %recordings
        if in1OptoOnIdx(1) > in1OptoOffIdx(1), in1OptoOffIdx(1) = []; end
        if in1OptoOnIdx(end) > in1OptoOffIdx(end), in1OptoOnIdx(end) = []; end
        
        %Finds the index  of the begining  and the end of pulse sets 
        dbTLimSec = .1;
        if length(in1OptoOnIdx) > 1
            db1PresOnTimeD2 = diff(db1Time(in1OptoOnIdx), 2);
            bl1FirstPulse = [true (db1PresOnTimeD2 > dbTLimSec | db1PresOnTimeD2 < -dbTLimSec) true]; %1 for 2016-10-13_10-03-25_3
            in1ToRemove = find(bl1FirstPulse(1:end-1) == 0 & bl1FirstPulse(2:end) == 1) + 1;
            bl1FirstPulse(in1ToRemove) = 0;
            in1FirstPulse = find(bl1FirstPulse);
            in1LastPulse = [in1FirstPulse(2:end)-1 length(in1OptoOnIdx)];
        else
            in1FirstPulse   = 1;
            in1LastPulse    = 1;
        end
        
        %Performs the same operation on pulse sets to find the beginning of
        %presentation sets
        dbTLimSec = .1;
        if length(in1FirstPulse) > 1
        db1PulseSetOnTimeD2 = diff(db1Time(in1OptoOnIdx(in1FirstPulse)), 2);
        bl1FirstPres = [true (db1PulseSetOnTimeD2 > dbTLimSec | db1PulseSetOnTimeD2 < -dbTLimSec) true]; %1 for 2016-10-13_10-03-25_3
        in1ToRemove = find(bl1FirstPres(1:end-1) == 0 & bl1FirstPres(2:end) == 1) + 1;
        bl1FirstPres(in1ToRemove) = 0;
        in1FirstPres = find(bl1FirstPres);
        in1LastPres = [in1FirstPres(2:end)-1 length(in1FirstPulse)];
        else
            in1FirstPres   = 1;
            in1LastPres    = 1;
        end
        in1FirstPres = in1FirstPulse(in1FirstPres);
        in1LastPres = in1LastPulse(in1LastPres);
        
        %When presentation sets and pulse sets coincide it means that pulse
        %sets were actually single pulses. Does that corrections
        in1SinglePulsePres = find(ismember(in1FirstPulse, in1FirstPres) & ismember(in1LastPulse, in1LastPres));
        for iPrs = in1SinglePulsePres
            in1FirstPulse = [in1FirstPulse in1FirstPulse(iPrs):in1LastPulse(iPrs)];
            in1LastPulse = [in1LastPulse in1FirstPulse(iPrs):in1LastPulse(iPrs)];
        end
        in1FirstPulse(in1SinglePulsePres) = [];
        in1LastPulse(in1SinglePulsePres) = [];
        in1FirstPulse = sort(in1FirstPulse);
        in1LastPulse = sort(in1LastPulse);
        
    else
        in1FirstPulse = [];
        in1LastPulse = [];
        in1FirstPres = [];
        in1LastPres = [];
    end
    
    % %converts the index back into the scale of the timestamps in case they were
    %compressed to match hardware refresh cycle.
    db1OptoOnTStamp = db1TStamps(in1OptoOnIdx);
    db1OptoOffTStamp = db1TStamps(in1OptoOffIdx);
else
    sCFG = load(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile)); sCFG = sCFG.sCFG;
    sCFG.sPARAM.blDoPlot = true;
    in1OptoOnIdx        = sCFG.sL1DOS.in1OptoOnIdx;
    db1OptoOnTStamp     = sCFG.sL1DOS.db1OptoOnTStamp;
    in1OptoOffIdx       = sCFG.sL1DOS.in1OptoOffIdx;
    db1OptoOffTStamp    = sCFG.sL1DOS.db1OptoOffTStamp;
    in1FirstPulse       = sCFG.sL1DOS.in1FirstPulse;
    in1LastPulse        = sCFG.sL1DOS.in1LastPulse;
    in1FirstPres        = sCFG.sL1DOS.in1FirstPres;
    in1LastPres         = sCFG.sL1DOS.in1LastPres;
end

% Plots the result if needed
if sCFG.sPARAM.blDoPlot
    in1FirstPulseIdx = in1OptoOnIdx(in1FirstPulse);
    in1LastPulseIdx = in1OptoOffIdx(in1LastPulse);
    in1FirstPresIdx = in1OptoOnIdx(in1FirstPres);
    in1LastPresIdx = in1OptoOffIdx(in1LastPres);
    figure
    plot(db1TStamps, db1OAnalog), hold on,
    bl1YL = ylim(gca);
    for idx = 1:length(in1OptoOnIdx)
        plot(repmat(db1TStamps(in1OptoOnIdx(idx)), 1, 2), bl1YL, '--g')
    end
    for idx = 1:length(in1OptoOffIdx)
        plot(repmat(db1TStamps(in1OptoOffIdx(idx)), 1, 2), bl1YL, '--r')
    end
    for idx = 1:length(in1FirstPulseIdx)
        plot(repmat(db1TStamps(in1FirstPulseIdx(idx)), 1, 2), bl1YL, 'g')
    end
    for idx = 1:length(in1LastPulseIdx)
        plot(repmat(db1TStamps(in1LastPulseIdx(idx)), 1, 2), bl1YL, 'r')
    end
    for idx = 1:length(in1FirstPresIdx)
        plot(repmat(db1TStamps(in1FirstPresIdx(idx)), 1, 2), bl1YL, 'g', 'LineWidth', 2)
    end
    for idx = 1:length(in1FirstPresIdx)
        plot(repmat(db1TStamps(in1LastPresIdx(idx)), 1, 2), bl1YL, 'r', 'LineWidth', 2)
    end
    hold off, title(strrep(chSessionName, '_', '\_'))
    
%     figure
%     plot(db1TStamps, db1VAnalog), hold on
%     bl1YL = ylim(gca);
%     for idx = 1:length(cFRAMEONIDX)
%         for jdx = 1:length(cFRAMEONIDX{idx})
%             plot(repmat(db1TStamps(cFRAMEONIDX{idx}(jdx)), 1, 2), bl1YL, 'y')
%         end
%     end
%     title(strrep(chSessionName, '_', '\_'))
end

if blDoProc
    %Update sREC
    sCFG.sREC = sREC;
    
    %Keeps track of the input in CSG
    sCFG.sINPUT.sPARAM = sLOAD.sCFG.sPARAM;
    sCFG.sINPUT.sL0PPVA.chScriptName = sLOAD.sCFG.sL0PPOA.chScriptName;
    sCFG.sINPUT.sL0PPVA.chTimeComputed = sLOAD.sCFG.sL0PPOA.chTimeComputed;
    
    %Writes the output in CFG
    sCFG.sL1DOS.in1PresOnIdx = in1OptoOnIdx;
    sCFG.sL1DOS.db1PresOnTStamp = db1OptoOnTStamp;
    sCFG.sL1DOS.in1PresOffIdx = in1OptoOffIdx;
    sCFG.sL1DOS.db1PresOffTStamp = db1OptoOffTStamp;
    sCFG.sL1DOS.in1FirstPulse = in1FirstPulse;
    sCFG.sL1DOS.in1LastPulse =in1LastPulse;
    sCFG.sL1DOS.in1FirstPres = in1FirstPres;
    sCFG.sL1DOS.in1LastPres =in1LastPres;
    sCFG.sL1DOS.chScriptName = mfilename('fullpath');
    sCFG.sL1DOS.chTimeComputed = datestr(now);
    
    %Saves the output
    save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');
end

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')