function [varargout] = VEHA_L3_MatchFaceMapWithCameraTriggers(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the input path
chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L0_PreProcessCameraTrigger');
chPPCTFile = 'VEHA_L0_PreProcessCameraTrigger.mat';
if ~exist(fullfile(chSourcePath_1, chSessionName, chPPCTFile), 'file')
    error('%s does not exist for session %s in %s\r', chPPCTFile, chSessionName, chSourcePath_1)
end

chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L2_DetectFaceChangePoint');
chDFCPFile = 'VEHA_L2_DetectFaceChangePoint.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chDFCPFile), 'file')
    error('%s does not exist for session %s in %s\r', chDFCPFile, chSessionName, chSourcePath_2)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L3_MatchFaceMapWithCameraTriggers';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L3_MatchFaceMapWithCameraTriggers.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

% Loads the imput
sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chPPCTFile), '-mat');
warning off, sINPUT_2 = load(fullfile(chSourcePath_2, chSessionName, chDFCPFile), '-mat'); warning on

%Loads camera triggers and computes a time vector out of time stamps 
% db1CamTrig = sINPUT_1.sCFG.sL0PPCT.db1CamreraTrig;
db1TStamps = sINPUT_1.sCFG.sL0PPCT.db1TStamps;
db1Time = (db1TStamps - db1TStamps(1))/1000000; %Time stamps are in microseconds
bl1TrigIdx = sINPUT_1.sCFG.sL0PPCT.bl1TrigIdx;
db1TrigTStamps = sINPUT_1.sCFG.sL0PPCT.db1TrigTStamps;

%Detect the number of trigger sets and their length (the boundaries between
%trigger sets are trigger intervals superior to .5s)
db1DTrigTime = diff(db1Time(bl1TrigIdx));
bl1TrigSetStart = [true db1DTrigTime > 0.5]; in1TrigSetStartIdx = find(bl1TrigSetStart);
bl1TrigSetStop = [db1DTrigTime > 0.5 true]; in1TrigSetStopIdx = find(bl1TrigSetStop);
inNTrigSet = sum(bl1TrigSetStart);
in1TrigSetLen = in1TrigSetStopIdx - in1TrigSetStartIdx + 1;

%Detects if it is likely that trigger extent beyond the recording
dbITI = (median(diff(db1TrigTStamps))/1000000); %median inter trigger interval -> frame rate
blMissTrigStart = db1Time(bl1TrigIdx(1)) < dbITI; %Flag for triggers missing at the begining of the recording
blMissTrigStop = db1Time(end) - db1Time(bl1TrigIdx(end)) < dbITI; %Flag for triggers missing at the end of the recording
if blMissTrigStart & blMissTrigStop & inNTrigSet == 1; %Exits if both flags are true
%     rmdir(fullfile(chDestPath, chDestMetaFolder, chSessionName));
    error('The trigger set cannot starts and end outside the recording\r')
end

%Detects the number of movie and their number of frame
sFMAP = sINPUT_2.sCFG.sL2DFCP.sMOVIE;

%%%%%%%%%% special process for one session: ss0097_d230810 because the
%%%%%%%%%% video recording was terminated in the middle of the experiment,
%%%%%%%%%% I added extra facePC1 to match the trigger, using the mean value
%%%%%%%%%% of the PC1 minus 1. 
sFMAP.db1_FacePC1 = [sFMAP.db1_FacePC1 ones(1,in1TrigSetLen-length(sFMAP.db1_FacePC1))*(mean(sFMAP.db1_FacePC1)-1)];
inNMovie = length(sFMAP);
in1MovieLen = zeros(inNMovie, 1);
for ii = 1:inNMovie
    in1MovieLen(ii) = size(sFMAP(ii).db1_FacePC1, 2);
end

%Checks for anomalie in preprocessing
if inNTrigSet < inNMovie %Rejects the set if the number of trigger sets is inferior to the number of movies
%     rmdir(fullfile(chDestPath, chDestMetaFolder, chSessionName));
    error('There is more movies files that trigger sets. Aborted.\r')
else %Checks that each movie can be attributed to a distinct trigger
    in2DTrig = repmat(in1TrigSetLen, length(in1MovieLen) ,1) - repmat(in1MovieLen, 1, length(in1TrigSetLen)); %table of frame and trigger diff
    [~, in1WhichTrigSet] = min(abs(in2DTrig), [], 2); %min distance along the trigger dimension for each movie
    %Modifies the in1WhichTrigSet if their is incomplete trigger sets
    if blMissTrigStart & in2DTrig(1,1) < 0;
        in1WhichTrigSet(1) = 1;
    elseif blMissTrigStop & in2DTrig(end,end) < 0;
        in1WhichTrigSet(end) = inNTrigSet;
    end
    %Checks that all movies have a unique trigger set    
    if length(unique(in1WhichTrigSet)) ~= length(in1WhichTrigSet)
%         rmdir(fullfile(chDestPath, chDestMetaFolder, chSessionName));
        error('Movies could not be matched to distinct trigger sets. Aborted. \r')
    end
end

%Loops through the movies
for ii = 1:inNMovie
    %Checks if the number of triggers is the same than the number of frames
    inTSIdx = in1WhichTrigSet(ii);
    inDropFrame = in1TrigSetLen(inTSIdx) - in1MovieLen(ii);
    db1MovieTrigTStamps = db1TrigTStamps(in1TrigSetStartIdx(inTSIdx):in1TrigSetStopIdx(inTSIdx));
    if inDropFrame < 0 % if more frames than triggers ...  
        if inTSIdx == 1 & blMissTrigStart %... either the movie has been started too early, ...
            db1MovieTrigTStamps = cat(2, nan(1, abs(inDropFrame)), db1MovieTrigTStamps); %Pads NaN at the beginning for extra frames
            chMatchTrigFlag = 'missing_trig_at_start';
        elseif inTSIdx == inNTrigSet & blMissTrigStop % ... ended too late, ...
            db1MovieTrigTStamps = cat(2, db1MovieTrigTStamps, nan(1, abs(inDropFrame))); %Pads NaN at the end for extra frames
            chMatchTrigFlag = 'missing_trig_at_stop';
        else %... if all of the above is not true then the movie should not be used
            chMatchTrigFlag = 'too_many_frames';
        end
    elseif inDropFrame > 0
        dbDropTime = inDropFrame*dbITI; % If more triggers than frames ...
        if inDropFrame == 1 %... if it is just one it is probably just an extra trigger at the end. Nothing serious.
            db1MovieTrigTStamps(end) = [];
            chMatchTrigFlag = 'good_one_extra_trig';
        % ... more generally it means that some frames were not recorded. It is bad...
        elseif dbDropTime < 2 % ... if less than 2 seconds of data was lost, 
            %removes some of the trigger arbitraly assuming that frames are dropped at a steady state.
            %It is generally not the case so it is wise not to use for
            %final anaysis ...
            inNanIdx = round(linspace(0, in1TrigSetLen(inTSIdx), inDropFrame + 2));
            db1MovieTrigTStamps(inNanIdx(2:end -1)) = [];
            chMatchTrigFlag = 'interpolated_dropped_frames';
        else % if more than 2 seconds interpolates anyway but changes the flag
%             inNanIdx = round(linspace(0, in1TrigSetLen(inTSIdx),inDropFrame + 2));   
%             db1MovieTrigTStamps(inNanIdx(2:end -1)) = [];  %%% Quentin's way

            db1MovieTrigTStamps= linspace(db1MovieTrigTStamps(1), db1MovieTrigTStamps(end), in1MovieLen);    %Stefan's way 2023/01/01
            chMatchTrigFlag = 'too_many_dropped_frames';
        end
    else
        chMatchTrigFlag = 'good';
    end
    sFMAP(ii).inDropFrame = inDropFrame;    
    sFMAP(ii).db1MovieTrigTStamps = db1MovieTrigTStamps;
    sFMAP(ii).chMatchTrigFlag = chMatchTrigFlag;
    fprintf('\r\tMovie %d out of %d:\tITI: %.2f\tDropped frames: %d\tTag: %s', ii, inNMovie, dbITI, inDropFrame, chMatchTrigFlag)
end

%Update sREC
sCFG.sREC = sREC;

%Keeps track of the input in CSG
sCFG.sINPUT.sL0PPCT.chScriptName = sINPUT_1.sCFG.sL0PPCT.chScriptName;
sCFG.sINPUT.sL0PPCT.chTimeComputed = sINPUT_1.sCFG.sL0PPCT.chTimeComputed;
sCFG.sINPUT.sL2DFCP.chScriptName = sINPUT_2.sCFG.sL2DFCP.chScriptName;
sCFG.sINPUT.sL2DFCP.chTimeComputed = sINPUT_2.sCFG.sL2DFCP.chTimeComputed;

%Writes the output in CSG
sCFG.sL3.dbITI = dbITI;
sCFG.sL3.sFMAP = sFMAP;
sCFG.sL3.chScriptName = mfilename('fullpath');
sCFG.sL3.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('\rDone !\r');