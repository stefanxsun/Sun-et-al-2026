clear
cd 'E:\Ephy\VisExpHighAll';
%Defines the info file
sINFO = VEHA_DefineINFO();
sREC = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = false;
sCFG.sPARAM.blWriteVid = true;

%loops through the files
parfor i = 1:length(sREC)
    try
        VEHA_L1_DetectPupil(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end