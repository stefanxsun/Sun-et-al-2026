clear
cd 'E:\Ephy\VisExpHighAll';

%Defines the info file
sINFO = VEHA_DefineINFO();
sREC = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = 1;
sCFG.sPARAM.dbWindowLenSec = .5;
sCFG.sPARAM.blDoPlot = true;

%loops through the files
for i = 1:length(sREC)
    try
        VEHA_L2_DetectFaceChangePoint(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
%     pause(), close all;
end