function [varargout] = VEHA_L1_RunFaceMap(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L1_RunFaceMap';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName))
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile_Mat  = 'VEHA_L1_RunFaceMap.mat';
% Checks that the data do not exist
% Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile_Mat, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...\r', chSessionName);
end

% From PrintFaceMapMovieProc ----------------------------------------------
    %Get the path to the face movie
chFaceMovieDir = fullfile(sREC.chPupilMovieSessionPath,sREC.chMouseCage);
% chFaceMovieDir = strrep(chFaceMovieDir, '\\', '/media/');
% chFaceMovieDir = strrep(chFaceMovieDir, '\', '/');
% chFaceMovieDir = fullfile(chFaceMovieDir, sREC.chPupilMovieSessionDir);
sDIR = dir(chFaceMovieDir);
    %Identifies Movie in the directory and sorts them
bl1Movie = contains({sDIR.name}, {'.mj2','.mp4','.mkv','.avi','.mpeg','.mpg','.asf'});
sDIR = sDIR(bl1Movie);
[~, in1Idx] = sort({sDIR.date});
sDIR = sDIR(in1Idx);

%Checks that the movie can be identified aborts if not
% if isempty(sREC.inWhichPupilMovie), blMovie = false;
% elseif ~isnumeric(sREC.inWhichPupilMovie), blMovie = false;
% elseif mod(sREC.inWhichPupilMovie, 1) ~= 0 || sREC.inWhichPupilMovie < 1; blMovie = false;
% elseif isempty(sDIR), blMovie = false;
% elseif length(sDIR) ~= sREC.inHowManyPupilMovie, blMovie = false;
% else, blMovie = true;
% end

bl1MovieIdx = ismember({sDIR.name}, {sREC.chFaceMovieFile});
blMovie = sum(bl1MovieIdx) == 1;   
if ~blMovie, disp('No Face movie'); rmdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)); return; end
    
%Checks that the movie has been preprocessed
chMovieName     = sDIR(bl1MovieIdx).name;
chPreProcFile   = regexprep(chMovieName, '\.\w{3}$', '_proc.mat');
blPreProc       = exist(fullfile(chFaceMovieDir, chPreProcFile), 'file');
if ~blPreProc, disp('Movie not pre-processed'); rmdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)); return; end

%Load the processed movie
sIN = load(fullfile(chFaceMovieDir, chPreProcFile));
h = sIN.proc;

%From MovieGUI --> compute h.vr = video reader object
h.vr = [];
fstr{1}=[];
for k = 1:size(h.files,1)
    for j = 1:size(h.files,2)
        h.vr{k,j} = VideoReader(h.files{k,j});
    end
    h.whichfile = k;
end

%From Face Map (Carsen Stringer: Stringer et al. 2018) function
%processROI.m ------------------
% compute mean from a subset of frames
tic; h = subsampledMean(h);
h.nframes = int64(h.nframes);

% compute svd of videos ----------------------------- %
h = computeSVDmotion(h);

% pupil, blink and running ROIs
h.spix{1}=[];
zf = find(h.plotROIs);
zf = zf(ismember(zf,[1 numel(h.plotROIs)-3:numel(h.plotROIs)]));
% these ROIs are not down-sampled in space
% h.iroi are full frame positions
for z = zf(:)'
    if h.plotROIs(z)
        k = h.ROIfile(z);
        nx = floor(h.nX{k});
        ny = floor(h.nY{k});
        h.spix{z} = false(ny, nx);
        iroi = max(1,floor(h.locROI{z} * h.sc));
        pos = round(iroi);
        h.spix{z}(pos(2)-1 + [1:pos(4)], pos(1)-1 + [1:pos(3)]) = 1;
        h.iroi{z} = pos;
    end
end

%
% get timetraces for U and compute pupil and running ------------ %
h = projectMasks(h);

%Update sREC
sCFG.sREC = sREC;

%Record the output
sCFG.sL2.h                  = h;
sCFG.sL2.chScriptName       = mfilename('fullpath');
sCFG.sL2.chTimeComputed     = datestr(now);
 
%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile_Mat), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('\rDone! \r')