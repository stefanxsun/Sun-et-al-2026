function in1SessionNum = VEHA_U_FindSessionDayNum(sINFO, chProcess)
%IN1SESSIONNUM = VEHA_U_FindSessionNumber(SINFO): VEHA utility
%allowing to find the session number (i.e. the number of days that the
%animal has been on the protocol).
%INPUT:
%-SINFO:        info structure given by BCP_DefineINFO();
%-CHPROCESS:    process that has been ran with the info. Example:
%               'VEHA_L7_Grating_PlotLFPPower_SFrCtrSSz'
%OUTPUT:
%-IN1SESSIONNUM:    vector of the length of sINFO and for each instance
%                   giving either the session number or NaN if the
%                   session does not correspond to the task of interest.

%2018-06-07 QP: Adapted from BCP_U_FindSessionDayNum

%Initialize some input task name
% chProcess   = 'VEHA_L7_Grating_PlotLFPPower_SFrCtrSSz';
chFileName  = [chProcess '.mat'];

%Computes a vector of the task computed
bl1IsProtoc = false(length(sINFO.sREC), 1);
in1DNum     = zeros(length(sINFO.sREC), 1);
for iSes = 1:length(sINFO.sREC)
    chSessionName = strcat(sINFO.sREC(iSes).chNlxSessionDir, '_', num2str(sINFO.sREC(iSes).inRecNum));
    try
        bl1IsProtoc(iSes) = exist(fullfile(sINFO.chBaseDirectory, chProcess, chSessionName, chFileName), 'file');
        if bl1IsProtoc(iSes)
            date = sINFO.sREC(iSes).chNlxSessionDir(9:end);
            year = ['20' date(1:2)]; month = date(3:4); day = date(5:6);
            in1DNum(iSes) = datenum([day '/' month '/' year '/'], 'dd/mm/yyyy');
        end
    catch ME
        getReport(ME)
    end
end

%Gets the ID of the mouse for each session
in1MouseID  = [sINFO.sREC(:).inMouseID]';
in1Mice     = unique(in1MouseID); %Vector containing the mice number of all the mouse used

%Calculate the session number for each mouse
in1SessionNum = nan(size(bl1IsProtoc)); % initializes the output vector
for iMouse = 1:length(in1Mice)
    in1Sessions = find(in1MouseID == in1Mice(iMouse) & bl1IsProtoc);
    [~, in1SesSortIdx] = sort(in1DNum(in1Sessions));
    in1SessionNum(in1Sessions(in1SesSortIdx)) = 1:length(in1Sessions);
end  