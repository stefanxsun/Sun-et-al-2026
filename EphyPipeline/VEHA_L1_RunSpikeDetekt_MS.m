clear
cd 'E:\Ephy\VisExpHighAll';

%Defines the info file
sINFO = VEHA_DefineINFO();
sREC = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory     = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite         = false;
sCFG.sPARAM.chCondaEnvironment  = 'klusta'; %name of the conda environment set by the user for the klusta suite
sCFG.sPARAM.dbThresholdStrong   = 6;
sCFG.sPARAM.dbThresholdWeak     = 3;
sCFG.sPARAM.inStartClustNum     = 20;
sCFG.sPARAM.dbWavfrmBefore_ms   = 0.5;
sCFG.sPARAM.dbWavfrmAfter_ms    = 1.5;

%loops through the files
parfor i = 1:length(sREC)
    try
        VEHA_L1_RunSpikeDetekt(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end