clear
cd 'E:\Ephy\VisExpHighAll';

%Defines the info file
sINFO = VEHA_DefineINFO();

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = 1;
% sCFG.sPARAM.blDoPlot = true;

%loops through the files
for i = 1:length(sINFO.sREC)
    sCFG.sREC = sINFO.sREC(i);
    try
        VEHA_L6_Grating_FourierPower(sCFG);
%         pause, close all
    catch ME
        getReport(ME)
    end
end
%% Aggregates the data