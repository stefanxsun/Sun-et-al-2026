clear
cd 'E:\Ephy\VisExpHighAll';
%Adds the CLAMS codes to the path
% addpath(genpath('/media/storage/Quentin/Scripts/Matlab/gamma_bouts'))

%Defines the info file
sINFO   = VEHA_DefineINFO();
sREC    = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory     = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite         = true;
sCFG.sPARAM.cTHRESHOLD         	= {'MahalDNorm'};
sCFG.sPARAM.dbWinLenSec         = .4;

%loops through the files
for i = 1:length(sREC)
     try
        VEHA_L6_Pulse_vs_LFP_ETA(sCFG, sREC(i));
     catch ME
 		chSessionName = strcat(sREC(i).chNlxSessionDir, '_', num2str(sREC(i).inRecNum));
 		try rmdir(fullfile('VEHA_L6_Pulse_vs_LFP_ETA', chSessionName)); end
        getReport(ME)
     end
end

error('INTENTIONAL ERROR');
%% loading all data needed
clear

chSessionDir = 'VEHA_L6_Pulse_vs_LFP_ETA';
chFileName = [chSessionDir '.mat'];
sDIR = dir(chSessionDir);

%Initializes info session and related variables
sINFO = VEHA_DefineINFO();
in1Session  = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR(:).name})));
in1InfoIdx  = VEHA_U_FindSessionIndex(sINFO, {sDIR(in1Session).name});
in1Mouse    = [sINFO.sREC.inMouseID];
in1Mouse    = in1Mouse(in1InfoIdx);


%Defines a band of interest
cBAND       = {'15-30Hz', '30-80Hz'};
cBND_VAL    = {[15 30], [30 80]};
cSTATE      = {'Stim', 'Running'};
inNBnd 		= length(cBAND);
cTHRESHOLD 	= {'MahalDNorm'};
inNThr 		= length(cTHRESHOLD);

%Initializes the depth for the LFP and CSD
db1ETADepthGrid     = 100:50:800;
db1CSDDepthGrid     = 150:10:750;

%Initinializes the output structure
sBAND = struct('db3ETA', cell(inNThr, inNBnd), 'db3ETVar', cell(inNThr, inNBnd), ...
    'db3ETA_Rnd', cell(inNThr, inNBnd), 'db3ETVar_Rnd', cell(inNThr, inNBnd), ...
    'in3NEvt', cell(inNThr, inNBnd));

% Aggregates the data
fprintf('Aggregating data... ')
blInit      = true;
in1Error    = [];
%Loops over sessions
for iSes = in1Session
    try
        % Loads the session data
        sLD = load(fullfile(chSessionDir, sDIR(iSes).name, chFileName)); % loads the file
        sLD = sLD.sCFG;
        
        % Initialize power paramters and checks for their consistency
        % across sessions
        if blInit
            db1ETA_Time     = sLD.sL6.sBAND(1).db1ETA_Time;
            inSampleRate    = sLD.sL6.inSampleRate;
        else
            if ~NS_CompMat(db1ETA_Time, sLD.sL6.sBAND(1).db1ETA_Time) | ~NS_CompMat(inSampleRate, sLD.sL6.sBAND(1).inSampleRate)
                fprintf('The power parameters are inconsistent in session %s\n', sDIR(iSes).name);
                continue
            end
        end
        
        %Extract the depth of the recording
        db1Depth = sLD.sL6.db1ChannelDepth;
        
        %Extract the sBAND structure
        sSES_BAND = sLD.sL6.sBAND;
        
        %Loops through bands in ses band
        for iBnd = 1:inNBnd, for iThr = 1:inNThr
            % Finds the band of interest and copy the corresponding ETA structure
            bl2Band = ismember({sSES_BAND.chBandLabel}, cBAND{iBnd}) & ismember({sSES_BAND.chStateLabel}, cSTATE{iBnd}) ...
                & ismember({sSES_BAND.chThreshold}, cTHRESHOLD{iThr});
            if ~any(bl2Band(:)), continue; end
            if sum(bl2Band(:)) ~= 1, continue; end
            
            % Aggregates power for wanted conditions
            sBAND(iThr, iBnd).db3ETA        = cat(3, sBAND(iThr, iBnd).db3ETA, interp1(db1Depth, sSES_BAND(bl2Band).db2ETA, db1ETADepthGrid));
            sBAND(iThr, iBnd).db3ETVar      = cat(3, sBAND(iThr, iBnd).db3ETVar, interp1(db1Depth, sSES_BAND(bl2Band).db2ETSD .^ 2, db1ETADepthGrid));
            sBAND(iThr, iBnd).db3ETA_Rnd 	= cat(3, sBAND(iThr, iBnd).db3ETA_Rnd, interp1(db1Depth, sSES_BAND(bl2Band).db2ETA_Rnd, db1ETADepthGrid));
            sBAND(iThr, iBnd).db3ETVar_Rnd  = cat(3, sBAND(iThr, iBnd).db3ETVar_Rnd, interp1(db1Depth, sSES_BAND(bl2Band).db2ETSD_Rnd .^ 2, db1ETADepthGrid));
            sBAND(iThr, iBnd).in3NEvt       = cat(3, sBAND(iThr, iBnd).in3NEvt, sSES_BAND(bl2Band).inNEvt);
        end, end
    catch ME
        fprintf('\nError loading %s', sDIR(in1Session(iSes)).name)
%         getReport(ME)
        in1Error = cat(1, in1Error, iSes);
    end
end

%Remove sessions for which there was an error from the indexing variables
bl1Rem = ismember(in1Session, in1Error);
in1Mouse(bl1Rem)    = [];


fprintf('\nDone!\n');
%% Averages and plots the data
clear hFIG
iFig = 0;
iday = repmat(1:7,1,7);
%Averages conditions over session for each individual mouse
in1U_Mse 		= unique(in1Mouse);
inNMse 			= length(in1U_Mse);

%Loops through bands in ses band
for iBnd = 1:inNBnd
    for iThr = 1:inNThr
        
        %Initializes the figure
        iFig = iFig + 1;
        hFIG(iFig)      = figure('Position', [50 50 1250 600]);
        cFIGNAME{iFig}  = sprintf('%s', cBAND{iBnd});
        
        %Aggregates the ETA
        db3ETA_Mse      = nan(length(db1ETADepthGrid), length(db1ETA_Time), inNMse);
        db3ETARnd_Mse 	= nan(length(db1ETADepthGrid), length(db1ETA_Time), inNMse);
        db3CSD_Mse      = nan(length(db1CSDDepthGrid), length(db1ETA_Time), inNMse);
        
        %Loops over mice
        for iMse = 1:length(in1U_Mse)
            bl1Mse = in1Mouse == in1U_Mse(iMse);
            bl1Mse = bl1Mse & iday== 1;    %%% STEFAN added, 05/28/2024, to plot only for one day
            % Aggregates Saline
            bl1Cond = bl1Mse;
            if ~isempty(bl1Cond)
                db3ETA_Mse(:, :, iMse)  = ...
                    NS_GrandStats(sBAND(iThr, iBnd).db3ETA(:, :, bl1Cond), ...
                    sBAND(iThr, iBnd).db3ETVar(:, :, bl1Cond), sBAND(iThr, iBnd).in3NEvt(:, :, bl1Cond), 3);
                db3ETARnd_Mse(:, :, iMse)  = ...
                    NS_GrandStats(sBAND(iThr, iBnd).db3ETA_Rnd(:, :, bl1Cond), ...
                    sBAND(iThr, iBnd).db3ETVar_Rnd(:, :, bl1Cond), sBAND(iThr, iBnd).in3NEvt(:, :, bl1Cond), 3);
                db3CSD_Mse(:, :, iMse)  = interp1(db1ETADepthGrid(2:end-1), NS_DoCSD(db3ETA_Mse(:, :, iMse), 6), db1CSDDepthGrid);
            end
        end
        
        % 1. PLots the average field potential around pulses as a function of depth ----------------------------------------
        
        %Computes the mean and SEM of the ETA
        db2ETA_Av   = nanmean(db3ETA_Mse, 3);
        db2ETA_SEM  = sqrt(nanvar(db3ETA_Mse, [], 3)./sum(~isnan(db3ETA_Mse)));
        %Computes the mean and SEM of the random event ETA
        %     db2ETARnd_Av   = mean(db3ETARnd_Mse, 3);
        %     db2ETARnd_SEM  = sqrt(var(db3ETARnd_Mse, [], 3)./sum(~isnan(db3ETARnd_Mse)));
        
        %Sets the channels and the time of interest of plotting the field
        dbTBnd      = 1.5 ./ median(cBND_VAL{iBnd});
        bl1TSel     = abs(db1ETA_Time) < dbTBnd;
        
        %Plots the LFP
        subplot(1, 3, 1);
        db1YL = NS_PlotLFP(db2ETA_Av(:, bl1TSel), db1ETA_Time(bl1TSel));
        plot([0 0], db1YL, 'k--', 'LineWidth', 1)
        xlim([-1 1] * dbTBnd)
        db1YTLbl    = db1ETADepthGrid;
        set(gca, 'YTickLabel', db1YTLbl(end:-1:1)); ylabel('Depth (um)');
        title(sprintf('Average field around %s pulses', cBAND{iBnd}));
        
        % 2. PLots the average CSD around pulses as a function of depth ----------------------------------------------------
        
        %Computes the mean and SEM of the ETA
        db2CSD_Av   = nanmean(db3CSD_Mse, 3);
        db2CSD_SEM  = sqrt(nanvar(db3CSD_Mse, [], 3)./sum(~isnan(db3CSD_Mse)));
        
        %Defines layer depth
        in1LayerDepth = [68; 306; 442; 714];
        
        %Plots the CSD
        subplot(1, 3, 2); hold on
        imagesc(db1ETA_Time(bl1TSel), db1CSDDepthGrid, db2CSD_Av(:, bl1TSel));
        ylim(db1CSDDepthGrid([1 end])); xlim([-1 1] * dbTBnd);
        set(gca, 'YDir', 'reverse');
        plot([0 0], ylim, 'k--', 'LineWidth', 1)
        for iLyr = 1:length(in1LayerDepth)
            plot(xlim, [1 1] * in1LayerDepth(iLyr), 'k', 'LineWidth', 2);
        end
        ylabel('Depth (um)'), xlabel('Time (s)');
        title(sprintf('CSD around %s pulses', cBAND{iBnd}));
        
        % 3. PLots the average spectrum of the LFP --------------------------------------------------------------------------inNSmp_ETA
        
        %Sets the parameters for multitaper estimate
        dbW_Hz      = .8;
        inTopFreq   = 120;
        dbWinLenSec = range(db1ETA_Time);
        inNSmp_ETA  = length(db1ETA_Time);
        dbNW 		= dbW_Hz * 2 * pi * inNSmp_ETA / inSampleRate;
        inNTp 		= round(2 * dbNW - 1);
        db1Freq 	= 0 : 1/dbWinLenSec : inTopFreq;
        in1FreqIdx 	= 1:inTopFreq * dbWinLenSec + 1;
        inNFreq     = length(in1FreqIdx);
        
        %Loops over mice and computes power for the ETA and random event ETA
        [db2Pwr_Mse, db2PwrRnd_Mse] = deal(nan(inNMse, inNFreq));
        for iMse = 1:length(in1U_Mse)
            [db2Pwr, db2PwrRnd] = deal(nan(size(db2ETA_Av, 1), inNFreq));
            for iChan = 1:size(db2ETA_Av, 1)
                db1Pwr              = NS_SineMultiTaperPSD(db3ETA_Mse(iChan, :, iMse), inSampleRate, inNTp);
                db2Pwr(iChan, :)    = db1Pwr(in1FreqIdx)';
                db1PwrRnd           = NS_SineMultiTaperPSD(db3ETARnd_Mse(iChan, :, iMse), inSampleRate, inNTp);
                db2PwrRnd(iChan, :) = db1PwrRnd(in1FreqIdx)';
            end
            db2Pwr_Mse(iMse, :)     = 10 * log10(nanmean(db2Pwr, 1));
            db2PwrRnd_Mse(iMse, :)  = 10 * log10(nanmean(db2PwrRnd, 1));
        end
        
        %Computes the mean and SEM of the ETA and the random event ETA
        db1Pwr_Av       = nanmean(db2Pwr_Mse, 1);
        db1Pwr_SEM      = sqrt(nanvar(db2Pwr_Mse, [], 1)./sum(~isnan(db2Pwr_Mse)));
        db1PwrRnd_Av    = nanmean(db2PwrRnd_Mse, 1);
        db1PwrRnd_SEM   = sqrt(nanvar(db2PwrRnd_Mse, [], 1)./sum(~isnan(db2PwrRnd_Mse)));
        
        subplot(1, 3, 3); hold on
        if iBnd == 1; db1Color = [0 .2 1]; else, db1Color = [1 .4 0]; end
        hP2(1) = NS_MeanErrPlot(db1Freq, db1PwrRnd_Av, db1PwrRnd_SEM, [.5 .5 .5]);
        hP2(2) = NS_MeanErrPlot(db1Freq, db1Pwr_Av, db1Pwr_SEM, db1Color);
        legend(hP2, {'Random', 'Pulses'})
        ylabel('Power (dB)'); xlabel('Frequency (Hz)');
        title(sprintf('Power of %s pulses (%d mice)', cBAND{iBnd}, inNMse));
        
    end
end

% Saves the figures
chFigDirName    = chSessionDir;
if ~exist(fullfile('Figure', chFigDirName, 'dir')), mkdir('Figure', chFigDirName); end
savefig(hFIG,fullfile('Figure', chFigDirName, 'Figure'));
NS_SaveFig(fullfile('Figure', chFigDirName), hFIG, cFIGNAME);
% close all