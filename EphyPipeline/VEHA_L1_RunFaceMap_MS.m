clear
cd 'E:\Ephy\VisExpHighAll';
addpath(genpath('E:\Ephy\Utilities\FaceMap-master_Quentin'));

%Defines the info file
sINFO = VEHA_DefineINFO();
sREC    = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = 1;

%loops through the files
for i = 1:length(sREC)
    try
        VEHA_L1_RunFaceMap(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end

corr