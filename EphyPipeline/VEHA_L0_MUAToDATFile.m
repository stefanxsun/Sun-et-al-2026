function [varargout] = VEHA_L0_MUAToDATFile(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Sets the source path
chSourcePath = fullfile(sREC.chNlxSessionPath, sREC.chNlxSessionDir);
for i = 1:length(sREC.cMUACHAN)
    if ~exist(fullfile(chSourcePath, sREC.cMUACHAN{i}), 'file')
        error('%s is missing from the source directory\r', sREC.cMUACHAN{i})
    end
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L0-1-2_UnitClustering';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
chDestFolder = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chDestFolder)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chDestFolder);
end
chDestFile_Mat = 'VEHA_L0_MUAToDATFile.mat';
chDestFile_Dat = 'MUA.dat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile_Mat), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile_Mat, fullfile(chDestPath, chDestMetaFolder, chDestFolder));
    return
else
    fprintf('Processing %s ...', chDestFolder);
end

%Defines the range for the recording, extracts and interpolates the timestamps and extracts the sampling rate
[TStamps, Header] = Nlx2MatCSC(fullfile(chSourcePath, sREC.cLFPCHAN{i}), [1 0 0 0 0], 1, 1); % Windows
% TStamps = NS_TStampSanityCheck(TStamps); %%%% STEFAN ADDED to fix the jitter from Neuralynx 08/07/2023
[in1BegPts, in1EndPts, inCells] = NS_DoDefineContinuousRecording(TStamps);
in1Range=[in1BegPts(sREC.inRecNum), in1EndPts(sREC.inRecNum)];

TStamps = TStamps(in1Range(1):in1Range(2));
db1TStampsInterval = linspace(0, round(mean(diff(TStamps))), 513);  %% Stefan edited 08/07/2023 to use mean of diff instead of diff of (4)-(3)
db1TStamps = repmat(db1TStampsInterval(1:512)', 1, length(TStamps)) + repmat(TStamps, 512, 1);
db1TStamps = db1TStamps(1:end);

%Defines the outputsample rate (%should not be below 20kHz)
sHEADER = NS_ReadHeader(Header);
inSampleRate = sHEADER.SamplingFrequency;
inOutputSampleRate = sCFG.sPARAM.inOutputSampleRate;
inDSFactor = inSampleRate/inOutputSampleRate;
if mod(inDSFactor,1) ~= 0
    error('The output sample rate must be an exact fraction of the original sample rate')
end
db1TStamps = NS_DownSampleTrace(db1TStamps, inDSFactor);

%This map should be loaded as a separate file; 1st row: channel #, 2nd row:
%Neuronexus site #; 3rd row: spatial order from superficial to deep
%CM16
in2SiteMap=[0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15;...
    12 11 10 9 8 7 6 5 1 2 3 4 13 14 15 16; ...
    7 5 3 1 2 4 6 8 16 14 12 10 9 11 13 15];

%creates a matrix to store the data
inTraceLength = floor(((in1Range(2)-in1Range(1)+1)*512)/inDSFactor);
db2Data = nan(size(in2SiteMap,2), inTraceLength);

%Loops through MUAs and detect spikes peak as well as their slope
for i = 1:length(sREC.cMUACHAN)
    %Opens Nlx file and directly extract the samples corresponding to the
    %recording
    [TSRec, Samples, Header] = Nlx2MatCSC(fullfile(chSourcePath, sREC.cLFPCHAN{i}) , [1 0 0 0 1], 1, 2, in1Range); % Windows
    if length(TSRec) ~= length(TStamps)
        bl1Sel = ismember(TSRec, TStamps);
        if sum(bl1Sel) ~= length(TStamps); keyboard; error('TStamps could not be matched'); end
        Samples = Samples(:, bl1Sel);
    end
    sHEADER = NS_ReadHeader(Header);
    inChannel = sHEADER.ADChannel;
    dbBitToVolts = sHEADER.ADBitVolts;
    
    %downsamples and filters the trace then puts it the data matrix
    inShankSite = in2SiteMap(3, in2SiteMap(1,:) == inChannel);
    Samples = Samples(1:end)*dbBitToVolts*1000;
    Samples = NS_DownSampleTrace(Samples, inDSFactor);
    db2Data(inShankSite,:) = Samples;
end

% keyboard
% dbFact = 1;
% inNChan = size(db2Data, 1);
% figure, hold on
% for iChan = 1:inNChan
%     plot(db2Data(iChan, 1:30*inOutputSampleRate) - (iChan * dbFact), 'Color', [iChan/inNChan 0 0.5])
% end

%Gets the min and the max of the data (will be usefull to rescale the
%output)
db1DatRange = [min(db2Data(:)) max(db2Data(:))];

%Update sREC
sCFG.sREC = sREC;

%Writes the output in CFG
sCFG.sL0MUATDF.db1DatRange           = db1DatRange;
sCFG.sL0MUATDF.in2SiteMap            = in2SiteMap;
sCFG.sL0MUATDF.inSampleRate          = inOutputSampleRate;
sCFG.sL0MUATDF.db1TStamps            = db1TStamps;
sCFG.sL0MUATDF.in1MUAFilterSettings  = [sHEADER.DspLowCutFrequency sHEADER.DspHighCutFrequency];
sCFG.sL0MUATDF.chMUAFilterSource     = 'Neuralynx';
sCFG.sL0MUATDF.chScriptName          = mfilename('fullpath');
sCFG.sL0MUATDF.chTimeComputed        = datestr(now);

%Saves the output parameter structure
save(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile_Mat), 'sCFG', '-v7.3');
%Writes the .dat file
NS_WriteMUADatFile(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile_Dat), db2Data);

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')