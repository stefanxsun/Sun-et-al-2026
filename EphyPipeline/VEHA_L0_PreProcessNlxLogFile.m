function [varargout] = VEHA_L0_PreProcessNlxLogFile(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Sets the source path
chSourcePath = fullfile(sREC.chNlxSessionPath, sREC.chNlxSessionDir);
if ~exist(fullfile(chSourcePath, 'CheetahLogFile.txt'), 'file')
    error('%s is missing from the source directory\r', 'CheetahLogFile.txt')
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L0_PreProcessNlxLogFile';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
chDestFolder = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chDestFolder)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chDestFolder);
end
chDestFile = 'VEHA_L0_PreProcessNlxLogFile.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chDestFolder));
    return
else
    fprintf('Processing %s ...', chDestFolder);
end

%Sets the session name
chSessionName = sREC.chNlxSessionDir;

%Gets the first few lines of the files to check the Cheetah version

%Reads the log file and extracts the time, timestamp values and action
%associated to each event into  respective indices of cLOGFILE 
    %Open the file
hFile = fopen(fullfile(chSourcePath, 'CheetahLogFile.txt') , 'r');
    %Checks the version for neuralynx 
cHEADER     = textscan(hFile, '%[^:] %[^\n]', 20);
inVersion  = find(strcmp('Cheetah Version', cHEADER{1}));
    %Reads the files
if contains(cHEADER{2}(inVersion), '5.6')
    chFormat    = '%*s %*s %*s %s %*s %s %*s %s %*[^\n]';
    cLOGFILE    = textscan(hFile, chFormat, 'HeaderLines', 20);
    blTS        = true;
elseif contains(cHEADER{2}(inVersion), '5.7')
    chFormat    = '%*s %*s %*s %*s %s %*s %s %*s %s %*[^\n]';
    cLOGFILE    = textscan(hFile, chFormat, 'HeaderLines', 21);
    blTS        = true;
elseif contains(cHEADER{2}(inVersion), '6.4')
    chFormat    = '%*s %*s %*s %*s %s %*s %s %*[^\n]';
    cLOGFILE    = textscan(hFile, chFormat, 'HeaderLines', 25);
    blTS        = false;
else
    error('Unsupported version of Cheetah')
end
    % Closes the header
fclose(hFile);


%Finds lines that are not dated events
cMATCH = regexp(cLOGFILE{1}, '[a-z]');
in1IdxToRem = find(~cellfun('isempty', cMATCH));
for ii = 1:length(cLOGFILE)
    cLOGFILE{ii}(in1IdxToRem) = [];
end

%Converts time stamps into number
if blTS, cLOGFILE{2} = cellfun(@(x) str2num(x), cLOGFILE{2}); end

%Gets the precise start date of the recording
db1StartDVec = str2num(regexprep(chSessionName, '[_,-]', ' '));
db1StartDVec(4:6) = str2num(regexprep(cLOGFILE{1}{1}, '[:]', ' '));

%Computes the elapsed time since the beginning of the recording out of the
%dates in the log
db1EventTFromStartSec = nan(length(cLOGFILE{1}), 1);
db2EventDVec = nan(length(cLOGFILE{1}), 6); 
db1TDVec = db1StartDVec;
for ii = 1:length(db1EventTFromStartSec)
    db1TDVec(4:6) = str2num(regexprep(cLOGFILE{1}{ii}, '[:]', ' '));
    db2EventDVec(ii, :) = db1TDVec;
    db1EventTFromStartSec(ii) = NS_CompareDateVector(db1StartDVec, db1TDVec);
end
  
if sCFG.sPARAM.blPlotTStampLinearity
    %Plots the results if needed
    figure, plot(db1EventTFromStartSec, cLOGFILE{2}, '-x'), xlabel('Elapsed time (sec)'), ylabel('TStamp value')
end

%Gets the indices of the event line where the recording was started and
%stopped
cSTART = regexp(cLOGFILE{end}, 'AcquisitionControl::StartRecording');
in1RecStartIdx = find(~cellfun('isempty', cSTART));
cSTOP = regexp(cLOGFILE{end}, 'AcquisitionControl::StopRecording');
in1RecStopIdx = find(~cellfun('isempty', cSTOP));

%Gets the timestamp and the date vector of the first StartRecording event
%(they will serve as anchor points for the computation of the absolute
%values of time stamps)
db1RecStart1DVec = db2EventDVec(in1RecStartIdx(1),:);
if blTS, dbRecStrart1TStamp = cLOGFILE{2}(in1RecStartIdx(1));
else %< -------------- go get the fist time stamp in CSC1
    %Sets the source path
    if ~exist(fullfile(chSourcePath, sREC.cLFPCHAN{1}), 'file')
        error('%s is missing from the source directory\r', sREC.cLFPCHAN{1})
    end
    [TStamps, ~] = Nlx2MatCSC(fullfile(chSourcePath, sREC.cLFPCHAN{1}), [1 0 0 0 0], 1, 1); % Windows
    TStamps = NS_TStampSanityCheck(TStamps); %%%% STEFAN ADDED to fix the jitter from Neuralynx 08/07/2023
    dbRecStrart1TStamp = TStamps(1);
end

%Update sREC
sCFG.sREC = sREC;

%Writes the output in CFG
sCFG.sL0NLF.chLogFileFullPath = fullfile(chSourcePath, 'CheetahLogFile.txt');
sCFG.sL0NLF.cLOGFILE = cLOGFILE;
sCFG.sL0NLF.db2EventDVec = db2EventDVec;
sCFG.sL0NLF.db1EventTFromStartSec = db1EventTFromStartSec;
sCFG.sL0NLF.in1RecStartIdx = in1RecStartIdx;
sCFG.sL0NLF.in1RecStopIdx = in1RecStopIdx;
sCFG.sL0NLF.db1RecStart1DVec = db1RecStart1DVec;
sCFG.sL0NLF.dbRecStrart1TStamp = dbRecStrart1TStamp;
sCFG.sL0NLF.chScriptName = mfilename('fullpath');
sCFG.sL0NLF.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')