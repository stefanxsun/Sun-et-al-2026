function [varargout] = VEHA_L2_RejectPupilErrors(sCFG, sREC)
%checks for the proper number of output arugments
nargoutchk(0,1);

%Recreates the session folder name
chSessionName = strcat(sREC.chNlxSessionDir, '_', num2str(sREC.inRecNum));

%Checks the input path
if sCFG.sPARAM.blDoPlot
    chSourcePath_1 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L0_SetPupilMovieParameters');
    chSPMPFile = 'VEHA_L0_SetPupilMovieParameters.mat';
    if ~exist(fullfile(chSourcePath_1, chSessionName, chSPMPFile), 'file')
        error('%s does not exist for session %s in %s\r', chSPMPFile, chSessionName, chSourcePath_1)
    end
end

chSourcePath_2 = fullfile(sCFG.sPARAM.chBaseDirectory, 'VEHA_L1_DetectPupil');
chDPFile = 'VEHA_L1_DetectPupil.mat';
if ~exist(fullfile(chSourcePath_2, chSessionName, chDPFile), 'file')
    error('%s does not exist for session %s in %s\r', chDPFile, chSessionName, chSourcePath_2)
end


%Sets the destination folder
chDestPath = sCFG.sPARAM.chBaseDirectory;
chDestMetaFolder = 'VEHA_L2_RejectPupilErrors';
if ~isdir(fullfile(chDestPath, chDestMetaFolder))
    mkdir(chDestPath, chDestMetaFolder)
end
if ~isdir(fullfile(chDestPath, chDestMetaFolder, chSessionName)) 
    mkdir(fullfile(chDestPath, chDestMetaFolder), chSessionName);
end
chDestFile = 'VEHA_L2_RejectPupilErrors.mat';
%Checks that the data do not exist
if exist(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'file') && ~sCFG.sPARAM.blOverwrite
    fprintf('%s already exist in:\r %s.\r Skipped...\r', chDestFile, fullfile(chDestPath, chDestMetaFolder, chSessionName));
    return
else
    fprintf('Processing %s ...', chSessionName);
end

% Loads the imput
if sCFG.sPARAM.blDoPlot
    sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chSPMPFile), '-mat');
end
sINPUT_2 = load(fullfile(chSourcePath_2, chSessionName, chDPFile), '-mat');
sMOVIE_RE = sINPUT_2.sCFG.sL1DP.sMOVIE_CR;

%Loops through the movies
for ii = 1:length(sMOVIE_RE)
    %Extracts the output matrix of the pupil detection
    db2CROut = sMOVIE_RE(ii).db2CROutput;
    
    %Extracts time stamp (for plotting purpose only), the short and long axes
    %and computes the eccentricity
    if sCFG.sPARAM.blDoPlot
        db1Time = db2CROut(:, 4);
    end
    db1a = db2CROut(:, 1)./2;
    db1b = db2CROut(:, 2)./2;
    db1Eccentricity = sqrt(((db1a.^2) - (db1b.^2))./(db1a.^2));
    bl1Exclude = db1Eccentricity > 0.8; %Rejects high eccentricity
    
    
    %Extracts the coordinates of the center of the ellipse
    db1X0in = db2CROut(:, 5);
    db1Y0in = db2CROut(:, 6);
    
    %Computes Mahalanobis distance of the centers, removes outliers (centers
    %having a Mahalanobis distance > 5) and reitarates until a stable outcome
    %is reached or a final number of iteration is reached
    inSumExclude = -1;
    inNIter = 0;
    while inSumExclude ~= sum(bl1Exclude) && inNIter < 100
        inSumExclude = sum(bl1Exclude);
        inNIter = inNIter + 1;
        
        db1X0in_e = db1X0in; db1X0in_e(bl1Exclude) = NaN; %removes outliers
        db1Y0in_e = db1Y0in; db1Y0in_e(bl1Exclude) = NaN;
        
        db2ECCoor = [db1X0in_e db1Y0in_e]; %Coordinates of the center of the ellipse
        db2S = nancov(db2ECCoor); %Covariance matrix
        db1Mu = nanmean(db2ECCoor); %Vector of means
        
        db2ECCoorCntrd = db2ECCoor - repmat(db1Mu, length(db1X0in_e), 1);
        db1ECMahalCoor = sqrt(sum((db2ECCoorCntrd/db2S).*db2ECCoorCntrd,2)); %Mahalanobis distance
        
        bl1Exclude = bl1Exclude | db1ECMahalCoor > 5; %update exclusion vector
    end
    
    %Extracts the area
    db1Area = db2CROut(:, 3);
    
    %Checks for bimodality in the area trace if so rejects the higher mode
    db1QArea = quantile(db1Area, linspace(0.02, 0.98, 49));
    db1ZDArea = zscore(diff(db1QArea));
    [dbMaxZDiff, inMaxIdx] = max(db1ZDArea);
    if inMaxIdx > 24 && inMaxIdx < 47 && dbMaxZDiff > sCFG.sPARAM.dbZThres_bimod
        db1AreaThres = db1QArea(inMaxIdx + 1);
        bl1Exclude = bl1Exclude | db1Area > db1AreaThres;
        %     if sCFG.blDoPlot
        %         figure, plot(db1ZDArea), YL = get(gca, 'YLim'); hold on, plot([inMaxIdx inMaxIdx] + 1, YL, 'r');
        %         title(strrep(chSessionName, '_', ' '))
        %     end
    end
    
    
    %Computes the zscore of the short and long axes, their differential, the
    %deviation of a linear predictor of the long axis as a function of the
    %short and of the area. Reject outliers (threshold varies) and reiterates
    %untill stability or a maximum number of iteration is reached
    inSumExclude = -1;
    inNIter = 0;
    while inSumExclude ~= sum(bl1Exclude) && inNIter < 100
        inSumExclude = sum(bl1Exclude);
        inNIter = inNIter + 1;
        
        db1a_e = db1a; db1a_e(bl1Exclude) = NaN; %removes outliers
        db1b_e = db1b; db1b_e(bl1Exclude) = NaN;
        db1Da = diff(db1a_e);
        db1Db = diff(db1b_e);
        db1Area_e = db1Area; db1Area_e(bl1Exclude) = NaN;
        
        %Fits the short axis as a function of the long
        db1phat = polyfit(db1a_e(~isnan(db1a_e)), db1b_e(~isnan(db1b_e)), 1);
        db1yhat = polyval(db1phat, db1a_e);
        db1Err = db1b_e - db1yhat; %Computes the error of the fit
        
        %Computes zscores
        db1Za = abs((db1a_e - nanmean(db1a_e))./nanstd(db1a_e));
        db1Zb = abs((db1b_e - nanmean(db1b_e))./nanstd(db1b_e));
        db1ZDa = [abs((db1Da - nanmean(db1Da))./nanstd(db1Da)); nanmean(db1Da)];
        db1ZDb = [abs((db1Db - nanmean(db1Db))./nanstd(db1Db)); nanmean(db1Db)];
        db1ZErr = abs((db1Err - nanmean(db1Err))./nanstd(db1Err));
        db1ZArea = abs((db1Area_e - nanmean(db1Area_e))./nanstd(db1Area_e));
        
        %Updates exclusion vector
        bl1Exclude = bl1Exclude| db1Za > 5 | db1Zb > 5;
        bl1Exclude = bl1Exclude | db1ZDa > 8 | db1ZDb > 8;
        bl1Exclude = bl1Exclude | db1ZErr > 7;
        bl1Exclude = bl1Exclude | db1ZArea > 5;
    end
    
    %Performs a morphological closure of order 3 to remove isolated chuncks of
    %trace
    bl1Exclude = NS_CloseBoolean(bl1Exclude, 3);
    
    %Plots the results if required
    if sCFG.sPARAM.blDoPlot
        %Center of the pupil
        db2ExIm = sINPUT_1.sCFG.sL0SPMP.sMOVIE_PARAM(ii).db2Image;
        in1XL = sINPUT_1.sCFG.sL0SPMP.sMOVIE_PARAM.in1XL;
        in1YL = sINPUT_1.sCFG.sL0SPMP.sMOVIE_PARAM.in1YL;
        db2ExImResize = db2ExIm(in1YL(1):in1YL(2), in1XL(1):in1XL(2));
        
        db2ImCoorX = repmat((1:range(in1XL) + 1), size(db2ExImResize, 1), 1);
        db2ImCoorY = repmat((1:range(in1YL) + 1)', 1,  size(db2ExImResize, 2));
        db2ImCoorCntrd = [db2ImCoorX(:) db2ImCoorY(:)] - repmat(db1Mu, numel(db2ImCoorX), 1);
        
        db1ImMahalCoor = sqrt(sum((db2ImCoorCntrd/db2S).*db2ImCoorCntrd,2));
        db2ImMahalCoor = reshape(db1ImMahalCoor, size(db2ExImResize));
        
        figure, imagesc(db2ExImResize), colormap('Gray'), hold on, plot(db1X0in, db1Y0in, 'xg')
        plot(db1X0in(bl1Exclude), db1Y0in(bl1Exclude), 'xr'),
        contour(db2ImMahalCoor, 'ShowText', 'on'),  legend('valid', 'excluded', 'Mahalonobis'),
        title([strrep(chSessionName, '_', ' ') 'Movie ' num2str(ii)])
        
        %a and b on a time trace
        db1a_e = db1a; db1a_e(bl1Exclude) = NaN;
        db1b_e = db1b; db1b_e(bl1Exclude) = NaN;
        
        db1YVal = nanmean(db1a_e)*ones(size(db1a));
        %     figure, plot(db1Time, [db1a_e db1b_e]), hold on, plot(db1Time(bl1Exclude), db1YVal(bl1Exclude), '.r');
        figure, plot(db1Time, [db1a db1b]), hold on, plot(db1Time(bl1Exclude), db1YVal(bl1Exclude), '.r');
        db1VV = [db1a_e; db1b_e]; ylim([min(db1VV)-0.1*range(db1VV) max(db1VV)+0.1*range(db1VV)]);
        legend('a', 'b', 'Excluded');
        title([strrep(chSessionName, '_', ' ') 'Movie ' num2str(ii)]), xlabel('time (s)')
    end
    
    %Stores the exclusion vector in the output Matrix
    sMOVIE_RE(ii).bl1Exclude = bl1Exclude;
end

%Update sREC
sCFG.sREC = sREC;

%Keeps track of the input in CSG
sCFG.sINPUT.sL1DP.chScriptName = sINPUT_2.sCFG.sL1DP.chScriptName;
sCFG.sINPUT.sL1DP.chTimeComputed = sINPUT_2.sCFG.sL1DP.chTimeComputed;

%Writes the output in CSG
sCFG.sL2RPE.sMOVIE_RE = sMOVIE_RE;
sCFG.sL2RPE.chScriptName = mfilename('fullpath');
sCFG.sL2RPE.chTimeComputed = datestr(now);

%Saves the output
save(fullfile(chDestPath, chDestMetaFolder, chSessionName, chDestFile), 'sCFG', '-v7.3');

%Returns the output if asked
if nargout > 0
    varargout{1} = sCFG;
end

fprintf('Done! \r')