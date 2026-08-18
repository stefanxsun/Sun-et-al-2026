clear
cd 'E:\Ephy\VisExpHighAll';
%Defines the info file
sINFO   = VEHA_DefineINFO();
sREC    = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = 0;
sCFG.sPARAM.dbMarginSec = 5; %time before and after each presentation

%loops through the files
for i = 1:length(sREC)
    try
        VEHA_L5_Grating_MakeDataStructure(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end