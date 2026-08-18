function VEHA_L3_LayerMapping_GUI()
%GUI used to map layer on the multicontact laminar silicon probe recordings
%using CSD analysis. The multiunit is used to make an intial guess.

%Intialization of variables -----------------------------------------------
global hCSD_PLOT hMUA_PLOT 
global hPROTOCOL_POPUP hCOMP_CSD_BUTTON hPLACE_L4_BUTTON hREM_L4_BUTTON 
global hPLACE_L5B_BUTTON hREM_L5B_BUTTON hIMPORT_BUTTON hRATING_POPUP hSAVE_BUTTON
global blPlaceL4 blPlaceL5B
global inNInterp db1ETAWindowSec 
global in1LayerDepth inMUAPeakDepth inL4Depth inL5BDepth
global chInputDir_0 chInputDir_1 chInputDir_2 chInputDir_3 chOutputDir chSessionName
global chL1DPSFile chL2PSFile chL0LFPFile chL0MUAFile chOutputFile

%Initialization of file management variables
chBaseDirectory = 'E:\Ephy\VisExpHighAll';
chInputDir_0    = fullfile(chBaseDirectory, 'VEHA_L1_DetectPresentationSet');
chL1DPSFile      = 'VEHA_L1_DetectPresentationSet.mat';
chInputDir_1    = fullfile(chBaseDirectory, 'VEHA_L2_MatchStimLogWithPresentationSet'); %Input directory for the presentation set
chL2PSFile      = 'VEHA_L2_MatchStimLogWithPresentationSet.mat';
chInputDir_2    = fullfile(chBaseDirectory, 'VEHA_L0_PreProcessLFP'); %Input directory for the LFP
chL0LFPFile     = 'VEHA_L0_PreProcessLFP.mat';
chInputDir_3    = fullfile(chBaseDirectory, 'VEHA_L0_PreProcessMUA'); %Input directory for the MUA
chL0MUAFile     = 'VEHA_L0_PreProcessMUA.mat';
chOutputDir     = fullfile(chBaseDirectory, 'VEHA_L3_LayerMapping'); %Output directory
chOutputFile    = 'VEHA_L3_LayerMapping.mat';
chSessionName   = [];

%Initialization of display variables
inNInterp = 20;
db1ETAWindowSec = [-.05 .25];
in1LayerDepth = [68; 306; 442; 714]; %if total depth = 1020
% in1LayerDepth = [70; 315; 455; 735]; %if total depth = 1050

%Initialization of depht landmark
inMUAPeakDepth = in1LayerDepth(3) + round(diff(in1LayerDepth(3:4))*0.3);
inL4Depth      = in1LayerDepth(2) + round(diff(in1LayerDepth(2:3))*0.5);
inL5BDepth     = in1LayerDepth(3) + round(diff(in1LayerDepth(3:4))*0.8);

%Intialization of button switch variables
blPlaceL4       = false;
blPlaceL5B      = false;

%Initialization of the figure and buttons ---------------------------------
hLM_GUI = figure('Visible', 'on', 'Position', [100, 100, 1600, 900], ...
    'WindowButtonDownFcn', {@ButtonDownCallback});

hMUA_PLOT   = axes('Parent', hLM_GUI, 'Units', 'normalized', 'Position', [0.03, 0.13, 0.31, 0.84]);

hCSD_PLOT   = axes('Parent', hLM_GUI, 'Units', 'normalized', 'Position', [0.37, 0.13, 0.60, 0.84]);

hOPEN_REC_BUTTON    = uicontrol('Parent', hLM_GUI, 'Style', 'pushbutton', 'String', ...
    'Open Recording', 'Units', 'normalized', 'Position', [0.03,0.03,0.08,0.06], 'BackgroundColor', [0.6 0.2 0.2], ...
    'Callback',{@OpenRecButtonCallback});

hOPEN_NEXT_BUTTON   = uicontrol('Parent', hLM_GUI, 'Style', 'pushbutton', 'String', ...
    'Open Next', 'Units', 'normalized', 'Position', [0.12,0.03,0.05,0.06], 'BackgroundColor', [0.6 0.3 0.1], ...
    'Callback',{@OpenNextButtonCallback});

hPROTOCOL_TEXT      = uicontrol('Parent', hLM_GUI, 'Style', 'text',...
    'Units', 'normalized', 'Position', [0.20,0.05,0.08,0.03], ...
    'String', 'Choose Protocol', 'BackgroundColor', [0.8 0.8 0.8]);

hPROTOCOL_POPUP     = uicontrol('Parent', hLM_GUI, 'Style', 'popupmenu',...
    'Units', 'normalized', 'Position', [0.20,0.03,0.08,0.03], ...
    'String', {''}, 'Enable', 'off');

hCOMP_CSD_BUTTON    = uicontrol('Parent', hLM_GUI, 'Style', 'pushbutton', 'String', ...
    'Compute CSD', 'Units', 'normalized', 'Position', [0.29,0.03,0.08,0.06], 'BackgroundColor', [0.6 0.6 0], ...
    'Enable', 'off', 'Callback',{@CompCSDButtonCallback});

hPLACE_L4_BUTTON    = uicontrol('Parent', hLM_GUI, 'Style', 'pushbutton', 'String', ...
    'Place L4', 'Units', 'normalized', 'Position', [0.41,0.03,0.07,0.06], 'BackgroundColor', [0.1 0.6 0.3], ...
    'Enable', 'off', 'Callback',{@PlaceL4Callback});

hREM_L4_BUTTON      = uicontrol('Parent', hLM_GUI, 'Style', 'pushbutton', 'String', ...
    'Remove L4', 'Units', 'normalized', 'Position', [0.49,0.03,0.05,0.06], 'BackgroundColor', [0.2 0.6 0.2], ...
    'Enable', 'off', 'Callback',{@RemL4Callback});

hPLACE_L5B_BUTTON    = uicontrol('Parent', hLM_GUI, 'Style', 'pushbutton', 'String', ...
    'Place L5B', 'Units', 'normalized', 'Position', [0.55,0.03,0.07,0.06], 'BackgroundColor', [0.1 0.3 0.6], ...
    'Enable', 'off', 'Callback',{@PlaceL5BCallback});

hREM_L5B_BUTTON     = uicontrol('Parent', hLM_GUI, 'Style', 'pushbutton', 'String', ...
    'Remove L5B', 'Units', 'normalized', 'Position', [0.63,0.03,0.05,0.06], 'BackgroundColor', [0.2 0.2 0.6], ...
    'Enable', 'off', 'Callback',{@RemL5BCallback});

hIMPORT_BUTTON     = uicontrol('Parent', hLM_GUI, 'Style', 'pushbutton', 'String', ...
    'Import Layers', 'Units', 'normalized', 'Position', [0.69,0.03,0.07,0.06], 'BackgroundColor', [0.6 0 0.3], ...
    'Enable', 'off', 'Callback',{@ImportCallback});

hRATING_TEXT      = uicontrol('Parent', hLM_GUI, 'Style', 'text',...
    'Units', 'normalized', 'Position', [0.80,0.05,0.08,0.03], ...
    'String', 'Rate Depth Estimate', 'BackgroundColor', [0.8 0.8 0.8]);

hRATING_POPUP     = uicontrol('Parent', hLM_GUI, 'Style', 'popupmenu',...
    'Units', 'normalized', 'Position', [0.80,0.03,0.08,0.03], ...
    'String', {'Good' 'Average' 'Bad'}, 'Enable', 'off');

hSAVE_BUTTON        = uicontrol('Parent', hLM_GUI, 'Style', 'pushbutton', 'String', ...
    'Save', 'Units', 'normalized', 'Position', [0.89,0.03,0.08,0.06], 'BackgroundColor', [0.6 0.1 0.3], ...
    'Enable', 'off', 'Callback',{@SaveButtonCallback});

%Callbacks ----------------------------------------------------------------

function ButtonDownCallback(source, eventdata)
%This function allows the user to set the location of the CSD sinks in
%layer 4 or layer 5B by clicking on the CSD plot. Which is placed depends
%on wether the buttons hPLACE_L4 or hPLACE_L5B is pushed on
global hCSD_PLOT
global blPlaceL4 blPlaceL5B
global db1L4SinkLoc db1L5BSinkLoc
global dbL4Chan dbL5BChan

if blPlaceL4 || blPlaceL5B %Only does something if hPLACE_L4 or hPLACE_L5B is pushed on
    db2MouseDownXYZ = get(hCSD_PLOT, 'CurrentPoint');
    dbMDX = db2MouseDownXYZ(1,1); dbMDY = db2MouseDownXYZ(1,2);
    db1XL = get(hCSD_PLOT, 'XLim'); db1YL = get(hCSD_PLOT, 'YLim');
    if dbMDX >= db1XL(1) && dbMDY >= db1YL(1) && dbMDX <= db1XL(2) && dbMDY <= db1YL(2)
        if blPlaceL4
            db1L4SinkLoc    = [dbMDX dbMDY];
            dbL4Chan        = dbMDY;
        elseif blPlaceL5B
            db1L5BSinkLoc   = [dbMDX dbMDY];
            dbL5BChan       = dbMDY;
        end
    end
    SetChannelDepth()
    PlotMUA()
    PlotCSD()
end

function OpenRecButtonCallback(source, eventdata)
global chInputDir_2 chSessionName

%Selects the folder
[chInputName] = uigetdir(chInputDir_2, 'Choose session directory:');
[chDirPath, chFileName] = fileparts(chInputName);

%Checks that the selected directory is inside the base directory
if ~strcmp(chInputDir_2, chDirPath)
    error('The directory should be in %s', chInputDir_2)
end

chSessionName = chFileName;

OpenRecording()


function OpenNextButtonCallback(source, eventdata)
global chInputDir_2 chSessionName

if isempty(chSessionName)
    disp('Select a session first before opening the next one')
else
    
    %List the files in the main input directory and only keeps the folders
    sDIR = dir(chInputDir_2);
    bl1IsDir = [sDIR(:).isdir];
    sDIR = sDIR(bl1IsDir);
    
    %Checks what the next folder exist and sets session name to it
    cNAME = {sDIR(:).name};
    inSessionIdx = find(strcmp(cNAME, chSessionName));
    if inSessionIdx < length(cNAME)
        chSessionName = sDIR(inSessionIdx + 1).name;
    end
    
    %Opens the recording
    OpenRecording()
end

function CompCSDButtonCallback(source, eventdata)
ComputeCSD();

function PlaceL4Callback(source, eventdata)
global blPlaceL4 blPlaceL5B hPLACE_L5B_BUTTON

if blPlaceL4
    blPlaceL4   = false; %Disable placing L4
    set(source, 'BackgroundColor', [0.1 0.6 0.3]);
else
    blPlaceL4   = true; %Enables placing L4
    set(source, 'BackgroundColor', [0.15 0.9 0.45]);
    blPlaceL5B  = false; %Disable placing L5B
    set(hPLACE_L5B_BUTTON, 'BackgroundColor', [0.1 0.3 0.6]);
end

function RemL4Callback(source, enventdata)
%Clears the sink in L4 and replots
global db1L4SinkLoc dbL4Chan

db1L4SinkLoc = [];
dbL4Chan = [];
SetChannelDepth()
PlotMUA()
PlotCSD()

function PlaceL5BCallback(source, eventdata)
global blPlaceL5B blPlaceL4 hPLACE_L4_BUTTON

if blPlaceL5B
    blPlaceL5B  = false; %Disable placing L5B
    set(source, 'BackgroundColor', [0.1 0.3 0.6]);
else
    blPlaceL5B  = true; %Enables placing L5B
    set(source, 'BackgroundColor', [0.15 0.45 0.9]);
    blPlaceL4   = false; %Disable placing L4
    set(hPLACE_L4_BUTTON, 'BackgroundColor', [0.1 0.6 0.3]);
end

function RemL5BCallback(source, enventdata)
global db1L5BSinkLoc dbL5BChan

db1L5BSinkLoc = [];
dbL5BChan = [];
SetChannelDepth()
PlotMUA()
PlotCSD()

function ImportCallback(source, eventdata)
%This routine allows to import an already estimated layer estimate from
%another existing session. This is usefull when sessions have been acquired
%from the same animal.
global chOutputDir chOutputFile
global in1LayerDepth
global dbL4Chan dbL5BChan db1L4SinkLoc db1L5BSinkLoc
 
%Selects the folder t
[chImpSessionName] = uigetdir(chOutputDir, 'Choose session directory:');
[chDirPath, chImpSessionName] = fileparts(chImpSessionName);

%Checks that the selected directory is inside the base directory
if ~strcmp(chOutputDir, chDirPath)
    error('The directory should be in %s', chOutputDir)
end

%Selects the session to import from
sIMPORT = load(fullfile(chOutputDir, chImpSessionName, chOutputFile), '-mat'); sIMPORT = sIMPORT.sCFG;
if ~all(in1LayerDepth == sIMPORT.sPARAM.in1LayerDepth)
    error('Layers have a different format in the selected import file');
else
    fprintf('Importing layer estimate from %s\r', chImpSessionName)
end

%Get former estimates of layer positons
dbL4Chan         = sIMPORT.sL3LM.dbL4Chan;
dbL5BChan        = sIMPORT.sL3LM.dbL5BChan;
db1L4SinkLoc     = sIMPORT.sL3LM.db1L4SinkLoc;
db1L5BSinkLoc    = sIMPORT.sL3LM.db1L5BSinkLoc;

%Computes depth estimate and replots everything
SetChannelDepth()
PlotMUA()
PlotCSD()
   

function SaveButtonCallback(source, eventdata)
%Savest the channel depth estimate in the output structure
global hPROTOCOL_POPUP hRATING_POPUP
global chOutputDir chSessionName chOutputFile 
global sCFG sLFP
global inNInterp db1ETAWindowSec in1LayerDepth inMUAPeakDepth inL4Depth inL5BDepth
global dbMUAPeakChan dbL4Chan dbL5BChan db1LayerChan db1ChannelDepth
global db1L4SinkLoc db1L5BSinkLoc

%Communicate with user
fprintf('Saving %s for session %s ... ', chOutputFile, chSessionName) 

%Sets the output folder
if ~isdir(chOutputDir)
    mkdir(chOutputDir)
end
if ~isdir(fullfile(chOutputDir, chSessionName)) 
    mkdir(chOutputDir, chSessionName);
end

%Createst the output structure
sCFG.sPARAM = struct();
sCFG.sL3LM  = struct();

%Stores the parameters 
sCFG.sPARAM.inNInterp       = inNInterp;
sCFG.sPARAM.db1ETAWindowSec = db1ETAWindowSec;
sCFG.sPARAM.in1LayerDepth   = in1LayerDepth; %if total depth = 1050
sCFG.sPARAM.inMUAPeakDepth  = inMUAPeakDepth;
sCFG.sPARAM.inL4Depth       = inL4Depth;
sCFG.sPARAM.inL5BDepth      = inL5BDepth;

%Gets the value of the protocol that was used for the CSD
iProt           = get(hPROTOCOL_POPUP, 'Value');
cGRAT_PROTOC    = get(hPROTOCOL_POPUP, 'String');

%Gets the value of the rating
iRat            = get(hRATING_POPUP, 'Value');
cRATING         = get(hRATING_POPUP, 'String');

%Writes the output in CFG 
sCFG.sL3LM.chGratProtocol           = cGRAT_PROTOC{iProt};
sCFG.sL3LM.chEstimateRating         = cRATING{iRat};
sCFG.sL3LM.dbLFPChanSpacingMicron   = sLFP.dbLFPChanSpacingMicron;
sCFG.sL3LM.dbMUAPeakChan            = dbMUAPeakChan;
sCFG.sL3LM.dbL4Chan                 = dbL4Chan;
sCFG.sL3LM.dbL5BChan                = dbL5BChan;
sCFG.sL3LM.db1L4SinkLoc             = db1L4SinkLoc;
sCFG.sL3LM.db1L5BSinkLoc            = db1L5BSinkLoc;
sCFG.sL3LM.db1LayerChan             = db1LayerChan;
sCFG.sL3LM.db1ChannelDepth          = db1ChannelDepth;
sCFG.sL3LM.chScriptName             = mfilename('fullpath');
sCFG.sL3LM.chTimeComputed           = datestr(now);

%Saves the output parameter structure
save(fullfile(chOutputDir, chSessionName, chOutputFile), 'sCFG', '-v7.3');

%Communicates with user
fprintf('Done\r')

%Core routines ------------------------------------------------------------

function OpenRecording()
global hCSD_PLOT hMUA_PLOT
global hPROTOCOL_POPUP hPLACE_L4_BUTTON hPLACE_L5B_BUTTON hRATING_POPUP
global blPlaceL4 blPlaceL5B 
global chInputDir_0 chInputDir_1 chInputDir_2 chInputDir_3 chL1DPSFile chL2PSFile chL0LFPFile chL0MUAFile
global chSessionName chOutputDir chOutputFile
global sCFG
global sGRATING sLFP in1MUASum in1GProtocol db1PresOnTStamp_All
global db1L4SinkLoc db1L5BSinkLoc dbL4Chan dbL5BChan
global dbMUAPeakChan
global in1LayerDepth

try
    %Communicates with user
    fprintf('Loading data for session %s ... \r', chSessionName)
    
    %Checks for the existence of input files
    if ~exist(fullfile(chInputDir_0, chSessionName, chL1DPSFile), 'file')
        error('%s does not exist for session %s. Choose another directory\n', chL1DPSFile, chSessionName);
    elseif ~exist(fullfile(chInputDir_2, chSessionName, chL0LFPFile), 'file')
        error('%s does not exist for session %s. Choose another directory\n', chL0LFPFile, chSessionName);
    elseif ~exist(fullfile(chInputDir_3, chSessionName, chL0MUAFile), 'file')
        error('%s does not exist for session %s\n', chL0MUAFile, chSessionName);
    end
    if ~exist(fullfile(chInputDir_1, chSessionName, chL2PSFile), 'file')
        blGrating = false;
        fprintf('%s does not exist for session %s. There will be no grating stimuli.\n', chL2PSFile, chSessionName);
    else
        blGrating = true;
    end
    
    %Loads presentations onset of all stimulus regardless of their type
    %(this will also include grating presented during the behavioral task)
    sINPUT_0 = load(fullfile(chInputDir_0, chSessionName, chL1DPSFile), '-mat'); sINPUT_0 = sINPUT_0.sCFG;
    if ~isfield(sINPUT_0.sL1DP, 'db1PresOnTStamp')
        fprintf('No presentations in %s for session %s\r', chL1DPSFile, chSessionName)
        db1PresOnTStamp_All = [];
        blPres = false;
    elseif isempty(sINPUT_0.sL1DP.db1PresOnTStamp)
        fprintf('No presentations in %s for session %s\r', chL1DPSFile, chSessionName)
        db1PresOnTStamp_All = [];
        blPres = false;
    else
        db1PresOnTStamp_All = sINPUT_0.sL1DP.db1PresOnTStamp;
        blPres = true;
    end
    
    %Loads logs of stimulation sets
    if blGrating
        sINPUT_1 = load(fullfile(chInputDir_1, chSessionName, chL2PSFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
        if ~isfield(sINPUT_1.sL2MSLPS.sSTIMLOG, 'sGRATING')
            blGrating = false;
            fprintf('No grating stimulus in %s for session %s\r', chL2PSFile, chSessionName)
        else
            sGRAT = sINPUT_1.sL2MSLPS.sSTIMLOG.sGRATING; %Set a shortcut for sGRATING that is convenient to work with
        end
    end
    
    %Checks for the number of grating protocols
    if blGrating
        cGRAT_PROTOC = cell(1, length(sGRAT));
        for iPres = 1:length(sGRAT)
            cGRAT_PROTOC{iPres} = VEHA_U_GetGratingSetType(sGRAT(iPres).sPARAM);
        end
        %Issues an error if there is no grating type (which indicates an error
        %in preprocessing)
        if length(unique(cGRAT_PROTOC)) < 1
            blGrating = false;
            fprintf('No recognized grating protocol in %s for session %s', chL2PSPFile, chSessionName)
        end
    end
        
    %Loads LFP (and MUA) and calculates MUA activity per channel to make an
    %initial guess for channel depth (MUA activity peaks in the most
    %superficial parts of layer 5)
    sINPUT_2 = load(fullfile(chInputDir_2, chSessionName, chL0LFPFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;
    sINPUT_3 = load(fullfile(chInputDir_3, chSessionName, chL0MUAFile), '-mat'); sINPUT_3 = sINPUT_3.sCFG;
    
    %Computes global variable
    if blGrating
        [cGRAT_PROTOC, ~, in1GProtocol] = unique(cGRAT_PROTOC); %Cell array of all the different grating protocols in the recording
        cGRAT_PROTOC = cat(2, cGRAT_PROTOC, 'All'); %Add the option of 
        sGRATING = sGRAT;
    elseif blPres
        in1GProtocol = [];
        cGRAT_PROTOC = {'All'};
        sGRATING = struct();
    else
        in1GProtocol = [];
        cGRAT_PROTOC = {'VirtualCSD'};
        sGRATING = struct();
    end
    
    sLFP = sINPUT_2.sL0PPLFP;
    sLFP.inSampleRate = sINPUT_2.sPARAM.inOutputSampleRate;
    in1MUASum = cellfun(@length, sINPUT_3.sL0PPMUA.cMUATStamps)';
    [~, dbMUAPeakChan] = max(in1MUASum);
    
    
    %Checks if the output variables exist if it has been computed with the
    %same parameters as the current parameters
    blReload = false;
    if exist(fullfile(chOutputDir, chSessionName, chOutputFile), 'file')
        sCFG = load(fullfile(chOutputDir, chSessionName, chOutputFile), '-mat'); sCFG = sCFG.sCFG;
        if all(in1LayerDepth == sCFG.sPARAM.in1LayerDepth)
            blReload = true;
        end
    end
    
    %Resets GUI variables, plots and output variables
    set(hPROTOCOL_POPUP, 'String', cGRAT_PROTOC, 'Value', length(cGRAT_PROTOC));
    blPlaceL4   = false; %Disable placing L4
    set(hPLACE_L4_BUTTON, 'BackgroundColor', [0.1 0.6 0.3]);
    blPlaceL5B   = false; %Disable placing L4
    set(hPLACE_L5B_BUTTON, 'BackgroundColor', [0.1 0.3 0.6]);
    cla(hCSD_PLOT); cla(hMUA_PLOT);
    [db1L4SinkLoc, db1L5BSinkLoc, dbL4Chan, dbL5BChan] = deal([]);
    
    %If a valid output already exists reloads the previous depth estimate
    %and resets the GUI in its former state
    if blReload
        %Communicate with user
        fprintf('Reloading %s for %s \r', chOutputFile, chSessionName) 
        
        %Get former estimates of layer positons
        dbL4Chan         = sCFG.sL3LM.dbL4Chan;
        dbL5BChan        = sCFG.sL3LM.dbL5BChan;
        db1L4SinkLoc     = sCFG.sL3LM.db1L4SinkLoc;
        db1L5BSinkLoc    = sCFG.sL3LM.db1L5BSinkLoc;
        
        %Gets the former spacing
        sLFP.dbLFPChanSpacingMicron = sCFG.sL3LM.dbLFPChanSpacingMicron;
        
        %Reset hPROTOCOL_POPUP and hRATING_POPUP in there former state 
        inGProtIdx = find(strcmp(sCFG.sL3LM.chGratProtocol, cGRAT_PROTOC));
        set(hPROTOCOL_POPUP, 'Value', inGProtIdx);
        inRatIdx = find(strcmp(sCFG.sL3LM.chEstimateRating, get(hRATING_POPUP, 'String')));
        set(hRATING_POPUP, 'Value', inRatIdx); 
    
    else %If no, sets the GUI so that a first estimate of depth can be made
        
        %Gets the spacing of the probe in microns or asks the user to define it
        if isfield(sINPUT_2.sREC, 'dbLFPChanSpacingMicron')
            sLFP.dbLFPChanSpacingMicron = sINPUT_2.sREC.dbLFPChanSpacingMicron;
        else
            blValid = false;
            while ~blValid
                inSpacing = input('What is the spacing of contact points on thcGRAT_PROTOCe probe in microns?: ');
                if isempty(inSpacing)
                    disp('The spacing cannot be empty')
                elseif inSpacing <= 0
                    disp('The spacing cannot be zero, negative')
                else
                    fprintf('Spacing set to: %.1f microns. ' , inSpacing)
                    chInp = input('Do you want to continue ? (y/n): ', 's');
                    if strcmp(chInp, 'y')
                        blValid = true;
                    end
                end
            end
            sLFP.dbLFPChanSpacingMicron = inSpacing;
        end
        
        %Creates the output structure
        sCFG = struct();
    end
    
    %keeps track of the input
    sCFG.sINPUT.sL1DP.sPARAM = sINPUT_0.sPARAM;
    sCFG.sINPUT.sL1DP.chScriptName = sINPUT_0.sL1DP.chScriptName;
    sCFG.sINPUT.sL1DP.chTimeComputed = sINPUT_0.sL1DP.chTimeComputed;
    if blGrating
        sCFG.sINPUT.sL2MSLPS.sPARAM = sINPUT_1.sPARAM;
        sCFG.sINPUT.sL2MSLPS.chScriptName = sINPUT_1.sL2MSLPS.chScriptName;
        sCFG.sINPUT.sL2MSLPS.chTimeComputed = sINPUT_1.sL2MSLPS.chTimeComputed;
    end
    sCFG.sINPUT.sL0PPLFP.sPARAM = sINPUT_2.sPARAM;
    sCFG.sINPUT.sL0PPLFP.chScriptName = sINPUT_2.sL0PPLFP.chScriptName;
    sCFG.sINPUT.sL0PPLFP.chTimeComputed = sINPUT_2.sL0PPLFP.chTimeComputed;
    sCFG.sINPUT.sL0PPMUA.sPARAM = sINPUT_3.sPARAM;
    sCFG.sINPUT.sL0PPMUA.chScriptName = sINPUT_3.sL0PPMUA.chScriptName;
    sCFG.sINPUT.sL0PPMUA.chTimeComputed = sINPUT_3.sL0PPMUA.chTimeComputed;
    
    %Plots the MUA
    SetChannelDepth()
    PlotMUA()
    
    %Recomputes the CSD as estimated previously if a previously
    %available estimate has been computed
    ComputeCSD()
    
    fprintf('Done\r')
catch ME
    %Displays error message
    disp(getReport(ME))
end

function ComputeCSD()
global hPROTOCOL_POPUP
global sGRATING sLFP in1GProtocol db1PresOnTStamp_All
global inNInterp db1ETAWindowSec db2CSD_ETA db1ETATime

%Communicates with user
fprintf('Computing CSD ...')

%Gets the value of the protocol popup
inGProtocol = get(hPROTOCOL_POPUP, 'Value');

%Determines if a particular grating presentation protocol should be used or
%if all the onset of any visual presentation should be used instead
if inGProtocol <= max(in1GProtocol) %if a grating is selected
    %Selects the Stimulation Sets corresponding to the chosen protocol into a
    %working variable sGRAT
    sGRAT = sGRATING(in1GProtocol == inGProtocol);
    
    %Collects the time stamps of stimulus onset
    db1PresOnTS = [];
    for iPres = 1:length(sGRAT)
        db1PresOnTS = cat(2, db1PresOnTS, sGRAT(iPres).db1PresOnTStamp);
    end
    %Converts the time stamps into indices of the LFP trace
    in1PresOnIdx = NS_GetTStampEventIndex(sLFP.db1TStamps, db1PresOnTS);
else
    in1PresOnIdx = NS_GetTStampEventIndex(sLFP.db1TStamps, db1PresOnTStamp_All);
end

%Computes Event Triggered Averages (ETA) of the LFP around stimulus onset
in1ETABnd   = round(db1ETAWindowSec*sLFP.inSampleRate); %bounds of the event triggered average of the LFP
in1ETAIdx   = in1ETABnd(1):in1ETABnd(2); %indices of the Event Triggered Average of the LFP around presentation onset

%Defines filters
[B1, A1] = butter(2, 2*[2 100]/sLFP.inSampleRate); %Low pass for regular CSD
%Filters the LFP (or not)
db2LFP = filtfilt(B1, A1, sLFP.db2LFP')';

%Checks that the presentation set is not empty
if ~isempty(in1PresOnIdx)    
    in3ETAIdx   = repmat(in1ETAIdx, 1, 1, length(in1PresOnIdx)) + repmat(permute(in1PresOnIdx, [3 1 2]), 1, length(in1ETAIdx), 1); %3D indices
    %Gathers the data and aligns to the onset of presentation
    db3LFP_ETA = zeros(16, length(in1ETAIdx), length(in1PresOnIdx));
    for iChan = 1:16
        db1LFPTrace  = db2LFP(iChan, :);
        db3LFP_ETA(iChan,:,:)  = db1LFPTrace(in3ETAIdx);
    end
    
    %Does a spactial convolution of the average
    inSpacing = sLFP.dbLFPChanSpacingMicron;
    switch inSpacing %The number of points to include in the convolution depends on the spacing of contact points on silicon probes
        case 50
            inNConv = 4;
        case 75
            inNConv = 3;
    end
    db2AvLFP_ETA = mean(db3LFP_ETA, 3);
    db2AvLFP_ETA = [repmat(db2AvLFP_ETA(1,:), ceil(inNConv/2), 1) ;...
        db2AvLFP_ETA ;...
        repmat(db2AvLFP_ETA(end,:), ceil(inNConv/2), 1)]; %Pads the signal before convolution to avoid artifact caused by zero padding
    db2CSD_ETA = - diff(conv2(db2AvLFP_ETA, gausswin(inNConv), 'same')./sum(gausswin(inNConv)), 2);
    db2CSD_ETA = db2CSD_ETA(ceil(inNConv/2) + 1:end - ceil(inNConv/2), :);
    
    %Interpolate between the points
    db1Idx = 1:14;
    db1IdxIntrp = 1:1/inNInterp:14;
    db2CSD_ETA = interp1(db1Idx, db2CSD_ETA, db1IdxIntrp, 'pchip');
    db1ETATime = in1ETAIdx/sLFP.inSampleRate;
else
    db1IdxIntrp = 1:1/inNInterp:14;
    db1ETATime = in1ETAIdx/sLFP.inSampleRate;
    db2CSD_ETA = nan(length(db1IdxIntrp), length(db1ETATime));
end


%Plots the CSD
PlotCSD()

%Update button status
EnableButtons([1 1 1 1 1 1 1 1 1])

%Communicates with angry user
fprintf(' Done!\r')

function EnableButtons(bl1ButtonStatus)
%Little function used to update the status of buttons in a concise way
global hPROTOCOL_POPUP hCOMP_CSD_BUTTON hPLACE_L4_BUTTON hREM_L4_BUTTON 
global hPLACE_L5B_BUTTON hREM_L5B_BUTTON hRATING_POPUP hIMPORT_BUTTON hSAVE_BUTTON

cBUTTON_STATUS = cellstr(categorical(bl1ButtonStatus, 0:1, {'off', 'on'}));

set(hPROTOCOL_POPUP, 'Enable', cBUTTON_STATUS{1});
set(hCOMP_CSD_BUTTON, 'Enable', cBUTTON_STATUS{2});
set(hPLACE_L4_BUTTON, 'Enable', cBUTTON_STATUS{3});
set(hREM_L4_BUTTON, 'Enable', cBUTTON_STATUS{4});
set(hPLACE_L5B_BUTTON, 'Enable', cBUTTON_STATUS{5});
set(hREM_L5B_BUTTON, 'Enable', cBUTTON_STATUS{6});
set(hRATING_POPUP, 'Enable', cBUTTON_STATUS{7});
set(hIMPORT_BUTTON, 'Enable', cBUTTON_STATUS{8});
set(hSAVE_BUTTON, 'Enable', cBUTTON_STATUS{9});

function SetChannelDepth()
%Utility used to estimate the depth of channel based on the estimated
%position of layer 4 and layer 5b, or alternatively using the MUA peak and
%the spacing of contact points
global sLFP
global dbMUAPeakChan dbL4Chan dbL5BChan
global in1LayerDepth inMUAPeakDepth inL4Depth inL5BDepth db1ChannelDepth
global db1LayerChan

if isempty(dbL4Chan) & isempty(dbL5BChan)
    dbA = sLFP.dbLFPChanSpacingMicron;
    dbB =inMUAPeakDepth- (dbA*dbMUAPeakChan);
elseif isempty(dbL5BChan)
    dbA = sLFP.dbLFPChanSpacingMicron;
    dbB = inL4Depth - (dbA*dbL4Chan);
elseif isempty(dbL4Chan)
    dbA = sLFP.dbLFPChanSpacingMicron;
    dbB = inL5BDepth - (dbA*dbL5BChan);
else
    dbA = (inL5BDepth - inL4Depth)./(dbL5BChan - dbL4Chan);
    dbB = inL5BDepth - (dbA*dbL5BChan);
end
db1ChannelDepth = dbA*(1:16) + dbB;
db1LayerChan = (in1LayerDepth - dbB)/dbA;

function PlotMUA()
%Little utility used to plot the MUA accross layers
global chSessionName
global hMUA_PLOT in1MUASum inNInterp
global in1LayerDepth db1ChannelDepth
 
%Normalizes MUA sum
db1MUANorm = in1MUASum(2:15)./max(in1MUASum);

%Interpolates between points to make it look pretty and smooth (:))
db1Idx = 2:15;
% keyboard
db1IdxIntrp = 2:1/inNInterp:15;
db1MUANorm_Intrp = interp1(db1Idx, db1MUANorm, db1IdxIntrp, 'pchip');
db1ChanDepth_Intrp = interp1(db1Idx, db1ChannelDepth(2:15), db1IdxIntrp);

%Sets the MUA plot as the current figure
axes(hMUA_PLOT)
db1XL = [0 1.1];
db1YL = [db1ChanDepth_Intrp(1) db1ChanDepth_Intrp(end)];

%Plots our superb plot 
plot(db1MUANorm_Intrp, db1ChanDepth_Intrp, 'k')
set(hMUA_PLOT, 'YDir', 'reverse', 'YLim', db1YL, 'XLim', db1XL) %Inverts the direction of the channels on the plot
ylabel('Estimated Depth'), title(sprintf('Normalized MUA   Rec: %s', strrep(chSessionName, '_', '\_')))

%Appends the best guess for layers
hold on, plot(db1XL, [in1LayerDepth in1LayerDepth], 'k', 'LineWidth', 2), hold off 

function PlotCSD()
%Little utility used to plot the CSD 
global hCSD_PLOT db2CSD_ETA db1ETATime
global db1LayerChan
global db1L4SinkLoc db1L5BSinkLoc

%Computes the x y and z axes
db1CLim = [-1 1]*(max(max(abs(db2CSD_ETA)))); %Computes the limit of the plots
db1Chan = 2:15;

%Sets the MUA plot as the current figure
axes(hCSD_PLOT)

%Plots the CSD
if ~any(isnan(db2CSD_ETA(:)))
    imagesc(db1ETATime, db1Chan, db2CSD_ETA, db1CLim);
else
    imagesc(db1ETATime, db1Chan, db2CSD_ETA);
end

db1XL = xlim;
ylabel('Channel'), xlabel('Time (s)')
title(sprintf('CSD'));

%Appends the best guess for layers
hold on, plot(db1XL, [db1LayerChan db1LayerChan], 'k', 'LineWidth', 2)

%Appends the position of CSD sink in L4 and L5B if they have been set
if ~isempty(db1L4SinkLoc), plot(db1L4SinkLoc(1), db1L4SinkLoc(2), 'sg', 'MarkerSize', 14, ...
        'LineWidth', 2, 'MarkerFaceColor', [0.2 0.6 0.2]); end
if ~isempty(db1L5BSinkLoc), plot(db1L5BSinkLoc(1), db1L5BSinkLoc(2), 'sb', 'MarkerSize', 14, ...
        'LineWidth', 2, 'MarkerFaceColor', [0.2 0.2 0.6]); end
hold off