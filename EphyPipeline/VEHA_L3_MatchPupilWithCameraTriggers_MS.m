clear
cd 'E:\Ephy\VisExpHighAll';
%Defines the info file
sINFO = VEHA_DefineINFO();
sREC = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = false;
sCFG.sPARAM.blDoPlot = false; 


%loops through the files
for i = 1:length(sINFO.sREC)
    try
        VEHA_L3_MatchPupilWithCameraTriggers(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end