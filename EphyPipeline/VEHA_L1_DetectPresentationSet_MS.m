% clear
cd 'E:\Ephy\VisExpHighAll';
%Defines the info file
sINFO = VEHA_DefineINFO();
sREC = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = true;
sCFG.sPARAM.blDoPlot = true;
sCFG.sPARAM.blVerbose = true;
sCFG.sPARAM.blOnOffBlink = false;
if sCFG.sPARAM.blOnOffBlink
	sCFG.sPARAM.db1StimLenSec = [1 3];
	sCFG.sPARAM.dbJitterOnOff = .3;
end

% cSESSION = {
%     '2020-11-17_14-08-37_1', ...
% }; 
% in1Idx = VEHA_U_FindSessionIndex(sINFO, cSESSION);
% 
% for i = in1Idx
for i = 1:length(sREC)
    try
        VEHA_L1_DetectPresentationSet(sCFG, sREC(i))
    catch ME
        getReport(ME)
    end
    hFIG = findobj('type', 'Figure');
    if length(hFIG) > 20; pause; close all; end
end
