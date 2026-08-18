function [varargout] = VEHA_L0_PreProcessLFP(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Checks for the proper number of argument
nargoutchk(0,1);

%Sets the source path
chSourcePath = fullfile(sREC.chNlxSessionPath, sREC.chNlxSessionDir);
for i = 1:length(sREC.cLFPCHAN)
    if ~exist(fullfile(chSourcePath, sREC.cLFPCHAN{i}), 'file')
        error('%s is missing from the source directory\r', sREC.cLFPCHAN{i})
    end
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L0_PreProcessLFP';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
chDestFolder = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chDestFolder)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chDestFolder);
end
chDestFile = 'VEHA_L0_PreProcessLFP.mat';
%Checks that the data do not exist

if exist(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'file')
    if ~sCFG.sPARAM.blOverwrite
        fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chDestFolder))
        return
    else
        delete(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile))
    end
end
fprintf('Processing %s ...', chDestFolder)

%Defines the range for the recording, extracts and interpolates the timestamps and extracts the sampling rate
[TStamps, Header] = Nlx2MatCSC(fullfile(chSourcePath, sREC.cLFPCHAN{i}), [1 0 0 0 0], 1, 1); % Windows
TStamps = NS_TStampSanityCheck(TStamps); %%%% STEFAN ADDED to fix the jitter from Neuralynx 08/07/2023
% [TStamps, Header] = Nlx2MatCSC_v3(fullfile(chSourcePath, sREC.cLFPCHAN{i}), [1 0 0 0 0], 1, 1); % Mac Linux
[in1BegPts, in1EndPts] = NS_DoDefineContinuousRecording(TStamps);
in1Range=[in1BegPts(sREC.inRecNum), in1EndPts(sREC.inRecNum)];

TStamps = TStamps(in1Range(1):in1Range(2));
db1TStampsInterval = linspace(0, round(mean(diff(TStamps))), 513);  %% Stefan edited 08/07/2023 to use mean of diff instead of diff of (4)-(3)
db1TStamps = repmat(db1TStampsInterval(1:512)', 1, length(TStamps)) + repmat(TStamps, 512, 1);
db1TStamps = db1TStamps(1:end);

sHEADER = NS_ReadHeader(Header);
inSampleRate = sHEADER.SamplingFrequency;

%Sets up the final smaple rates and the filter 
inOutputSampleRate = sCFG.sPARAM.inOutputSampleRate;
inDownSamplingFactor = inSampleRate/inOutputSampleRate;
if mod(inDownSamplingFactor, 1)~=0
    error('The sampling rate is not a direct multiple of the output sampling rate')
end
db1FilterRange = sCFG.sPARAM.db1FilterRange;
inNyqFreq=inOutputSampleRate/2;
[B, A]=butter(2, db1FilterRange/inNyqFreq);

% %This map should be loaded as a separate file; 1st row: channel #, 2nd row:
% %Neuronexus site #; 3rd row: spatial order from superficial to deep
% %A16
% in2SiteMap=[0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; ...
%     12 10 14 6 8 16 4 2 1 3 15 7 5 13 9 11; ...
%     12 10 14 6 8 16 4 2 1 3 15 7 5 13 9 11];

%This map should be loaded as a separate file; 1st row: channel #, 2nd row:
%Neuronexus site #; 3rd row: spatial order from superficial to deep
%CM16
in2SiteMap=[0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15;...
    12 11 10 9 8 7 6 5 1 2 3 4 13 14 15 16; ...
    7 5 3 1 2 4 6 8 16 14 12 10 9 11 13 15];

%creates a matrix to store the data
inTraceLength = floor(((in1Range(2)-in1Range(1)+1)*512)/inDownSamplingFactor); % Windows
db2Data = nan(size(in2SiteMap,2), inTraceLength);

%Downsamples the timestamps
db1TStamps = NS_DownSampleTrace(db1TStamps, inDownSamplingFactor);

%Fills the matrix with the data after downspampling and filtering them
for i = 1:length(sREC.cLFPCHAN)
    %Opens Nlx file and directly extract the samples corresponding to the
    %recording
    [TSRec, Samples, Header] = Nlx2MatCSC(fullfile(chSourcePath, sREC.cLFPCHAN{i}) , [1 0 0 0 1], 1, 2, in1Range); % Windows
    %[TSRec, Samples, Header] = Nlx2MatCSC_v3(fullfile(chSourcePath, sREC.cLFPCHAN{i}) , [1 0 0 0 1], 1, 2, in1Range - 1); % Mac Linux
    if length(TSRec) ~= length(TStamps)
        bl1Sel = ismember(TSRec, TStamps);
        if sum(bl1Sel) ~= length(TStamps); error('TStamps could not be matched'); end
        Samples = Samples(:, bl1Sel);
    end
    sHEADER = NS_ReadHeader(Header);
    inChannel = sHEADER.ADChannel;
    dbBitToVolts = sHEADER.ADBitVolts;
    
    %downsamples and filters the trace then puts it the data matrix
    inShankSite = in2SiteMap(3, in2SiteMap(1,:) == inChannel);
    Samples = Samples(1:end)*dbBitToVolts*1000;
    Samples = NS_DownSampleTrace(Samples, inDownSamplingFactor);
    db2Data(inShankSite,:) = filtfilt(B,A,Samples);
end

%Checks for dead channels and estimates them by interpolating spacially
%between the two adjacent channels
for i = 1:length(sREC.cLFPDEADCHAN)
    [Header] = Nlx2MatCSC(fullfile(chSourcePath, sREC.cLFPCHAN{i}) , [0 0 0 0 1], 1, 1); % Windows
    %[Header] = Nlx2MatCSC_v3(fullfile(chSourcePath, sREC.cLFPDEADCHAN{i}) , [0 0 0 0 0], 1, 1);
    sHEADER = NS_ReadHeader(Header);
    inChannel = sHEADER.ADChannel;
    inShankSite = in2SiteMap(3, in2SiteMap(1,:) == inChannel);
    if isnan(db2Data(inShankSite,1)) && inShankSite ~= 1 && inShankSite ~= 16
        db2Data(inShankSite,:) = mean([db2Data(inShankSite-1,:);db2Data(inShankSite-1,:)]);
    else
        fprintf('The location reported for dead channel: %s is inconsistent. Aborted.\r', sREC.cLFPCHAN{i})
        return
    end
end

% keyboard
% dbFact = 1;
% inNChan = size(db2Data, 1);
% figure, hold on
% for iChan = 1:inNChan
%     plot(db2Data(iChan, 1:30*inOutputSampleRate) - (iChan * dbFact), 'Color', [iChan/inNChan 0 0.5])
% end

%Update sREC
sCFG.sREC = sREC;

%Writes the output in CFG
sCFG.sL0PPLFP.db2LFP = db2Data;
sCFG.sL0PPLFP.db1TStamps = db1TStamps;
sCFG.sL0PPLFP.in2SiteMap = in2SiteMap;
sCFG.sL0PPLFP.chScriptName = mfilename('fullpath');
sCFG.sL0PPLFP.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')