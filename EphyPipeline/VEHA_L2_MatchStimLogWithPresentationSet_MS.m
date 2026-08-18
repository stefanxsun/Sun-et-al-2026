% clear
cd 'E:\Ephy\VisExpHighAll';

%Defines the info file
sINFO = VEHA_DefineINFO();
sREC = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = true;

% %loops through the files
% cSESSION = {
%     '2019-07-16_10-51-34_2', ...
%     };
% in1Idx = VEHA_U_FindSessionIndex(sINFO, cSESSION);
% for i = in1Idx
%loops through the files
for i = 1:length(sREC)
    try
        VEHA_L2_MatchStimLogWithPresentationSet(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end