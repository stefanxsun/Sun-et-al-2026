clear
cd 'E:\Ephy\VisExpHighAll';
%Defines the info file
sINFO = VEHA_DefineINFO();
sREC = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = 1;

%loops through the files
for i = 1:length(sREC)
    try
        VEHA_L4_MakeMetaDataStructure(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end