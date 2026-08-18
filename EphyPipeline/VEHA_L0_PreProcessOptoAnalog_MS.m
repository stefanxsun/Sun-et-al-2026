clear
cd 'E:\Ephy\VisExpHighAll';
%Defines the info file
sINFO = VEHA_DefineINFO();
sREC    = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = false;
sCFG.sPARAM.inWorkingSamplingRate = 4000;

%loops through the files
for i = 1:length(sINFO.sREC)
    try
        VEHA_L0_PreProcessOptoAnalog(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end