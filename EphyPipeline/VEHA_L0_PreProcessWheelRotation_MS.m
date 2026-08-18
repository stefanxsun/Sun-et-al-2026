% clear
cd 'E:\Ephy\VisExpHighAll';
%Defines the info file
sINFO = VEHA_DefineINFO();
sREC = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = 1;
sCFG.sPARAM.inOutputSampleRate = 2000;
sCFG.sPARAM.dbWheelDiameterM = 0.1524; %in m... measured
sCFG.sPARAM.db1WheelVRange = [1770 30850]; %bounds from actual trace (empirical)

%loops through the files
for i = 1:length(sREC)
    try
        VEHA_L0_PreProcessWheelRotation(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end