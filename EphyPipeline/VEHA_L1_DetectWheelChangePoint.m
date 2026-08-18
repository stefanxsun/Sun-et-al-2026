function [varargout] = VEHA_L1_DetectWheelChangePoint(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the source path
chSourcePath = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L0_PreProcessWheelRotation');
chPPWRFile = 'VEHA_L0_PreProcessWheelRotation.mat';
if ~exist(fullfile(chSourcePath, chSessionName, chPPWRFile), 'file')
    error('%s does not exist for session %s in %s\r', chPPWRFile, chSessionName, chSourcePath)
end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L1_DetectWheelChangePoint';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L1_DetectWheelChangePoint.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

%Loads the preprocessed wheel recordings and extracts what is needed
sINPUT = load(fullfile(chSourcePath, chSessionName, chPPWRFile), '-mat');

db1SpeedMpS     = sINPUT.sCFG.sL0PPWR.db1SpeedMpS;
db1TStamps      = sINPUT.sCFG.sL0PPWR.db1TStamps;
inSampleRate    = sINPUT.sCFG.sL0PPWR.inOutputSampleRate;

%Sets som parameters 
dbWindowLenSec = sCFG.sPARAM.dbWindowLenSec; % set the temoporal resolution of the analysis
bl1IsNumeric = double(~isnan(db1SpeedMpS)); %This will be usefull to compute the moving SD
if sCFG.sPARAM.blDoPlot %Computes the time for plotting purposes
    db1Time = (db1TStamps - db1TStamps(1))./1000000;
end

%Computes the sd over a moving window (this part is the most
%computationaly expensive)%Update sREC
sCFG.sREC = sREC;
inWLen = round(dbWindowLenSec*inSampleRate);
if mod(inWLen, 2) ~= 0, inWLen = inWLen + 1; end %Makes sure the window length is even
in1Win  = ones(1,inWLen);
db1MovAvrgSpeed         = conv2(db1SpeedMpS, in1Win,'same');
in1DoF                  = conv2(bl1IsNumeric, in1Win,'same');
db1MovAvSpeedSquare     = conv2(db1SpeedMpS.^2, in1Win,'same');
db1SpeedMovSD           = sqrt((db1MovAvSpeedSquare - db1MovAvrgSpeed.^2./in1DoF)./(in1DoF-1));

%renormalizes the moving average speed
db1MovAvrgSpeed = db1MovAvrgSpeed./in1DoF;

%Computes a forward zscore corresponding to the mean of the speed in the
%window after the point expressed in units of the standard deviation of the
%speed in the window before the point. Computes a backward zscore following
%a similar principle.
db1ZForward  = [nan(1, inWLen) db1MovAvrgSpeed(inWLen + (inWLen/2) + 1:end -(inWLen/2))...
    ./db1SpeedMovSD((inWLen/2):end - (inWLen/2) - inWLen - 1) nan(1, inWLen)];
db1ZBackward  = [nan(1, inWLen) db1MovAvrgSpeed(inWLen/2 :end -(inWLen/2) - inWLen - 1)...
    ./db1SpeedMovSD(inWLen + inWLen/2:end - inWLen/2 - 1) nan(1, inWLen)];


%Threshold the moving SD to get a crude estimate of the period of mobility
%and a first estimate of transition points
% fprintf('Moving SD SD: %.4f    \r', std(db1SpeedMovSD)), return
bl1ZSDSig           = db1SpeedMovSD > 0.02;  %the threshold is empirical and might change if the moving speed is smoothed differently 
bl1ZSDSig([1 end])  = 0; %Makes sure that the recording begins and ends with periods of immobility
in1OnIdx    = find(diff(bl1ZSDSig) == 1); %first estimates of 'wheel on'
in1OffIdx   = find([false diff(bl1ZSDSig) == -1]); %first estimate 'wheel off'


%Removes on and off trigger on contiguous movement periods if they follow
%each others too closely
in1RemIdx = find(in1OnIdx(2:end) - in1OffIdx(1:end - 1) <= inWLen);
in1OnIdx(in1RemIdx + 1) = [];
in1OffIdx(in1RemIdx) = [];

%Gets a better estimate using the maximum of the moving zscore in a window
%around each points whose length is defined by window length sec
for ii = 1:length(in1OnIdx)
    if in1OnIdx(ii) == 1, continue, end %skips the beginning of the recording if it is a period of mouvement
    inBegWin    = max(in1OnIdx(ii) - inWLen/2, 1);
    inEndWind   = min(in1OnIdx(ii) + inWLen/2, length(db1SpeedMpS));
    [~, inMaxIdx] = max(db1ZForward(inBegWin : inEndWind));
    in1OnIdx(ii) = inBegWin + inMaxIdx - 1;
end
for ii = 1:length(in1OffIdx)
    if in1OffIdx(ii) == length(db1SpeedMpS), continue, end %skips the end of the recording if it is a period of mouvement
    inBegWin    = max(in1OffIdx(ii) - inWLen/2, 1);
    inEndWind   = min(in1OffIdx(ii) + inWLen/2, length(db1SpeedMpS));
    [~, inMaxIdx] = max(db1ZBackward(inBegWin : inEndWind));
    in1OffIdx(ii) = inBegWin + inMaxIdx - 1;
end

%Removes periods of movement if they are too short
in1RemIdx = find(in1OffIdx - in1OnIdx <= inWLen/2);
in1OnIdx(in1RemIdx) = [];
in1OffIdx(in1RemIdx) = [];

%Checks that the average speed during moving period is not to low (it is
%typically above 0.2-0.5 meter per seconds but can go lower than that)
db1MovingAvSpeed   = nan(size(in1OnIdx));
for ii = 1:length(in1OffIdx)
    db1MovingAvSpeed(ii) = mean(abs(db1SpeedMpS(in1OnIdx(ii):in1OffIdx(ii))));
end
in1RemIdx = find(db1MovingAvSpeed <= 0.04);
in1OnIdx(in1RemIdx) = [];
in1OffIdx(in1RemIdx) = [];

%Plots the result for debugging purposes if asked by the user.
if sCFG.sPARAM.blDoPlot
    figure
    plot(db1Time, db1SpeedMpS, 'k'), db1YL = ylim;
    hold on,
    for ii = 1:length(in1OnIdx)
        plot(db1Time([in1OnIdx(ii) in1OnIdx(ii)]), db1YL, 'g')
    end
    for ii = 1:length(in1OffIdx)
        plot(db1Time([in1OffIdx(ii) in1OffIdx(ii)]), db1YL, 'r')
    end
    xlabel('time (s)'), ylabel('Speed (m.s-1)')
    title(strrep(chSessionName, '_', '\_'))
end

%Update sREC
sCFG.sREC = sREC;

%Keeps track of the input in CSG
sCFG.sINPUT.sL0PPPC.sPARAM          = sINPUT.sCFG.sPARAM;
sCFG.sINPUT.sL0PPPC.chScriptName    = sINPUT.sCFG.sL0PPWR.chScriptName;
sCFG.sINPUT.sL0PPPC.chTimeComputed  = sINPUT.sCFG.sL0PPWR.chTimeComputed;

%Writes the output in CSG
sCFG.sL1DWCP.in1WheelOnIdx      = in1OnIdx;
sCFG.sL1DWCP.in1WheelOffIdx     = in1OffIdx;
sCFG.sL1DWCP.db1WheelOnTStamp   = db1TStamps(in1OnIdx);
sCFG.sL1DWCP.db1WheelOffTStamp  = db1TStamps(in1OffIdx);
sCFG.sL1DWCP.inSampleRate       = inSampleRate;
sCFG.sL1DWCP.chScriptName       = mfilename('fullpath');
sCFG.sL1DWCP.chTimeComputed     = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')