clear
% run StartupAnalysis.m
% cd '/media/storage/Quentin/Analyses/GammaChronicProbe';

%Adds the CLAMS codes to the path
% addpath(genpath('/media/storage/Quentin/Scripts/Matlab/gamma_bouts'))

%Defines the info file
sINFO   = VEHA_DefineINFO();
sREC    = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory     = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite         = 1;
sCFG.sPARAM.cBAND               = {[15 30], [30 80]};
sCFG.sPARAM.cBAND_LABEL         = {'15-30Hz', '30-80Hz'};
sCFG.sPARAM.cSTATE              = {'Stim', 'Running'};
sCFG.sPARAM.inNClu 				= 20;
sCFG.sPARAM.dbSigThrs 			= 10.^-3;
sCFG.sPARAM.blHPass_MovArtefact = false;
sCFG.sPARAM.dbHighBound         = 10;

%loops through the files
for i = 1:length(sREC)
     try
        VEHA_L5_GetPulse(sCFG, sREC(i));
     catch ME
 		chSessionName = strcat(sREC(i).chNlxSessionDir, '_', num2str(sREC(i).inRecNum));
 		try, rmdir(fullfile('VEHA_L5_GetPulse', chSessionName)); end
         getReport(ME)
     end
end
