function VEHA_L2_ClusterCut_GUI()
%GUI used to load session, computes a nd displays quality metrics for
%cluster, calls phy kwik-gui to visualize and cluster-cut the data and
%export the clusters.
%
%phy kwik-gui is part of the klusta suit written in python and developped
%by the team of Ken Harris in London. Here it is recruited to the process
%of clustering with a system call.

%Defines global variables -------------------------------------------------
global hQ_TABLE hLOAD_SESSION_BUTTON hCALL_KWIKGUI_BUTTON hUPDATE_METRIC_BUTTON hEXPORT_CLUSTER_BUTTON
global chBaseDirectory
global chEnv

chEnv = 'klusta'; %Name of the environment of neuralynx (the name is computer dependent and decided by the user when installing the python package klusta)
chBaseDirectory = 'E:\Ephy\VisExpHighAll\VEHA_L0-1-2_UnitClustering';


%Defines the figure and the controls
hCQ_GUI = figure('Visible', 'on', 'Position', [500, 500, 522, 400]);

%Defines the table where quality metrics are going to be displayed
cCOL_LABEL  = {'Cluster', 'Type', 'N-Spike', 'Isolation Dist', 'L-Ratio', 'ISI < 2ms'};
cCOL_FORMAT = {'short', 'char', 'short', 'short', 'short', 'short'};
hQ_TABLE = uitable('Parent', hCQ_GUI, 'Units', 'normalized', ...
    'Position', [0.05,0.20,0.9,0.75], 'ColumnName', ...
    cCOL_LABEL, 'ColumnFormat', cCOL_FORMAT, 'RowName', {});

hLOAD_SESSION_BUTTON = uicontrol('Parent', hCQ_GUI, 'Style', 'pushbutton', ...
    'String', 'Open Session', 'Units', 'normalized', 'Position', [0.05,0.05,0.2,0.1], ...
    'BackgroundColor', [0.2 0.5 0.8], 'Callback', {@OpenSessionCallback});

hCALL_KWIKGUI_BUTTON = uicontrol('Parent', hCQ_GUI, 'Style', 'pushbutton', ...
    'String', 'Call Kwik-Gui', 'Units', 'normalized', 'Position', [0.283,0.05,0.2,0.1], ...
    'BackgroundColor', [0.4 0.5 0.6], 'Callback', {@CallKGuiCallback}, ...
    'Enable', 'off');

hUPDATE_METRIC_BUTTON = uicontrol('Parent', hCQ_GUI, 'Style', 'pushbutton', ...
    'String', 'Uptade Metrics', 'Units', 'normalized', 'Position', [0.516,0.05,0.2,0.1], ...
    'BackgroundColor', [0.6 0.5 0.4], 'Callback', {@UpdateMetricCallback}, ...
    'Enable', 'off');

hEXPORT_CLUSTER_BUTTON = uicontrol('Parent', hCQ_GUI, 'Style', 'pushbutton', ...
    'String', 'Export Clusters', 'Units', 'normalized', 'Position', [0.75,0.05,0.2,0.1], ...
    'BackgroundColor', [0.8 0.5 0.2], 'Callback', {@ExpClusterCallback}, ...
    'Enable', 'off');
    

%Callbacks ----------------------------------------------------------------
function OpenSessionCallback(source, eventdata)
global hCALL_KWIKGUI_BUTTON hUPDATE_METRIC_BUTTON hEXPORT_CLUSTER_BUTTON
global chBaseDirectory chBaseName chKwikFile chKwxFile chL0MUATF_File

%Selects the folder
[chBaseName] = uigetdir(chBaseDirectory, 'Choose session directory:');
[chDirPath, chBaseName] = fileparts(chBaseName);

%Checks that the selected directory is inside the base directory
if ~strcmp(chBaseDirectory, chDirPath)
    error('The directory should be in %s', chBaseDirectory)
end

%Computes the name of the required input files and check for the existence
chKwikFile  = fullfile(chBaseDirectory, chBaseName, [chBaseName '.kwik']);
chKwxFile   = fullfile(chBaseDirectory, chBaseName, [chBaseName '.kwx']);
chL0MUATF_File = fullfile(chBaseDirectory, chBaseName, 'VEHA_L0_MUAToDATFile.mat');
if ~exist(chL0MUATF_File, 'file')
    error('%s not computed for session %s\r', 'VEHA_L0_MUAToDATFile.mat', chBaseName)
elseif ~exist(chKwikFile, 'file')
    error('%s has not been computed for session %s\r', chBaseName)
elseif ~exist(chKwxFile, 'file')
    error('%s has not been computed for session %s\r', chBaseName)
end

%Computes the metrics and load them in the table
 ComputeMetrics()

 %Enable the other callback buttons
 set(hCALL_KWIKGUI_BUTTON, 'Enable', 'On');
 set(hUPDATE_METRIC_BUTTON, 'Enable', 'On');
 set(hEXPORT_CLUSTER_BUTTON, 'Enable', 'On');

function CallKGuiCallback(source, eventdata)
global chBaseDirectory chBaseName
global chEnv

%CDs to the directory (otherwise the system call will be made into C: and
%want recognize other drives in windows)
chOldPath = cd;
cd(fullfile(chBaseDirectory, chBaseName));

%Makes a system call to open phy kwik-gui
if isunix
    chCMD = sprintf('../../VEHA_L2_CallKwikGUI.sh %s %s', chEnv, [chBaseName '.kwik']); %cell array of system commands . Callas a secondary bash file
else
    chCMD = sprintf('activate %s & phy kwik-gui %s &', chEnv, [chBaseName '.kwik']); %cell array of system commands
end
[blStat, chCmdOut] = system(chCMD, '-echo');
if blStat %status is zero if there is an error
    %         keyboard
    error('ERROR in system command with report:\n%s', chCmdOut)
end

% disp('Rototoooooo')
cd(chOldPath)

function UpdateMetricCallback(source, eventdata)
%Recomputes the metrics and load them in the table 
 ComputeMetrics()

function ExpClusterCallback(source, eventdata)
global chBaseDirectory chBaseName chL0MUATF_File
global sPRM_KLUSTA sCLUSTER bl1GoodCluster in1SpkTime in1SpkClu db3FeaturesMask

%Updates metrics in case user forgets
ComputeMetrics();

%checks if there are good clusters
if ~any(bl1GoodCluster)
    disp('There is no good cluster to export. Recut or load another file')
    return
else
    %Communicate with angry user
    fprintf('Computing TStamps and waveforms for the good clusters in %s. This may take a while....\r', chBaseName)
end

%Loads the input file 
sINPUT_1 = load(chL0MUATF_File, '-mat'); sINPUT_1 = sINPUT_1.sCFG;
inSampleRate = sINPUT_1.sL0MUATDF.inSampleRate;

%Checks if MUA.dat is present inside the home directory
chMUADatFile = fullfile(chBaseDirectory, chBaseName, 'MUA.dat');
if ~exist(chMUADatFile, 'file')
    disp('MUA.dat been deleted to gain space. We will recompute it');
    sINPUT_1.sPARAM.blOverwrite = true;
    VEHA_L0_MUAToDATFile(sINPUT_1)
end

%Extracts the MUA file and rescales it so that its value are in mV
disp('Reading MUA.dat ...')
db2MUA      = NS_ReadMUADatFile(chMUADatFile);
db1DatRange = sINPUT_1.sL0MUATDF.db1DatRange;
dbMed       = median(db1DatRange);
db2MUA      = (db2MUA * diff(db1DatRange)./(2*32768)) + dbMed;

%Makes a copy of sCLUSTER comprising only good clusters
inNClu      = sum(bl1GoodCluster);
sGOOD_CLU   = sCLUSTER(bl1GoodCluster);

%Computes a time vector and an index vector for waveforms
inTBIdx     = round(double(sPRM_KLUSTA.extract_s_before));
inTAIdx     = round(double(sPRM_KLUSTA.extract_s_after));
in1WavIdx   = -inTBIdx:inTAIdx;
db1WavTime  = 100*in1WavIdx./inSampleRate; %in miliseconds

%Initializes the missing fields of the output structure
sGOOD_CLU(inNClu).db1TStamps    = [];
sGOOD_CLU(inNClu).bl2Mask       = [];
sGOOD_CLU(inNClu).db2Waveform   = [];
sGOOD_CLU(inNClu).inRating      = [];
sGOOD_CLU(inNClu).chComment     = [];

%Loops through sCLUSTER in order to add spike time and waveform
for iClu = 1:length(sGOOD_CLU)
    %Extracts cluster number and communicate with user
    inCNum = sGOOD_CLU(iClu).inNumber;
    fprintf('Processing cluster %d ...\r', inCNum)
    
    %Extracts the time stamps of each spike
    in1CSpikTime = in1SpkTime(in1SpkClu == inCNum);
    sGOOD_CLU(iClu).db1TStamps = sINPUT_1.sL0MUATDF.db1TStamps(in1CSpikTime);
    
    %Extracts the channel masks stores as a (chan x spike) logical
    inFPerChan = sPRM_KLUSTA.n_features_per_channel; %Number of features per channels in klusta
    bl2Mask = logical(squeeze(db3FeaturesMask(2,1:inFPerChan:end - inFPerChan + 1 ,in1SpkClu == inCNum)));
    sGOOD_CLU(iClu).bl2Mask = bl2Mask;
    
    %Computes the wafeform of each spike when it is significantly on one
    %channel (spike x waveform). Spikes are ordered as chan1(spk1, spik2
    %...), chan2(spk1, spk2); Spikes are not included if they are not
    %present on one channel. Channel where there is no spikes are omited:
        
    %Extracts the appropriate channels to extracts the waveform
    in1Chan = find(logical(sum(bl2Mask, 2))); %Channels where spikes are present
    db2Waveform = []; %Initialize db2Waveform
    for iChn = 1:1:length(in1Chan) %loops through channels
        db1MUAChan  = db2MUA(in1Chan(iChn), :);
        in1Idx = double(in1CSpikTime(bl2Mask(in1Chan(iChn), :)'));
        bl1Rem = in1Idx <= -in1WavIdx(1) | in1Idx >= length(db1MUAChan) - in1WavIdx(end);
        in1Idx(bl1Rem) = []; %Removes indices that are too close to the edges of the trace
        in2Idx = repmat(in1Idx(:), 1, length(in1WavIdx)) + repmat(in1WavIdx, length(in1Idx), 1);
        db2Waveform = cat(1, db2Waveform, db1MUAChan(in2Idx));
    end
    sGOOD_CLU(iClu).db2Waveform = db2Waveform;
    
%     %Plots the waveform for verification
%     blIsPlot = false;
%     try
%         hFIG = PlotWaveform(sGOOD_CLU(iClu), db1WavTime);
%         blIsPlot = true;
%     end
    
    %Print a table for to summurize the metrics of the unit
    Cluster     = inCNum;
    NSpike      = [sGOOD_CLU(iClu).inNSpk]';
    IDist       = [sGOOD_CLU(iClu).dbIsolDist]';
    LRatio      = [sGOOD_CLU(iClu).dbLRatio]';
    pISI_2ms    = [sGOOD_CLU(iClu).dbISISub2ms]'*100;

    %Displays a table of the quality metrics in the command window
    disp(table(Cluster, NSpike, IDist, LRatio, pISI_2ms))
    
    %Ask the user for a rating and comments
    blPass = false;
    while ~blPass
        fprintf('How would you rate this unit on a scale of 1 to 5: ')
        inRating = input('');
        %             inRating = input('How would rate this unit and a scale of 1 to 5: ');
        if (any(inRating == 1:5))
            sGOOD_CLU(iClu).inRating = inRating;
            blPass = true;
        else
            fprintf('Rating is not a 1, 2, 3, 4 or 5. Would you like to go again (y/n)?:')
            inInp = input('', 's');
            %                 inInp = input('Rating is not 1,2,3,4 or 5. Would you like to go again (y/n)?: ', 's');
            if ~strcmp(inInp, 'y')
                blPass = true;
                sGOOD_CLU(iClu).inRating = NaN;
            end
        end
    end
    fprintf('Any comments on the unit ?:')
    sGOOD_CLU(iClu).chComment = input('', 's');
    %         sGOOD_CLU(iClu).chComment = input('Any comments on the unit ?: ', 's');
    
    %Closes the waveform plot if it exists
%     if blIsPlot & ishandle(hFIG)
%         close(hFIG)
%     end
end

sCFG.sINPUT.sL4MMDS.sPARAM          = sINPUT_1.sPARAM;
sCFG.sINPUT.sL4MMDS.chScriptName    = sINPUT_1.sL0MUATDF.chScriptName;
sCFG.sINPUT.sL4MMDS.chTimeComputed  = sINPUT_1.sL0MUATDF.chTimeComputed;

%Writes the output in CFG
sCFG.sL0MUATDF.db1WavTime       = db1WavTime;
sCFG.sL0MUATDF.sCLUSTER         = sGOOD_CLU;
sCFG.sL0MUATDF.sPRM_KLUSTA      = sPRM_KLUSTA;
sCFG.sL0MUATDF.chScriptName     = mfilename('fullpath');
sCFG.sL0MUATDF.chTimeComputed   = datestr(now);

%Ask the user permission to delete the MUA file which takes a lot a space
%and is relatively easy to recompute
fprintf('Would you like to delete MUA.dat to gain space (y/n)?: ');
chInp = input('', 's');
if strcmp(chInp, 'y')
    disp('Deleting MUA.dat')
    delete(chMUADatFile)
end

%Saves the output
fprintf('Saving clusters for %s ... ', chBaseName);
save(fullfile(chBaseDirectory, chBaseName, 'VEHA_L2_ClusterCut_GUI.mat'), 'sCFG', '-v7.3');

fprintf('Done! \r')


%Core routine ------------------------------------------------------------
%Loads the data, computes the metrics and initializes the output structure
function ComputeMetrics()
%Computes global
global hQ_TABLE
global chKwikFile chKwxFile chBaseName
global sPRM_KLUSTA sCLUSTER bl1GoodCluster in1SpkTime in1SpkClu db3FeaturesMask

%Load spike time, cluster and feature mask
in1SpkTime      = h5read(chKwikFile, '/channel_groups/0/spikes/time_samples');
in1SpkClu       = h5read(chKwikFile, '/channel_groups/0/spikes/clusters/main');
db3FeaturesMask = h5read(chKwxFile, '/channel_groups/0/features_masks');

%Loads the attributes of kwik file into a structure
sF_INFO = h5info(chKwikFile);

%Extracts the parameter of klusta and stores them on on a structure
sPRM_RAW    = sF_INFO.Groups(1).Groups(2).Attributes(:);
sPRM_KLUSTA = struct();
for iPrm = 1:length(sPRM_RAW)
    eval(sprintf('sPRM_KLUSTA.%s = sPRM_RAW(%d).Value;', sPRM_RAW(iPrm).Name, iPrm));
end
inSampleRate = double(sPRM_KLUSTA.sample_rate);

%Extracts the cluster groups (i.e.: Good, MUA or Noise ; Main in the .kwik
%format refers to the clustering that is the most up to date)
sMAIN       = sF_INFO.Groups(2).Groups.Groups(3).Groups(1).Groups;
in1CNumMain     = nan(length(sMAIN), 1);
in1CGroupMain   = nan(length(sMAIN), 1); %0 = Noise; 1 = MUA; 2 = Good; 
for iClu = 1:length(sMAIN)
    in1CNumMain(iClu)   = str2double(regexprep(sMAIN(iClu).Name, '/.*/.*/.*/.*/', ''));
    in1CGroupMain(iClu) = sMAIN(iClu).Attributes.Value;
end

%Matches clustergroup in in1CGroupMain with those in in1SpkClu
in1CNum     = unique(in1SpkClu);
in1CGroup    = nan(size(in1CNum));
for iClu = 1:length(in1CNum)
    in1CGroup(iClu) = in1CGroupMain(in1CNumMain == in1CNum(iClu));
end
bl1GoodCluster = in1CGroup == 2;

%Intializes the output structure
inNClu = length(in1CNum);
sCLUSTER = struct();
sCLUSTER(inNClu).inNumber       = [];
sCLUSTER(inNClu).chGroup        = [];
sCLUSTER(inNClu).inNSpk         = [];
sCLUSTER(inNClu).dbIsolDist     = [];
sCLUSTER(inNClu).dbLRatio       = [];
sCLUSTER(inNClu).dbISISub2ms    = [];

for iClu = 1:inNClu
    %Stores the cluster number
    sCLUSTER(iClu).inNumber = in1CNum(iClu);
    sCLUSTER(iClu).chGroup = char(categorical(in1CGroup(iClu), 0:3, {'Noise', 'MUA', 'Good', 'NC'}));
    
    %Computes the isolation distance and the L-Ratio as a fonction of the
    %features coordinates of each cluster
    db3CFM = db3FeaturesMask(:,:,in1SpkClu == in1CNum(iClu)); %Features and maks of the cluster
    db3NFM = db3FeaturesMask(:,:,in1SpkClu ~= in1CNum(iClu)); %Features and maks of the noise (all the other spikes)
    
    %Computes the number of spike
    inNSpk      = size(db3CFM, 3);
    sCLUSTER(iClu).inNSpk = inNSpk;
    %Gets the features associated with a channel where more than 95% of spike were detected
    in1Mask = mean(db3CFM(2,:,:), 3) > 0.95;
    if all(~in1Mask) || inNSpk < 2
        sCLUSTER(iClu).dbIsolDist  = NaN;
        sCLUSTER(iClu).dbLRatio    = NaN;
    else
        db2CFeat    = permute(db3CFM(1, in1Mask, :), [3 2 1]); %Feature coordinates of the cluster
        db2CCov     = nancov(db2CFeat); %Covariance matrix of the cluster
        db1CMu      = mean(db2CFeat); %Centroid of the cluster
        
        db2NFeat    = permute(db3NFM(1, in1Mask, :), [3 2 1]); %Feature coordinates of the noise
        db2NFeatCnt = db2NFeat - repmat(db1CMu, size(db2NFeat,1), 1); %Centered coordintates
        db1NDist    = sum(db2NFeatCnt/db2CCov.*db2NFeatCnt, 2); %Squared Mahalonobis distances 
        db1NDSort   = sort(db1NDist);
        
        if inNSpk < length(db1NDist) %Isolation distance is not defined if there is less spike in the noise than in the cluster
            sCLUSTER(iClu).dbIsolDist  = db1NDSort(inNSpk);
        else
            sCLUSTER(iClu).dbIsolDist  = NaN;
        end
        sCLUSTER(iClu).dbLRatio    = sum(1 - chi2cdf(db1NDSort, sum(in1Mask)))/inNSpk;
    end
    %Computes the refractory violation
    if size(db3CFM, 3) < 2
        sCLUSTER(iClu).dbISISub2ms = NaN; 
    else
        in1CSpkTime = in1SpkTime(in1SpkClu == in1CNum(iClu));
        dbISI       = double(diff(in1CSpkTime))/inSampleRate;
        sCLUSTER(iClu).dbISISub2ms = sum(dbISI < 0.002)/length(dbISI);
    end
end

%Create quality metrics vectors 
Cluster     = in1CNum;
Group       = categorical(in1CGroup, 0:3, {'Noise', 'MUA', 'Good', 'NC'});
NSpike      = [sCLUSTER(:).inNSpk]';
IDist       = [sCLUSTER(:).dbIsolDist]';
LRatio      = [sCLUSTER(:).dbLRatio]'; 
pISI_2ms    = [sCLUSTER(:).dbISISub2ms]'*100;

%Displays a table of the quality metrics in the command window
disp(chBaseName)
disp(table(Cluster, Group, NSpike, IDist, LRatio, pISI_2ms))

%Formats the data so that it can be padded to the table
cQM = [num2cell(Cluster), cellstr(Group), num2cell(NSpike), ...
    num2cell(IDist), num2cell(LRatio), num2cell(pISI_2ms)];

%Loads the data in the table
set(hQ_TABLE, 'Data', cQM, 'RowName', {})

function hFIG = PlotWaveform(sINPUT, db1WavTime)
%Little utility to plot waveform. Not super usefull here but will serve as
%a sketch for a function used in data processing

bl2Mask     = sINPUT.bl2Mask;
db2Waveform = sINPUT.db2Waveform;

in1Chan = find(logical(sum(bl2Mask, 2)));
in1SpkCS = [0; cumsum(sum(bl2Mask(in1Chan,:), 2))]; %Cumulative sum of the number of spike on each channel

db1YL = [0 0];
hFIG = figure;
for iPlt = 1:length(in1Chan)
    axC(iPlt) = subplot(1, length(in1Chan), iPlt);
    plot(db1WavTime, db2Waveform(in1SpkCS(iPlt) + 1: in1SpkCS(iPlt + 1), :)', ...
        'Color', [0.2 0.5 0.8])
    title(sprintf('Chan %d', in1Chan(iPlt)))
    xlabel('ms')
    db1YLP = ylim;
    if db1YLP(1) < db1YL(1), db1YL(1) = db1YLP(1); end
    if db1YLP(2) > db1YL(2), db1YL(2) = db1YLP(2); end
    if iPlt == 1
        ylabel('mV')
    else
        set(axC(iPlt), 'YTickLabel', [])
    end
end
linkaxes(axC), ylim(db1YL); xlim([db1WavTime(1) db1WavTime(end)])
