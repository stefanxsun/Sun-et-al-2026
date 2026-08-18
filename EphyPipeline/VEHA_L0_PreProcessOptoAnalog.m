function [varargout] = VEHA_L0_PreProcessOptoAnalog(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Sets the source path
chSourcePath = fullfile(sREC.chNlxSessionPath, sREC.chNlxSessionDir);
if ~exist(fullfile(chSourcePath, sREC.cOPTOCHAN{1}), 'file')
    error('%s is missing from the source directory\r', sREC.cOPTOCHAN{1})
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L0_PreProcessOptoAnalog';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
chDestFolder = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chDestFolder)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chDestFolder);
end
chDestFile = 'VEHA_L0_PreProcessOptoAnalog.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chDestFolder));
    return
else
    fprintf('Processing %s ...', chDestFolder);
end

%Defines the range for the recording, extracts and interpolates the timestamps and extracts the sampling rate
%[TStamps, Header] = Nlx2MatCSC(fullfile(chSourcePath, sREC.cOPTOCHAN{1}), [1 0 0 0 0], 1, 1); % Windows
[TStamps, Header] = Nlx2MatCSC_v3(fullfile(chSourcePath, sREC.cOPTOCHAN{1}), [1 0 0 0 0], 1, 1); % Linux Mac
[in1BegPts, in1EndPts, inCells] = NS_DoDefineContinuousRecording(TStamps);
in1Range=[in1BegPts(sREC.inRecNum), in1EndPts(sREC.inRecNum)];

%Sets the downsampling parameters
sHEADER = NS_ReadHeader(Header);
inSampleRate = sHEADER.SamplingFrequency;
inDSFactor = round(inSampleRate/sCFG.sPARAM.inWorkingSamplingRate);

TStamps = TStamps(in1Range(1):in1Range(2));
db1TStampsInterval = linspace(0, TStamps(4) - TStamps(3), 513);
db1TStamps = repmat(db1TStampsInterval(1:512)', 1, length(TStamps)) + repmat(TStamps, 512, 1);
db1TStamps = NS_DownSampleTrace(db1TStamps(1:end), inDSFactor);

%Extract and downsamples the visual analog
%[Samples, Header] = Nlx2MatCSC(fullfile(chSourcePath, sREC.cOPTOCHAN{1}) , [0 0 0 0 1], 1, 2, in1Range); % Windows
[TSRec, Samples, Header] = Nlx2MatCSC_v3(fullfile(chSourcePath, sREC.cOPTOCHAN{1}) , [0 0 0 0 1], 1, 2, in1Range-1); % Mac Linux
if length(TSRec) ~= length(TStamps)
    bl1Sel = ismember(TSRec, TStamps);
    if sum(bl1Sel) ~= length(TStamps); error('TStamps could not be matched'); end
    Samples = Samples(:, bl1Sel);
end
db1OptoAnalog = NS_DownSampleTrace(Samples(1:end), inDSFactor);

%Update sREC
sCFG.sREC = sREC;

%Writes the output in CFG
sCFG.sL0PPOA.db1OAnalog = db1OptoAnalog;
sCFG.sL0PPOA.db1TStamps = db1TStamps;
sCFG.sL0PPOA.chScriptName = mfilename('fullpath');
sCFG.sL0PPOA.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')