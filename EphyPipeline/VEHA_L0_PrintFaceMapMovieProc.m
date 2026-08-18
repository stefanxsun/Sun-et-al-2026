%Defines the info file
cd 'E:\Ephy\VisExpHighAll';
sINFO   = VEHA_DefineINFO();
sREC    = sINFO.sREC;

fprintf('\r###\tSesDir\t\t\tRecNum\t\tMovieStatus\r')
fprintf('-----------------------------------------------------------------\r');


%loops through the files
for iRec = 1:length(sINFO.sREC)
    chFaceMovieDir = fullfile(sREC(iRec).chPupilMovieSessionPath,sREC(iRec).chMouseCage);
    sDIR = dir(chFaceMovieDir);
    
    bl1Movie = contains({sDIR.name}, {'.mj2','.mp4','.mkv','.avi','.mpeg','.mpg','.asf'});
    sDIR = sDIR(bl1Movie);
    
    [~, in1Idx] = sort({sDIR.date});
    sDIR = sDIR(in1Idx);
    
%     if isempty(sREC(iRec).inWhichPupilMovie), chMovieStatus = 'No movie';
%     elseif ~isnumeric(sREC(iRec).inWhichPupilMovie), chMovieStatus = 'No movie';
%     elseif mod(sREC(iRec).inWhichPupilMovie, 1) ~= 0 || sREC(iRec).inWhichPupilMovie < 1; chMovieStatus = 'No movie'; 
%     elseif isempty(sDIR), chMovieStatus = 'No movie';
%     elseif length(sDIR) ~= sREC(iRec).inHowManyPupilMovie, chMovieStatus = 'Not sure which movie';
%     else
    
    bl1MovieIdx = ismember({sDIR.name}, {sREC(iRec).chFaceMovieFile});
    if ~any(bl1MovieIdx)
        chMovieStatus = 'No movie';
    elseif sum(bl1MovieIdx) > 1
        chMovieStatus = 'Not sure which movie';
    else
        chMovieName = sDIR(bl1MovieIdx).name;
        if exist(fullfile(chFaceMovieDir, regexprep(chMovieName, '\.\w{3}$', '_proc.mat')), 'file')
            chMovieStatus = 'Pre-processed';
        else
            chMovieStatus = 'No pre-proc';
        end
    end
    fprintf('%3d:\t%s\t%d\t\t%s\r', iRec, sREC(iRec).chNlxSessionDir, sREC(iRec).inRecNum, chMovieStatus)  
end