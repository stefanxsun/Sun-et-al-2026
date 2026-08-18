function [varargout] = VEHA_L2_MatchOptoLogWithOptoStimSet(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Exits if there is no stimulation log
if isempty(sREC.cOPTOSTIMPROTOCOL)
    error('No stimulation log for %s\r', chSessionName)
end

%Sets the source path for stimulation logs
chSourcePath_1 = fullfile(sREC.chOptoStimSessionPath, sREC.chOptoStimSessionDir);
sSTIMLOGDIR = dir(chSourcePath_1);
inNStimLog = length(sREC.cOPTOSTIMPROTOCOL);
in1LogDirIdx = nan(1, inNStimLog);
for ii = 1:inNStimLog
    blMatch = false;
    inIter = 0;
    while ~blMatch && inIter < length(sSTIMLOGDIR)
        inIter = inIter + 1;
        blMatch = ~isempty(strfind(sSTIMLOGDIR(inIter).name, sREC.cOPTOSTIMPROTOCOL{ii}));
    end
    if ~blMatch
        error('%s does not exist for session %s in %s\r', sREC.cOPTOSTIMPROTOCOL{ii}, chSessionName, chSourcePath_1)
    else
        in1LogDirIdx(ii) = inIter;
    end
end
if length(unique(in1LogDirIdx)) ~= inNStimLog
    error('Several stimulation logs were matched to the same file' )
end

%Checks for presentation sets
chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L1_DetectOptoStimSet');
chDOSFile = 'VEHA_L1_DetectOptoStimSet.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chDOSFile), 'file')
    error('%s does not exist for session %s in %s\r', chDOSFile, chSessionName, chSourcePath_2)
end

%Checks for log file (used to compute the absolute time of time stamps)
chSourcePath_3 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L0_PreProcessNlxLogFile');
chPPNLFFile = 'VEHA_L0_PreProcessNlxLogFile.mat';
if ~exist(fullfile(chSourcePath_3, chSessionName, chPPNLFFile), 'file')
    error('%s does not exist for session %s in %s\r', chPPNLFFile, chSessionName, chSourcePath_3)
end


%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L2_MatchOptoLogWithOptoStimSet';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L2_MatchOptoLogWithOptoStimSet.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

%Loads the result of presentation set detection
sINPUT_1 = load(fullfile(chSourcePath_2, chSessionName, chDOSFile), '-mat');
sINPUT_2 = load(fullfile(chSourcePath_3, chSessionName, chPPNLFFile), '-mat');

%Computes the metrics of the presentation set
in1FirstPres        = sINPUT_1.sCFG.sL1DOS.in1FirstPres;
in1LastPres         = sINPUT_1.sCFG.sL1DOS.in1LastPres;
in1FirstPulse       = sINPUT_1.sCFG.sL1DOS.in1FirstPulse;
in1LastPulse        = sINPUT_1.sCFG.sL1DOS.in1LastPulse;
in1FirstPres_Pls    = find(ismember(in1FirstPulse, in1FirstPres));
in1LastPres_Pls     = find(ismember(in1LastPulse, in1LastPres));
inNPresSet = length(in1FirstPres);
in1NPresInSet = in1LastPres_Pls - in1FirstPres_Pls + 1;
db1PresOffTStamp = sINPUT_1.sCFG.sL1DOS.db1PresOffTStamp;

%Extracts reference time point
db1RecStart1DVec = sINPUT_2.sCFG.sL0NLF.db1RecStart1DVec;
dbRecStrart1TStamp = sINPUT_2.sCFG.sL0NLF.dbRecStrart1TStamp;
    %Computes the date vectors of the last presentation
db2LastPresDVec = nan(inNPresSet, 6);
for ii = 1:inNPresSet
    db2LastPresDVec(ii, :) = NS_NlxTStamp2DateVector(db1RecStart1DVec, dbRecStrart1TStamp, db1PresOffTStamp(in1LastPres(ii)));
end
    %Fetches the date vectors of the time where stim log were saved
db2LogCreationDVec = nan(inNStimLog, 6);
for ii = 1:inNStimLog
    db2LogCreationDVec(ii, :) = datevec(sSTIMLOGDIR(in1LogDirIdx(ii)).date);
end
    %Calculates the lag betwwen last presentation and log creation
db2LagSec = nan(inNPresSet, inNStimLog);
for ii = 1:inNPresSet
    for jj = 1:inNStimLog
        db2LagSec(ii, jj) = NS_CompareDateVector(db2LastPresDVec(ii, :), db2LogCreationDVec(jj, :));
    end
end
%A negative lag means that the log was created before the end of the
%presentation which is impossible
db2LagSec(db2LagSec < 0) = Inf; %Sets negative value to infinity 


%Attributes log to the set that has the most plausible lag betweeen the last
%presentation and the creation of the file
dbMedMinLag = median(min(db2LagSec));
[db1HitVal, in1WhichSet] = min(abs(db2LagSec - dbMedMinLag));

%If one presentation set is attributed to two different logs, keeps the log
%which has the most plausible lag;
if length(unique(in1WhichSet)) ~= length(in1WhichSet)
    bl2Hit = zeros(size(db2LagSec));
    for ii = 1: length(in1WhichSet)
        bl2Hit(in1WhichSet(ii), ii) = 1;
    end
    in1DbHitSetIdx = find(sum(bl2Hit, 2) > 1);
    for ii = 1: length(in1DbHitSetIdx)
        in1DbHitLogIdx = find(in1WhichSet == in1DbHitSetIdx(ii));
        [~, inMin] = min(db1HitVal(in1DbHitLogIdx));
        in1DbHitLogIdx(inMin) = [];
        in1WhichSet(in1DbHitLogIdx) = 0;
    end
end

%Loads the log file, and stores the relevant parameters in the appropriate
%field of the output structure as a function of the type of visual
%stimulation
sSTIMLOG = struct;
in1NPresInLog = nan(1, inNStimLog);
for ii = 1:inNStimLog
    %Skips the Log if no set was attributed to it
    if in1WhichSet(ii) == 0
        fprintf('\rNo set was attributed to %s', sSTIMLOGDIR(in1LogDirIdx(ii)).name)
        continue
    end
    %Loads the log
    sLOAD = load(fullfile(chSourcePath_1, sSTIMLOGDIR(in1LogDirIdx(ii)).name), '-mat');
    %Checks what type of log it is
    if ~strcmp(sLOAD.StimStruct.StimType, 'LaserStime')
        fprintf('\rProtocol non recognized for %s', sSTIMLOGDIR(in1LogDirIdx(ii)).name) 
    else
        %Checks that the log and the set have matching numbers of
        %presentation. Does not record anything if it is not the case
        inLogLen = length(sLOAD.StimStruct.StimLog);
        db1LogWritten = false(1,inLogLen);
        for jj = 1:inLogLen
            db1LogWritten(jj) = sLOAD.StimStruct.StimLog{jj}(1, 1) ~= 0;
        end
        in1NPresInLog(ii) = sum(db1LogWritten);
        if in1NPresInLog(ii) ~= in1NPresInSet(in1WhichSet(ii))
            fprintf('\rMismatch in presentation number for %s', sSTIMLOGDIR(in1LogDirIdx(ii)).name)
            fprintf('\r%d pres in log and %d pres in file', in1NPresInLog(ii), in1NPresInSet(in1WhichSet(ii)))
            continue
        end
        %Stores the output parameters in a structre
        sOPTO.chLogName = sSTIMLOGDIR(in1LogDirIdx(ii)).name;
        sOPTO.sPARAM = sLOAD.StimStruct.StimParameters;
        sOPTO.dbStimMat = sLOAD.StimStruct.StimMatrix;
        sOPTO.db1PulseOnTStamp = sINPUT_1.sCFG.sL1DOS.db1PresOnTStamp(in1FirstPulse(in1FirstPres_Pls(in1WhichSet(ii)):in1LastPres_Pls(in1WhichSet(ii))));
        sOPTO.db1PulseOffTStamp = sINPUT_1.sCFG.sL1DOS.db1PresOffTStamp(in1LastPulse(in1FirstPres_Pls(in1WhichSet(ii)):in1LastPres_Pls(in1WhichSet(ii))));
        sOPTO.db1PresOnTStamp = sINPUT_1.sCFG.sL1DOS.db1PresOnTStamp(in1FirstPres(in1WhichSet(ii)):in1LastPres(in1WhichSet(ii)));
        sOPTO.db1PresOffTStamp = sINPUT_1.sCFG.sL1DOS.db1PresOffTStamp(in1FirstPres(in1WhichSet(ii)):in1LastPres(in1WhichSet(ii)));
        sOPTO.cSTIMLOG = sLOAD.StimStruct.StimLog;
        %Append the structure to the output structure sSTIMLOG
        if isfield(sSTIMLOG, 'sOPTO')
            sSTIMLOG.sOPTO = [sSTIMLOG.sOPTO sOPTO];
        else
            sSTIMLOG.sOPTO = sOPTO;
        end
    end
end

%Update sREC
sCFG.sREC = sREC;

%Writes the output in CFG
sCFG.sL2MSLPS.sSTIMLOG = sSTIMLOG;
sCFG.sL2MSLPS.chScriptName = mfilename('fullpath');
sCFG.sL2MSLPS.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('  Done! \r')