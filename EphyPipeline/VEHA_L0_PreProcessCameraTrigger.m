function [varargout] = VEHA_L0_PreProcessCameraTrigger(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Sets the source path
chTriggerPath = fullfile(sREC.chNlxSessionPath, sREC.chNlxSessionDir);
if ~exist(fullfile(chTriggerPath, sREC.chPupilCameraTrigChan), 'file')
    error('%s is missing from the source directory\r', sREC.chPupilCameraTrigChan)
end

%Check that pupil movie source
chMoviePath = fullfile(sREC.chPupilMovieSessionPath);
if ~exist(chMoviePath, 'dir')
    error('Unable to locate %s in %s\r', sREC.chPupilMovieSessionPath);
end

%Checks that the number of movie file matches found in the directory
%matches the information in sINFO
sMOVIE_DIR = dir(chMoviePath);
bl1IsMovie = false(1, length(sMOVIE_DIR));
for ii = 1:length(sMOVIE_DIR)
    bl1IsMovie(ii) = ~isempty(strfind(sMOVIE_DIR(ii).name, '.mp4')) ||...
        ~isempty(strfind(sMOVIE_DIR(ii).name, '.avi'));
end

% %Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L0_PreProcessCameraTrigger';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
chDestFolder = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chDestFolder)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chDestFolder);
end
chDestFile = 'VEHA_L0_PreProcessCameraTrigger.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chDestFolder));
    return
else
    fprintf('Processing %s ...', chDestFolder);
end

%Defines the range for the recording, extracts and interpolates the timestamps and extracts the sampling rate
[TStamps, Header] = Nlx2MatCSC(fullfile(chTriggerPath, sREC.chPupilCameraTrigChan), [1 0 0 0 0], 1, 1);% Windows
TStamps = NS_TStampSanityCheck(TStamps); %%%% STEFAN ADDED to fix the jitter from Neuralynx 08/07/2023
[in1BegPts, in1EndPts, inCells] = NS_DoDefineContinuousRecording(TStamps);
in1Range=[in1BegPts(sREC.inRecNum), in1EndPts(sREC.inRecNum)];

%Sets the downsampling parameters
sHEADER = NS_ReadHeader(Header);
inSampleRate = sHEADER.SamplingFrequency;
inDSFactor = round(inSampleRate/sCFG.sPARAM.inWorkingSamplingRate);

TStamps = TStamps(in1Range(1):in1Range(2));
db1TStampsInterval = linspace(0, round(mean(diff(TStamps))), 513);  %% Stefan edited 08/07/2023 to use mean of diff instead of diff of (4)-(3)
db1TStamps = repmat(db1TStampsInterval(1:512)', 1, length(TStamps)) + repmat(TStamps, 512, 1);
db1TStamps = NS_DownSampleTrace(db1TStamps(1:end), inDSFactor);

%Extract and downsamples the camera trigger analog
[TSRec, Samples, Header] = Nlx2MatCSC(fullfile(chTriggerPath, sREC.chPupilCameraTrigChan) , [1 0 0 0 1], 1, 2, in1Range); 
if length(TSRec) ~= length(TStamps)
    bl1Sel = ismember(TSRec, TStamps);
    if sum(bl1Sel) ~= length(TStamps); error('TStamps could not be matched'); end
    Samples = Samples(:, bl1Sel);
end
db1CameraTrig = NS_DownSampleTrace(Samples(1:end), inDSFactor);

if isfield(sREC, 'chPupilMovieTrigType')
    chPupilMovieTrigType = sREC.chPupilMovieTrigType;
else
    chPupilMovieTrigType = '_';
end


%Extracts the triggers
try
    bl1TrigUpIdx = db1CameraTrig > range(db1CameraTrig)/2 + min(db1CameraTrig);
    switch chPupilMovieTrigType %Determines the trigger type
        case 'rising';
            bl1TrigIdx = diff(bl1TrigUpIdx) > 0;
        case 'falling';
            bl1TrigIdx = diff(bl1TrigUpIdx) < 0;
        case 'alternate'
            bl1TrigIdx = diff(bl1TrigUpIdx) ~= 0;
        case 'rising_1OutOf2Frame'
            bl1TrigIdx = diff(bl1TrigUpIdx) > 0;
            dbMedDTrigIdx = nanmedian(diff(find(bl1TrigIdx)));
            bl1TrigIdx(find(bl1TrigIdx) + round(dbMedDTrigIdx/2)) = true;
        otherwise %treats as a rising trigger if the movie type is non recognized
            fprintf('\rTrigger type non recognized. Treated as a rising edge\r')
            bl1TrigIdx = diff(bl1TrigUpIdx) > 0;
    end
    db1TrigTStamps = db1TStamps(bl1TrigIdx);
catch
    rmdir(fullfile(chDestPath, chDestMetaFolder, chDestFolder));
    error('Could not extract triggers. Skipped.\r')
end


% %Plot for debugging purpose, uncomment if needed
% db1Time = (db1TStamps - db1TStamps(1))/1000000;
% figure, plot(db1Time, db1CameraTrig)
% hold on, plot(db1Time(bl1TrigIdx), db1CameraTrig(bl1TrigIdx), '.g'), hold off
% title(strrep(chDestFolder, '_', ' '))

%Update sREC
sCFG.sREC = sREC;

%Writes the output in CFG
sCFG.sL0PPCT.db1CamreraTrig = db1CameraTrig;
sCFG.sL0PPCT.db1TStamps = db1TStamps;
sCFG.sL0PPCT.bl1TrigIdx = bl1TrigIdx;
sCFG.sL0PPCT.db1TrigTStamps = db1TrigTStamps;
sCFG.sL0PPCT.chScriptName = mfilename('fullpath');
sCFG.sL0PPCT.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')