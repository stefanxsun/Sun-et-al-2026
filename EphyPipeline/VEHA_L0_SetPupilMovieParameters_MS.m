clear
cd 'E:\Ephy\VisExpHighAll';
%Defines the info file
sINFO = VEHA_DefineINFO();

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = false;

%loops through the files
for i = 1:length(sINFO.sREC)
    sCFG.sREC = sINFO.sREC(i);
    try
        VEHA_L0_SetPupilMovieParameters(sCFG);
    catch ME
        getReport(ME)
    end
end