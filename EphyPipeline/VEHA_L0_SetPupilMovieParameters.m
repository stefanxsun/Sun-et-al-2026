function [varargout] = VEHA_L0_SetPupilMovieParameters(sCFG)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Check that the source path is valid
chSourcePath = fullfile(sCFG.sREC.chPupilMovieSessionPath);
if ~exist(chSourcePath, 'dir')
    error('Unable to locate %s in %s\r',  sCFG.sREC.chPupilMovieSessionPath);
end

%Checks that the number of movie file matches found in the directory
%matches the information in sINFO
sMOVIE_DIR = dir(chSourcePath);
bl1IsMovie = false(1, length(sMOVIE_DIR));
for ii = 1:length(sMOVIE_DIR)
    bl1IsMovie(ii) = ~isempty(strfind(sMOVIE_DIR(ii).name, '.mp4')) ||...
        ~isempty(strfind(sMOVIE_DIR(ii).name, '.avi'));
end

% if sum(bl1IsMovie) ~= sCFG.sREC.inHowManyPupilMovie
%     error('The number of movie file in %s does not match info file\r', sCFG.sREC.chPupilMovieSessionPath)
% else
%     sMOVIE_DIR = sMOVIE_DIR(bl1IsMovie);
% end

%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L0_SetPupilMovieParameters';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
chDestFolder = strcat(sCFG.sREC.chNlxSessionDir, '_', num2str(sCFG.sREC.inRecNum));
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chDestFolder)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chDestFolder);
end
chDestFile = 'VEHA_L0_SetPupilMovieParameters.mat';

%Checks that the analysis has not already been performed
if exist(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chDestFolder));
    return
else
    fprintf('Processing %s ...\r', chDestFolder);
end

% Does the preprocessing
blCompleted = false;
while ~blCompleted 
    %Cycles throught the different movies
    sMOVIE_PARAM = struct();
    in1XL = []; in1YL = [];
    for ii = 1:length(sCFG.sREC.inWhichPupilMovie)
        fprintf('Processing %d out of %d Movies. Press ENTER when ready!', ii, length(sCFG.sREC.inWhichPupilMovie));
        input(''); %flushes the keyboard buffer so that the enter command is not passed to the next input (workaround bug)
        hFig = figure;
        try
            %Opens 20 frames of the movie spaced 5 frame from another
            inMovIdx = sCFG.sREC.inWhichPupilMovie(ii);
            chMovieFullPath = fullfile(chSourcePath, sMOVIE_DIR(inMovIdx).name);
            fprintf('Opening %s.\r', sMOVIE_DIR(inMovIdx).name);
            sMMREAD_OUTPUT = mmread(chMovieFullPath, 1:5:101);
            
            %Cycle throught frames untill a good example frame is found
            chAnswer = '';
            iFrame = 0;
            figure(hFig); 
            while ~strcmpi(chAnswer, 'y') && iFrame < 21
                iFrame = iFrame + 1;
                db2Im = sMMREAD_OUTPUT(end).frames(iFrame).cdata(:,:,1);
                imagesc(db2Im), colormap('Gray')
                pause
                if iFrame == 1
                    chAnswer = input('Does the movie seem usable (type "y" if yes): ', 's'); %pause
                    figure(hFig)
                    if ~strcmpi(chAnswer, 'y')
                        break
                    end
                end
                chAnswer = input('Is the pupil visible (type "y" if yes): ', 's'); %pause
                figure(hFig)
            end
            
            %Saves the movie as unusable if all the frames are unusable
            if ~strcmpi(chAnswer, 'y')
                sMOVIE_PARAM(ii).inMovIdx = inMovIdx;
                sMOVIE_PARAM(ii).chMovieFullPath = chMovieFullPath;
                sMOVIE_PARAM(ii).blPupilMovieTrigComplete = sCFG.sREC.blPupilMovieTrigComplete(ii);
                sMOVIE_PARAM(ii).blUsable = false;
                sMOVIE_PARAM(ii).sMMREAD_OUTPUT = sMMREAD_OUTPUT;
                close(hFig)
                continue
            end
            
            % Zooms in to the pupil and saves the range
            if ~isempty(in1XL) && ~isempty(in1YL), set(gca, 'XLim', in1XL, 'YLim', in1YL); end %sets it to the limits of the previous movie if they exist
            disp('Zoom into the eye putting the pupil at the center. Press ENTER when done.')
            pause
            in1XL = round(get(gca, 'XLim'));
            in1XL(1) = max([1, in1XL(1)]); in1XL(2) = min([size(db2Im, 2), in1XL(2)]);
            in1YL = round(get(gca, 'YLim'));
            in1YL(1) = max([1, in1YL(1)]); in1YL(2) = min([size(db2Im, 1), in1YL(2)]);
            figure(hFig)
            
            %Gets some example of intensity values to expell the background

            disp('Click at four or more location on the iris')
            disp('Avoid pupil and high luminance area.')
            disp('Press BACKSPACE to undo and ENTER when done, ')
            db1PxSample = impixel;
            input(''); %flushes the keyboard buffer so that the enter command is not passed to the next input (workaround bug)
            figure(hFig)

            %Stores the parameter for the movie
            sMOVIE_PARAM(ii).blUsable = true;
            sMOVIE_PARAM(ii).inMovIdx = inMovIdx;
            sMOVIE_PARAM(ii).chMovieFullPath = chMovieFullPath;
            sMOVIE_PARAM(ii).blPupilMovieTrigComplete = sCFG.sREC.blPupilMovieTrigComplete(ii);
            sMOVIE_PARAM(ii).sMMREAD_OUTPUT = sMMREAD_OUTPUT;
            sMOVIE_PARAM(ii).db2Image = db2Im;
            sMOVIE_PARAM(ii).in1XL = in1XL;
            sMOVIE_PARAM(ii).in1YL = in1YL;
            sMOVIE_PARAM(ii).dbMaxPixValForSegmentation = round(max(max(db1PxSample))*1.1);
            close(hFig)
        catch
            sMOVIE_PARAM(ii).blUsable = false;
            sMOVIE_PARAM(ii).inMovIdx = inMovIdx;
            sMOVIE_PARAM(ii).chMovieFullPath = chMovieFullPath;
            sMOVIE_PARAM(ii).blPupilMovieTrigComplete = sCFG.sREC.blPupilMovieTrigComplete(ii);
            close(hFig)
            continue
        end
    end
    
    
    %Asks the user if it is ok to save the result
    chCompleted = input('Are you satisfied with preprocessing (type "y" if yes): ', 's'); %pause
    if strcmpi(chCompleted, 'y')
        blCompleted = true;
    end
end

    
%Writes the output in CFG
sCFG.sL0SPMP.sMOVIE_PARAM = sMOVIE_PARAM;
sCFG.sL0SPMP.chScriptName = mfilename('fullpath');
sCFG.sL0SPMP.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chDestFolder, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')