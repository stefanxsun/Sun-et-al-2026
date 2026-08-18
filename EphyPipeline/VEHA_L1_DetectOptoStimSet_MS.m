clear
cd 'E:\Ephy\VisExpHighAll';
%Defines the info file
sINFO = VEHA_DefineINFO();
sREC    = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = false;
sCFG.sPARAM.blDoPlot = true;

% %Finds the indices of sessions of interest
% cSESSION    = {'2019-06-11_14-03-30_4'};
% in1Idx      = VEHA_U_FindSessionIndex(sINFO, cSESSION);
% 
% %loops through the files
% for i = in1Idx
for i = 1:length(sINFO.sREC)
    try
        VEHA_L1_DetectOptoStimSet(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end