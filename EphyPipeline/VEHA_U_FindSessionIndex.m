function in1Idx = VEHA_U_FindSessionIndex(sINFO, cSESSION)
%INIDX = BCP_FindSession(SINFO, CSESSION)
%Finds the index IN1IDX of the sessions listed in CSESSION in the info file
%SINFO

%Computes cell array and vector of the neuralynx directories and recording
%numbers
cNLX = {sINFO.sREC(:).chNlxSessionDir};
in1RNum = [sINFO.sREC(:).inRecNum];

%Initialize the response vector
in1Idx = nan(size(cSESSION));

%Loops through sessions
for iSes = 1:length(cSESSION)
    %Gets the neuralynx sesssion directory and the session number of the
    %chSessionName
    chSession = cSESSION{iSes};
    inNumIdx    = regexp(chSession, '\d+$');
    inRNum      = str2double(chSession(inNumIdx:end));
    if isempty(inRNum); continue; end
    chNlxDir = chSession(1:end - 2);
    
    %Finds the index
    inIdx = find(strcmp(chNlxDir, cNLX) & in1RNum == inRNum);
    if numel(inIdx) > 1
                keyboard
        error('There is %d sessions in sINFO corresponding to %s', numel(inIdx), cSESSION{iSes})

    elseif numel(inIdx) == 1
        in1Idx(iSes) =  inIdx;
    end
end