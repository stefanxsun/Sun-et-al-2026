% clear
cd 'E:\Ephy\VisExpHighAll';
%Defines the info file
sINFO = VEHA_DefineINFO();
sREC = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = 1;
sCFG.sPARAM.dbWindowLenSec = 4; %Won't work well below 3. Takes more time if set to longer times
sCFG.sPARAM.blDoPlot = true;

%loops through the files
for i = 1:length(sREC)
    try
        VEHA_L1_DetectWheelChangePoint(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end