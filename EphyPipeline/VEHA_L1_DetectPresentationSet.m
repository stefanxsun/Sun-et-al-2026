function [varargout] = VEHA_L1_DetectPresentationSet(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the source visual analog
chSourcePath = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L0_PreProcessVisualAnalog');
chPPVAFile = 'VEHA_L0_PreProcessVisualAnalog.mat';
if ~exist(fullfile(chSourcePath, chSessionName, chPPVAFile), 'file')
    error('%s does not exist for session %s in %s\r', chPPVAFile, chSessionName, chSourcePath)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L1_DetectPresentationSet';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L1_DetectPresentationSet.mat';
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
sLOAD = load(fullfile(chSourcePath, chSessionName, chPPVAFile), '-mat');
db1VAnalog = sLOAD.sCFG.sL0PPVA.db1VAnalog;
db1TStamps = sLOAD.sCFG.sL0PPVA.db1TStamps;
blLowLum = sLOAD.sCFG.sL0PPVA.blLowLum;
if blLowLum
    inFR = 100;
    in1FrameBegIdx = 1:round(sLOAD.sCFG.sPARAM.inWorkingSamplingRate / inFR):length(db1VAnalog);
%     in1FrameBegIdx = sLOAD.sCFG.sL0PPVA.in1FrameBegIdx; 
else
    inFR = sLOAD.sCFG.sPARAM.inWorkingSamplingRate;
end

%Computes time index in minutes
db1Time = (1:length(db1TStamps))/sLOAD.sCFG.sPARAM.inWorkingSamplingRate;

if blDoProc
    %Sets the parameters for the detection of epochs where the stimulus was on
    if blLowLum
        dbZThreshold = 7; % 10
        inClosureOrder = 12; % 12
        
        db1FrameLum = zeros(1, length(in1FrameBegIdx) - 1);
        for idx = 1:length(db1FrameLum)
            db1FrameLum(idx) = mean(db1VAnalog(in1FrameBegIdx(idx):in1FrameBegIdx(idx + 1)));
        end
        db1FrameTime = db1Time(in1FrameBegIdx(1:end - 1));
    else
        db1FrameLum = db1VAnalog;
        db1FrameTime = db1Time;
        dbZThreshold = 20;
        inClosureOrder = inFR/20;
    end
    
    %Computes the statistic of the baseline (assumes that no stimulus is
    %displayed during the first 30 seconds of the recording)sCFG.sPARAM.blOpen
    dbBLDurSec = 2;
    dbMeanBL = mean(db1FrameLum(1:inFR*dbBLDurSec));
    dbStdBL = std(db1FrameLum(1:inFR*dbBLDurSec));
    
    % ALTERNATIVEHAY Computes the statistic of the baseline from the end fot
    % the recording
%     dbBLDurSec = .5;
%     dbMeanBL = mean(db1FrameLum(end - round(inFR*dbBLDurSec) - 1: end));
%     dbStdBL = std(db1FrameLum(end - round(inFR*dbBLDurSec) - 1: end));
    
    %Detects epochs when a stimulus is on (epochs where the visual analog is
    %dbZThreshold s.d above or under baseline with a tolerance for false
    %negative defined by inClosure order)
    db1ZFrameLum = (db1FrameLum - dbMeanBL)./dbStdBL;
    dbZThreshold = mean(db1ZFrameLum); % using mean as threshold, Stefan edited
    bl1NonBL = db1ZFrameLum > dbZThreshold;
    bl1NonBL = NS_OpenBoolean(bl1NonBL, 60); % Can make stimuli dissappear use with caution
    bl1NonBL = NS_CloseBoolean(bl1NonBL, inClosureOrder);
    bl1NonBL([1:100 end]) = false;  % exclude first second artfact,  Stefan edited
    
    %Find the index of the time when the presentation turns on or off
    in1PresOnIdx = find(bl1NonBL(1:end-1) == 0 & bl1NonBL(2:end) == 1)+ 1;
    in1PresOffIdx = find(bl1NonBL(1:end-1) == 1 & bl1NonBL(2:end) == 0)+ 1;
    
    if ~isempty(in1PresOnIdx)
        %Removes presentations if their begining of their end is outside the
        %recordings
        if in1PresOnIdx(1) > in1PresOffIdx(1), in1PresOffIdx(1) = []; end
        if in1PresOnIdx(end) > in1PresOffIdx(end), in1PresOnIdx(end) = []; end
    end
	
	% In the case that presentation patch correspond to the onset and offset of stimulations, 
	% checks that result are consistent with a model and groups on and off stim into one stimulation.
	if sCFG.sPARAM.blOnOffBlink & ~isempty(in1PresOnIdx)
        % Gives an error if there is less that two stims detected
        if in1PresOnIdx == 1; error('Less that two stim with OnOffBlink'); end
        
        % Checks for error in expected duration between on and off blinks
        inN_Jitter 		= round(sCFG.sPARAM.dbJitterOnOff * inFR);
		in1PresLenIdx 	= sCFG.sPARAM.db1StimLenSec; % expected durations
		if iscolumn(in1PresLenIdx), in1PresLenIdx = in1PresLenIdx'; end
		in1DBlink   = diff(in1PresOnIdx);
		db1Error    = min(abs(in1DBlink - round(in1PresLenIdx * inFR)), [], 2);  % min of the error
        bl1Valid    = db1Error < inN_Jitter;

        % Finds motifs corresponding to 1 0 0 1 and removes them from pres
        % on indices
        bl2Motif    = bl1Valid((1:length(bl1Valid) - 4)' + (0:3));
        in1Error    = find(sum(bl2Motif == [1 0 0 1], 2) == 4) + 2;
        if ~bl1Valid(1), in1Error = [1; in1Error]; end
        if ~bl1Valid(end), in1Error = [in1Error; length(in1PresOnIdx)]; end 
        in1PresOnIdx(in1Error) = [];

		% Checks that the number of presentation is even
		if mod(length(in1PresOnIdx), 2) ~= 0
            % DIAGNOSTIC FOR FAILURE
            figure, plot(db1ZFrameLum); hold on, plot(find(bl1NonBL), db1ZFrameLum(bl1NonBL), 'g.');
            title(strrep(chSessionName, '_', '\_'))
            fprintf('\r');
            
            error('Odd number of flashes with OnOffBlink, check for inacuracies in detection');
        end
        
        % Recomputes stim on and stim off
        in1PresOffIdx   = in1PresOnIdx(2:2:end);
        in1PresOnIdx    = in1PresOnIdx(1:2:end - 1);
	end 	

    if length(in1PresOnIdx) > 2
         
        %Finds the index  of the begining  and the end of presentation sets
        dbTimeThr = 10;  %%%%%%%%% WAS 1.2, but visual stim is messed up because vision gui problem so rough fix with this
        db1PresOnTimeD2 = diff(db1FrameTime(in1PresOnIdx), 2);
        bl1FirstPres = [true (db1PresOnTimeD2 > dbTimeThr | db1PresOnTimeD2 < -dbTimeThr) true]; %1 for 2016-10-13_10-03-25_3
        in1ToRemove = find(bl1FirstPres(1:end-1) == 0 & bl1FirstPres(2:end) == 1) + 1;
        bl1FirstPres(in1ToRemove) = 0;
        in1FirstPres = find(bl1FirstPres);
        in1LastPres = [in1FirstPres(2:end)-1 length(in1PresOnIdx)];
    else
        in1FirstPres = find(in1PresOnIdx);
        in1LastPres = find(in1PresOffIdx);
    end
    
    %Finds the number of frame of each presentations (relevants for movies
    %only)
    if blLowLum
        inClosureOrder = 12;
    else
        inClosureOrder = inFR/200;
    end
    
    cFRAMEONIDX = cell(1, length(in1PresOnIdx));
    cFRAMEONTSTAMP = cell(1, length(in1PresOnIdx));
    inFrameCount = zeros(1, length(in1PresOnIdx));
    for idx = 1:length(cFRAMEONIDX)
        bl1AboveBL = db1FrameLum(in1PresOnIdx(idx):in1PresOffIdx(idx)) > dbMeanBL;
        bl1AboveBL = NS_CloseBoolean(bl1AboveBL, inClosureOrder)';
        cFRAMEONIDX{idx} = [in1PresOnIdx(idx) in1PresOnIdx(idx) + find(diff(bl1AboveBL) ~= 0)];
        if blLowLum
            cFRAMEONIDX{idx} = in1FrameBegIdx(cFRAMEONIDX{idx});
        end
        cFRAMEONTSTAMP{idx} = double(db1TStamps(cFRAMEONIDX{idx}));
        inFrameCount(idx) = length(cFRAMEONTSTAMP{idx});
    end
    
    % %converts the index back into the scale of the timestamps in case they were
    %compressed to match hardware refresh cycle.
    if blLowLum
        in1PresOnIdx = in1FrameBegIdx(in1PresOnIdx);
        in1PresOffIdx = in1FrameBegIdx(in1PresOffIdx);
    end
    db1PresOnTStamp = db1TStamps(in1PresOnIdx);
    db1PresOffTStamp = db1TStamps(in1PresOffIdx);
else
    sCFG = load(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile)); sCFG = sCFG.sCFG;
    sCFG.sPARAM.blDoPlot = true;
    in1PresOnIdx        = sCFG.sL1DP.in1PresOnIdx;
    db1PresOnTStamp     = sCFG.sL1DP.db1PresOnTStamp;
    in1PresOffIdx       = sCFG.sL1DP.in1PresOffIdx;
    db1PresOffTStamp    = sCFG.sL1DP.db1PresOffTStamp;
    in1FirstPres        = sCFG.sL1DP.in1FirstPres;
    in1LastPres         = sCFG.sL1DP.in1LastPres;
    cFRAMEONIDX         = sCFG.sL1DP.cFRAMEONIDX;
    cFRAMEONTSTAMP      = sCFG.sL1DP.cFRAMEONTSTAMP;false
end

if sCFG.sPARAM.blVerbose
    inNPres = length(in1FirstPres);
    in1PresLen = in1LastPres - in1FirstPres + 1;
    if inNPres < 2, fprintf('%d Presentation:\r', inNPres);
    else, fprintf('%d Presentations:\r', inNPres); end
    for iPres = 1:inNPres
        fprintf('Pres %d: %d Stims\r', iPres, in1PresLen(iPres));
    end
end
    
% Plots the result if needed
if sCFG.sPARAM.blDoPlot
    in1FirstPresIdx = in1PresOnIdx(in1FirstPres);
    in1LastPresIdx = in1PresOffIdx(in1LastPres);
    figure
    plot(db1TStamps, db1VAnalog), hold on,
    bl1YL = ylim(gca);
    for idx = 1:length(in1PresOnIdx)
        plot(repmat(db1TStamps(in1PresOnIdx(idx)), 1, 2), bl1YL, 'g')
    end
    for idx = 1:length(in1PresOffIdx)
        plot(repmat(db1TStamps(in1PresOffIdx(idx)), 1, 2), bl1YL, 'r')
    end
    for idx = 1:length(in1FirstPresIdx)
        plot(repmat(db1TStamps(in1FirstPresIdx(idx)), 1, 2), bl1YL, 'g', 'LineWidth', 3)
    end
    for idx = 1:length(in1FirstPresIdx)
        plot(repmat(db1TStamps(in1LastPresIdx(idx)), 1, 2), bl1YL, 'r', 'LineWidth', 3)
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
    sCFG.sINPUT.sL0PPVA.chScriptName = sLOAD.sCFG.sL0PPVA.chScriptName;
    sCFG.sINPUT.sL0PPVA.chTimeComputed = sLOAD.sCFG.sL0PPVA.chTimeComputed;
    
    %Writes the output in CFG
    sCFG.sL1DP.in1PresOnIdx = in1PresOnIdx;
    sCFG.sL1DP.db1PresOnTStamp = db1PresOnTStamp;
    sCFG.sL1DP.in1PresOffIdx = in1PresOffIdx;
    sCFG.sL1DP.db1PresOffTStamp = db1PresOffTStamp;
    sCFG.sL1DP.in1FirstPres = in1FirstPres;
    sCFG.sL1DP.in1LastPres =in1LastPres;
    sCFG.sL1DP.cFRAMEONIDX = cFRAMEONIDX;
    sCFG.sL1DP.cFRAMEONTSTAMP = cFRAMEONTSTAMP;
    sCFG.sL1DP.chScriptName = mfilename('fullpath');
    sCFG.sL1DP.chTimeComputed = datestr(now);
    
    %Saves the output
    save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');
end

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')
