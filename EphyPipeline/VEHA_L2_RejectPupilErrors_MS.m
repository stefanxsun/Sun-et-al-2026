clear
cd 'E:\Ephy\VisExpHighAll';

%Defines the info file
sINFO = VEHA_DefineINFO();
sREC = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = false;
sCFG.sPARAM.blDoPlot = true; % Recomanded just to see if it works fine
sCFG.sPARAM.dbZThres_bimod = 5; %Set to inferior value if exlusion of the higher mode fales

%loops through the files
for i = 1:length(sREC)
    try
        VEHA_L2_RejectPupilErrors(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end