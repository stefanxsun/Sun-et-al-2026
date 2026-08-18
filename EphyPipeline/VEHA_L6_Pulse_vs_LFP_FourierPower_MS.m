clear
% run StartupAnalysis.m
% cd '/media/storage/Quentin/Analyses/GammaChronicProbe';

%Adds the CLAMS codes to the path
% addpath(genpath('/media/storage/Quentin/Scripts/Matlab/gamma_bouts'))

%Defines the info file
sINFO   = VEHA_DefineINFO();
sREC    = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite     = true;
sCFG.sPARAM.cTHRESHOLD      = {'MahalDNorm'};
sCFG.sPARAM.dbWinLenSec     = .5;
sCFG.sPARAM.inNStep         = 4;
sCFG.sPARAM.inTopFreq       = 120;
sCFG.sPARAM.blPlot          = false;
sCFG.sPARAM.blVisible       = false;

%loops through the files
parfor i = 1:length(sREC)
     try
        VEHA_L6_Pulse_vs_LFP_FourierPower(sCFG, sREC(i));
     catch ME
 		chSessionName = strcat(sREC(i).chNlxSessionDir, '_', num2str(sREC(i).inRecNum));
 		try, rmdir(fullfile('VEHA_L6_Pulse_vs_LFP_FourierPower', chSessionName)); end
        getReport(ME)
     end
end

error('INTENTIONAL ERROR');
%%
clear, close all
run StartupAnalysis.m
cd '/media/storage/Quentin/Analyses/GammaChronicProbe';
chSessionDir = 'VEHA_L6_Pulse_vs_LFP_FourierPower';
chFileName = [chSessionDir '.mat'];
sDIR = dir(chSessionDir);

sINFO = VEHA_DefineINFO();
in1Session  = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR(:).name})));
in1InfoIdx  = VEHA_U_FindSessionIndex(sINFO, {sDIR(in1Session).name});
in1Mouse    = [sINFO.sREC.inMouseID];
in1Mouse    = in1Mouse(in1InfoIdx);
cDAY        = cellfun(@(x) datestr(x(1:10)), {sINFO.sREC.chNlxSessionDir}, 'UniformOutput', false);
cDAY        = cDAY(in1InfoIdx);

%Defines a band of interest
cBAND       = {'15-30Hz', '30-80Hz'};
cBND_VAL    = {[15 30], [30 80]};
cSTATE      = {'Stim', 'Running'};
inNBnd 		= length(cBAND);
cTHRESHOLD 	= {'MahalDNorm'};
inNThr 		= length(cTHRESHOLD);

sBAND = struct('db180pct', cell(inNThr, inNBnd), 'in1NChnk80plus',cell(inNThr, inNBnd), ...
    'db2MeanPwr_80plus', cell(inNThr, inNBnd), 'db2VarPwr_plus', cell(inNThr, inNBnd), ...
    'in1NChnk80min', cell(inNThr, inNBnd), 'db2MeanPwr_80min', cell(inNThr, inNBnd), ...
    'db2VarPwr_80min', cell(inNThr, inNBnd));

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
            db1Freq = sLD.sL6.db1Freq;
            inNFreq = length(db1Freq);
            blInit = false;
        else
            if ~NS_CompMat(db1Freq, sLD.sL6.db1Freq) 
                fprintf('The power parameters are inconsistent in session %s\r', sDIR(iSes).name);
                continue
            end
        end
         
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
            sBAND(iThr, iBnd).db180pct            = cat(1, sBAND(iThr, iBnd).db180pct, sSES_BAND(bl2Band).db80pct);
            sBAND(iThr, iBnd).in1NChnk80plus      = cat(1, sBAND(iThr, iBnd).in1NChnk80plus, sSES_BAND(bl2Band).inNChnk_80plus);
            sBAND(iThr, iBnd).db2MeanPwr_80plus   = cat(1, sBAND(iThr, iBnd).db2MeanPwr_80plus, sSES_BAND(bl2Band).db1MeanPwr_80plus);
            sBAND(iThr, iBnd).db2VarPwr_plus      = cat(1, sBAND(iThr, iBnd).db2VarPwr_plus, sSES_BAND(bl2Band).db1SEMPwr_80plus .^ 2 .* sSES_BAND(bl2Band).inNChnk_80plus);
            sBAND(iThr, iBnd).in1NChnk80min       = cat(1, sBAND(iThr, iBnd).in1NChnk80min, sSES_BAND(bl2Band).inNChnk_80min);
            sBAND(iThr, iBnd).db2MeanPwr_80min    = cat(1, sBAND(iThr, iBnd).db2MeanPwr_80min, sSES_BAND(bl2Band).db1MeanPwr_80min);
            sBAND(iThr, iBnd).db2VarPwr_80min     = cat(1, sBAND(iThr, iBnd).db2VarPwr_80min, sSES_BAND(bl2Band).db1SEMPwr_80min .^ 2 .* sSES_BAND(bl2Band).inNChnk_80min);
        end, end
    catch ME
        fprintf('\rError loading %s', sDIR(in1Session(iSes)).name)
        getReport(ME)
        in1Error = cat(1, in1Error, iSes);
    end
end

%Remove sessions for which there was an error from the indexing variables
bl1Rem = ismember(in1Session, in1Error);
in1Mouse(bl1Rem)    = [];
cDAY(bl1Rem)        = [];

%%Plots the plots

fprintf('\rDone!\r');
%% Averages and plots the data
clear hFIG
iFig = 0;

%Averages conditions over session for each individual mouse
in1U_Mse 		= unique(in1Mouse);
inNMse 			= length(in1U_Mse);

%Loops through bands in ses band
for iBnd = 1:inNBnd, for iThr = 1:inNThr
    
    %Initializes the figure
    iFig = iFig + 1;
    hFIG(iFig)      = figure('Position', [50 50 1250 600]);
    cFIGNAME{iFig}  = sprintf('%s', cBAND{iBnd}); 
    
    %Aggregates the Power
    [db2PwrPlus_Mse, db2PwrMin_Mse] 	= deal(nan(inNMse, inNFreq));
    
    %Loops over mice
    for iMse = 1:length(in1U_Mse)
        bl1Mse = in1Mouse == in1U_Mse(iMse);
        % Aggregates Saline
        bl1Cond = bl1Mse;
        if ~isempty(bl1Cond)
            db2PwrPlus_Mse(iMse, :)  = ...
                NS_GrandStats(sBAND(iThr, iBnd).db2MeanPwr_80plus(bl1Cond, :), ...
                sBAND(iThr, iBnd).db2VarPwr_plus(bl1Cond, :), sBAND(iThr, iBnd).in1NChnk80plus(bl1Cond, :), 1);
            db2PwrMin_Mse(iMse, :)  = ...
                NS_GrandStats(sBAND(iThr, iBnd).db2MeanPwr_80min(bl1Cond, :), ...
                sBAND(iThr, iBnd).db2VarPwr_80min(bl1Cond, :), sBAND(iThr, iBnd).in1NChnk80min(bl1Cond, :), 1);
        end
    end
    
    %Averages power over mice
    db1MeanPwr_80plus   = nanmean(db2PwrPlus_Mse, 1);
    db1SEMPwr_80plus    = sqrt(nanvar(db2PwrPlus_Mse, [], 1)./sum(~isnan(db2PwrPlus_Mse), 1));
    db1MeanPwr_80min    = nanmean(db2PwrMin_Mse, 1);
    db1SEMPwr_80min     = sqrt(nanvar(db2PwrMin_Mse, [], 1)./sum(~isnan(db2PwrMin_Mse), 1));
    
    %Calculates significance
    db1P    = nan(1, inNFreq);   for iFrq = 1:inNFreq, [~, db1P(iFrq)] = ttest(db2PwrPlus_Mse(:, iFrq), db2PwrMin_Mse(:, iFrq)); end
    bl1Sig  = logical(fdr_bh(db1P));
    
    %Sets the colors
    if ismember(cBAND{iBnd}, '15-30Hz'), cCOLOR = {[.5 .5 .5], [0 .2 1]};
    elseif ismember(cBAND{iBnd}, '30-80Hz'),  cCOLOR = {[.5 .5 .5], [1 .4 0]};
    else, cCOLOR =   {[.5 .5 .5], [.6 .2 .1]}; end
    
    %Plots the plots
    subplot(1, 3, [1 2])
    hPLT(1) = NS_MeanErrPlot(db1Freq, db1MeanPwr_80min, db1SEMPwr_80min, cCOLOR{1});
    hPLT(2) = NS_MeanErrPlot(db1Freq, db1MeanPwr_80plus, db1SEMPwr_80plus, cCOLOR{2});
    dbY = -10; db1SigVec = nan(size(db1Freq)); db1SigVec(bl1Sig) = 1;
    hold on, plot(db1Freq, dbY * db1SigVec, 'k', 'LineWidth', 2);
    ylabel('Power (dB)'); xlabel('Frequency (Hz)');
    legend(hPLT, {'<80pct', '>80pct'})
    title(sprintf(' Power vs %s Pulse Rate (%d mice)', cBAND{iBnd}, inNMse))
    
    %Plots a histograme of the 80pct
    subplot(1, 3, 3), hold on
	db180pct 	= sBAND(iThr, iBnd).db180pct;
	dbAv80pct 	= nanmean(db180pct(:), 1); 
	dbSEM80pct 	= sqrt(nanstd(db180pct(:), [], 1) ./ sum(~isnan(db180pct(:)), 1)); 
	plot(1, db180pct(:), 'x', 'Color', [.7 .7 .7]);
	errorbar(1, dbAv80pct, dbSEM80pct, dbSEM80pct, 'o', 'Color', cCOLOR{2}, 'LineWidth', 2)
    ylabel('Rate (Hz)');
    title(sprintf('80 pct rate (%d Sessions)', sum(~isnan(db180pct(:)), 1)));
end, end

% Saves the figures
chFigDirName    = chSessionDir;
if ~exist(fullfile('Figure', chFigDirName, 'dir')), mkdir('Figure', chFigDirName); end
savefig(hFIG,fullfile('Figure', chFigDirName, 'Figure'));
NS_SaveFig(fullfile('Figure', chFigDirName), hFIG, cFIGNAME);
close all
