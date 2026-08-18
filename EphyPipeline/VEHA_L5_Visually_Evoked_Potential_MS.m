clear
% run StartupAnalysis.m
cd 'E:\Ephy\VisExpHighAll';

%Defines the info file
sINFO = VEHA_DefineINFO();

%Defines the parameters
sCFG.sPARAM.cTHRESHOLD = {'3SDRandData', 'ScorePower', '.70'};
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = true;


for i = 1:length(sINFO.sREC)
	sCFG.sREC = sINFO.sREC(i);
    try
        VEHA_L5_Visually_Evoked_Potential(sCFG)
        close all
    catch ME
        getReport(ME)
    end
end
% error('VOLONTARY SCRIPT STOP');

%% Aggregates the data accross the sessions into different figures for each subsequent day
clear, close all
cd 'E:\Ephy\VisExpHighAll';
chSessionDir 	= 'VEHA_L5_Visually_Evoked_Potential';
chFileName 		= [chSessionDir '.mat'];
chFigDir 		= fullfile('Figure', chSessionDir); if ~exist(chFigDir, 'dir'); mkdir('Figure', chSessionDir); end
blVisible 		= 1;
sDIR 			= dir(chSessionDir);

%Sets the bands
cBAND 		= {'15-30Hz', '30-80Hz'};
inNBnd 		= length(cBAND); 

%Defines the info file and get the sessions for which the protocol exist
sINFO 		= VEHA_DefineINFO();
in1Session  = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR(:).name})));
in1InfoIdx  = VEHA_U_FindSessionIndex(sINFO, {sDIR(in1Session).name});
in1Day      = VEHA_U_FindSessionDayNum(sINFO, chSessionDir);
in1Day      = in1Day(in1InfoIdx);
in1Mouse    = [sINFO.sREC.inMouseID];
in1Mouse    = in1Mouse(in1InfoIdx);
[MouseNum,~,MouseSeq] = unique(in1Mouse);     

% Initializes sCOND
[in1SesDay, in1SesMouse] = deal([]);

% Aggregates the data
fprintf('Aggregating data... ')
chanLayer = cell(length(MouseNum),in1Day(end));
allSesVEP = cell(length(MouseNum),in1Day(end));
SesCond = cell(length(MouseNum),in1Day(end));
alltrace = cell(length(MouseNum),in1Day(end));

for iSes = 1:length(in1Session)

    sLD = load(fullfile(chSessionDir, sDIR(in1Session(iSes)).name, chFileName)); % loads the file
    
    in1SesDay       = cat(1, in1SesDay, in1Day(iSes));
    in1SesMouse     = cat(1, in1SesMouse, in1Mouse(iSes));
    SesCond{MouseSeq(iSes),in1Day(iSes)} = sLD.db2CondPrs;
    allSesVEP{MouseSeq(iSes),in1Day(iSes)}= sLD.VEP;
    alltrace{MouseSeq(iSes),in1Day(iSes)}= sLD.alltrace;  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       ADDED by STEFAN
    chanLayer{MouseSeq(iSes),in1Day(iSes)}= sLD.chanLayer;  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       ADDED by STEFAN
    
end

fprintf('Done !\r');

%%
NS_L5_VEP_Plot