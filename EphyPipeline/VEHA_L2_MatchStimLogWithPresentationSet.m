function [varargout] = VEHA_L2_MatchStimLogWithPresentationSet(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Exits if there is no stimulation log
if isempty(sREC.cVISUALSTIMPROTOCOL)
    error('No stimulation log for %s\r', chSessionName)
end

%Sets the source path for stimulation logs
chSourcePath_1 = fullfile(sREC.chVisualStimSessionPath,sREC.chMouseCage);   
sSTIMLOGDIR = dir(chSourcePath_1);
inNStimLog = length(sREC.cVISUALSTIMPROTOCOL); 
in1LogDirIdx = nan(1, inNStimLog);
for ii = 1:inNStimLog
    blMatch = false;
    inIter = 0;
    while ~blMatch && inIter < length(sSTIMLOGDIR)
        inIter = inIter + 1;
        blMatch = ~isempty(strfind(sSTIMLOGDIR(inIter).name, sREC.cVISUALSTIMPROTOCOL{ii}));
    end
    if ~blMatch
        error('%s does not exist for session %s in %s\r', sREC.cVISUALSTIMPROTOCOL{ii}, chSessionName, chSourcePath_1)
    else
        in1LogDirIdx(ii) = inIter;
    end
end
if length(unique(in1LogDirIdx)) ~= inNStimLog
    error('Several stimulation logs were matched to the same file' )
end

%Checks for presentation sets
chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L1_DetectPresentationSet');
chDPFile = 'VEHA_L1_DetectPresentationSet.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chDPFile), 'file')
    error('%s does not exist for session %s in %s\r', chDPFile, chSessionName, chSourcePath_2)
end

%Checks for log file (used to compute the absolute time of time stamps)
chSourcePath_3 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L0_PreProcessNlxLogFile');
chPPNLFFile = 'VEHA_L0_PreProcessNlxLogFile.mat';
if ~exist(fullfile(chSourcePath_3, chSessionName, chPPNLFFile), 'file')
    error('%s does not exist for session %s in %s\r', chPPNLFFile, chSessionName, chSourcePath_3)
end


%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L2_MatchStimLogWithPresentationSet';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L2_MatchStimLogWithPresentationSet.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

%Loads the result of presentation set detection
sINPUT_1 = load(fullfile(chSourcePath_2, chSessionName, chDPFile), '-mat');
sINPUT_2 = load(fullfile(chSourcePath_3, chSessionName, chPPNLFFile), '-mat');

%Computes the metrics of the presentation set
in1FirstPres = sINPUT_1.sCFG.sL1DP.in1FirstPres;
in1LastPres = sINPUT_1.sCFG.sL1DP.in1LastPres;
inNPresSet = length(in1FirstPres);
in1NPresInSet = in1LastPres - in1FirstPres + 1;
db1PresOffTStamp = sINPUT_1.sCFG.sL1DP.db1PresOffTStamp;

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
% for ii = 1:inNPresSet
%     for jj = 1:inNStimLog
%         db2LagSec(ii, jj) = NS_CompareDateVector(db2LastPresDVec(ii, :), db2LogCreationDVec(jj, :));
%     end
% end
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
        [ignore, inMin] = min(db1HitVal(in1DbHitLogIdx));
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
    %%%%%%%%%%%%%%% Stefan edited
    visualstim = load(fullfile(chSourcePath_1, sSTIMLOGDIR(in1LogDirIdx(ii)).name));
    sLOAD.StimStruct.StimType='Gratings';
    sLOAD.StimStruct.StimMatrix(1,:) = visualstim(:,2)'; %ORT
    sLOAD.StimStruct.StimMatrix(2,:) = visualstim(:,4)'; %SF
    sLOAD.StimStruct.StimMatrix(3,:) = visualstim(:,3)'; %TF
    sLOAD.StimStruct.StimMatrix(4,:) = visualstim(:,1)'/100; %CRF
    sLOAD.StimStruct.StimMatrix(5,:) = visualstim(:,5)'/2; %diameter to radius 
    
    sLOAD.StimStruct.StimParameters.Orientation = unique(visualstim(:,2)');
    sLOAD.StimStruct.StimParameters.SpatialFrequency = unique(visualstim(:,4)');
    sLOAD.StimStruct.StimParameters.TemporalFrequency = unique(visualstim(:,3)');
    sLOAD.StimStruct.StimParameters.Contrast = unique(visualstim(:,1)'/100);
    sLOAD.StimStruct.StimParameters.SquareGrating = 0;
    sLOAD.StimStruct.StimParameters.MaskRadiusInVisualDegree = unique(visualstim(:,5)'/2);
    sLOAD.StimStruct.StimParameters.NumberOfPresentations = size(visualstim,1)./...
        (length(sLOAD.StimStruct.StimParameters.Orientation)*...
        length(sLOAD.StimStruct.StimParameters.SpatialFrequency)*...
        length(sLOAD.StimStruct.StimParameters.TemporalFrequency)*...
        length(sLOAD.StimStruct.StimParameters.Contrast)*...
        length(sLOAD.StimStruct.StimParameters.MaskRadiusInVisualDegree));
    sLOAD.StimStruct.StimParameters.BlankDuration = unique(visualstim(:,7));
    sLOAD.StimStruct.StimParameters.StimulusDuration = unique(visualstim(:,6));
    sLOAD.StimStruct.StimParameters.DrawMask = 1;
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Checks what type of log it is
    switch sLOAD.StimStruct.StimType
        case 'Gratings'
            %Checks that the log and the set have matching numbers of
            %presentation. Does not record anything if it is not the case
%             inLogLen = length(sLOAD.StimStruct.StimLog);
%             db1LogWritten = nan(1,inLogLen);
%             for jj = 1:inLogLen
%                 db1LogWritten(jj) = sLOAD.StimStruct.StimLog{jj}(1, 1) ~= 0;
%             end
%             in1NPresInLog(ii) = sum(db1LogWritten);
%             if in1NPresInLog(ii) ~= in1NPresInSet(in1WhichSet(ii))
%                 fprintf('\rMismatch in presentation number for %s', sSTIMLOGDIR(in1LogDirIdx(ii)).name)
%                 fprintf('\r%d pres in log and %d pres in file', in1NPresInLog(ii), in1NPresInSet(in1WhichSet(ii)))
%                 continue
%             end
            %Stores the output parameters in a structre
            sGRATING.chLogName = sSTIMLOGDIR(in1LogDirIdx(ii)).name;
            sGRATING.sPARAM = sLOAD.StimStruct.StimParameters;
            sGRATING.dbStimMat = sLOAD.StimStruct.StimMatrix;
            sGRATING.db1PresOnTStamp = sINPUT_1.sCFG.sL1DP.db1PresOnTStamp(in1FirstPres(in1WhichSet(ii)):in1LastPres(in1WhichSet(ii)));
            sGRATING.db1PresOffTStamp = sINPUT_1.sCFG.sL1DP.db1PresOffTStamp(in1FirstPres(in1WhichSet(ii)):in1LastPres(in1WhichSet(ii)));
            sGRATING.cFRAMEONTSTAMP = sINPUT_1.sCFG.sL1DP.cFRAMEONTSTAMP(in1FirstPres(in1WhichSet(ii)):in1LastPres(in1WhichSet(ii)));
%             sGRATING.cSTIMLOG = sLOAD.StimStruct.StimLog;
            %Append the structure to the output structure sSTIMLOG
            if isfield(sSTIMLOG, 'sGRATING')
                sSTIMLOG.sGRATING = [sSTIMLOG.sGRATING sGRATING];
            else
                sSTIMLOG.sGRATING = sGRATING;
            end
        case 'Movie'
            %Checks that the log and the set have matching numbers of
            %presentation. Does not record anything if it is not the case
%             in1NPresInLog(ii) = sum(sLOAD.StimStruct.StimLog(:,2) ~= 0);
%             if in1NPresInLog(ii) ~= in1NPresInSet(in1WhichSet(ii))
%                 fprintf('\rMismatch in presentation number for %s', sSTIMLOGDIR(in1LogDirIdx(ii)).name)
%                 fprintf('\r%d pres in log and %d pres in file', in1NPresInLog(ii), in1NPresInSet(in1WhichSet(ii)))
%                 continue
%             end
            %Stores the output parameters in a structre
            sMOVIE.chLogName = sSTIMLOGDIR(in1LogDirIdx(ii)).name;
            sMOVIE.sPARAM = sLOAD.StimStruct.StimParameters;
            sMOVIE.in3MovieMat = sLOAD.StimStruct.MovieMatrix;
            sMOVIE.db1PresOnTStamp = sINPUT_1.sCFG.sL1DP.db1PresOnTStamp(in1FirstPres(in1WhichSet(ii)):in1LastPres(in1WhichSet(ii)));
            sMOVIE.db1PresOffTStamp = sINPUT_1.sCFG.sL1DP.db1PresOffTStamp(in1FirstPres(in1WhichSet(ii)):in1LastPres(in1WhichSet(ii)));
            sMOVIE.cFRAMEONTSTAMP = sINPUT_1.sCFG.sL1DP.cFRAMEONTSTAMP(in1FirstPres(in1WhichSet(ii)):in1LastPres(in1WhichSet(ii)));
            sMOVIE.in2StimLog = sLOAD.StimStruct.StimLog;
            %Append the structure to the output structure sSTIMLOG in the
            %relevant field depending on what type of movie was displayed
            if regexp(sMOVIE.sPARAM.moviefile, 'Natural')
                if isfield(sSTIMLOG, 'sNATURAL_MOVIE')
                    sSTIMLOG.sNATURAL_MOVIE = [sSTIMLOG.sNATURAL_MOVIE sMOVIE];
                else
                    sSTIMLOG.sNATURAL_MOVIE = sMOVIE;
                end 
            elseif regexp(sMOVIE.sPARAM.moviefile, 'PhaseRandomized')
                if isfield(sSTIMLOG, 'sPHASERAND_MOVIE')
                    sSTIMLOG.sPHASERAND_MOVIE = [sSTIMLOG.sPHASERAND_MOVIE sMOVIE];
                else
                    sSTIMLOG.sPHASERAND_MOVIE = sMOVIE;
                end 
            elseif regexp(sMOVIE.sPARAM.moviefile, 'BrownNoise')
                if isfield(sSTIMLOG, 'sBROWN_NOISE_MOVIE')
                    sSTIMLOG.sBROWN_NOISE_MOVIE = [sSTIMLOG.sBROWN_NOISE_MOVIE sMOVIE];
                else
                    sSTIMLOG.sBROWN_NOISE_MOVIE = sMOVIE;
                end 
            elseif regexp(sMOVIE.sPARAM.moviefile, 'PinkNoise')
                if isfield(sSTIMLOG, 'sPINK_NOISE_MOVIE')
                    sSTIMLOG.sPINK_NOISE_MOVIE = [sSTIMLOG.sPINK_NOISE_MOVIE sMOVIE];
                else
                    sSTIMLOG.sPINK_NOISE_MOVIE = sMOVIE;
                end 
            elseif regexp(sMOVIE.sPARAM.moviefile, 'WhiteNoise')
                if isfield(sSTIMLOG, 'sWHITE_NOISE_MOVIE')
                    sSTIMLOG.sWHITE_NOISE_MOVIE = [sSTIMLOG.sWHITE_NOISE_MOVIE sMOVIE];
                else
                    sSTIMLOG.sWHITE_NOISE_MOVIE = sMOVIE;
                end 
            else
                if isfield(sSTIMLOG, 'sUNKNOWN_MOVIE')
                    sSTIMLOG.sUNKNOWN_MOVIE = [sSTIMLOG.sUNKNOWN_MOVIE sMOVIE];
                else
                    sSTIMLOG.sUNKNOWN_MOVIE = sMOVIE;
                end 
            end
        otherwise
           fprintf('\rProtocol non recognized for %s', sSTIMLOGDIR(in1LogDirIdx(ii)).name) 
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