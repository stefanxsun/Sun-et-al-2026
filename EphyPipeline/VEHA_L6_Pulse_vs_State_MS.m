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
sCFG.sPARAM.dbConvWinSec 	= .2; 
sCFG.sPARAM.db1ETAWinSec 	= [-2 5];

%loops through the files
for i = 1:length(sREC)
     try
        VEHA_L6_Pulse_vs_State(sCFG, sREC(i));
     catch ME
 		chSessionName = strcat(sREC(i).chNlxSessionDir, '_', num2str(sREC(i).inRecNum));
 		try, rmdir(fullfile('VEHA_L6_Pulse_vs_State', chSessionName)); end
        getReport(ME)
     end
end

error('INTENTIONAL ERROR');
%%
clear, close all
% run StartupAnalysis
% cd '/media/storage/Quentin/Analyses/GammaChronicProbe';
chSessionDir = 'VEHA_L6_Pulse_vs_State';
chFileName = [chSessionDir '.mat'];
sDIR = dir(chSessionDir);

sINFO = VEHA_DefineINFO();
in1Session  = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR(:).name})));
in1InfoIdx  = VEHA_U_FindSessionIndex(sINFO, {sDIR(in1Session).name});
in1Mouse    = [sINFO.sREC.inMouseID];
in1Mouse    = in1Mouse(in1InfoIdx);
% cDAY        = cellfun(@(x) datestr(x(1:10)), {sINFO.sREC.chNlxSessionDir}, 'UniformOutput', false);
% cDAY        = cDAY(in1InfoIdx);

%Defines a band of interest
cBAND       = {'15-30Hz', '30-80Hz'};
cBND_VAL    = {[15 30], [30 80]};
cSTATE      = {'Stim', 'Running'};
inNBnd 		= length(cBAND);
cTHRESHOLD 	= {'MahalDNorm'};
inNThr 		= length(cTHRESHOLD);

sBAND = struct('db2ETA', cell(inNThr, inNBnd), 'db2ETVar',cell(inNThr, inNBnd), ...
    'in1NEvt', cell(inNThr, inNBnd), 'db1RateIn', cell(inNThr, inNBnd), ...
    'db1RateOut', cell(inNThr, inNBnd));

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
            db1ETA_Time = sLD.sL6.sBAND(1).db1ETA_Time;
            inNSmp 	= length(db1ETA_Time);
            blInit = false;
        else
            if ~NS_CompMat(db1ETA_Time, sLD.sL6.sBAND(1).db1ETA_Time) 
                fprintf('The power parameters are inconsistent in session %s\n', sDIR(iSes).name);
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
            sBAND(iThr, iBnd).db2ETA   		= cat(1, sBAND(iThr, iBnd).db2ETA, sSES_BAND(bl2Band).db1ETA);
            sBAND(iThr, iBnd).db2ETVar      = cat(1, sBAND(iThr, iBnd).db2ETVar, sSES_BAND(bl2Band).db1ETSD .^ 2);
            sBAND(iThr, iBnd).in1NEvt       = cat(1, sBAND(iThr, iBnd).in1NEvt, sSES_BAND(bl2Band).inNEvt);
            sBAND(iThr, iBnd).db1RateIn    	= cat(1, sBAND(iThr, iBnd).db1RateIn, sSES_BAND(bl2Band).dbRateIn);
            sBAND(iThr, iBnd).db1RateOut    = cat(1, sBAND(iThr, iBnd).db1RateOut, sSES_BAND(bl2Band).dbRateOut);
        end, end
    catch ME
        fprintf('\nError loading %s', sDIR(in1Session(iSes)).name)
        getReport(ME)
        in1Error = cat(1, in1Error, iSes);
    end
end

%Remove sessions for which there was an error from the indexing variables
bl1Rem = ismember(in1Session, in1Error);
in1Mouse(bl1Rem)    = [];
% cDAY(bl1Rem)        = [];

%%Plots the plots

fprintf('\nDone!\n');
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
    db2ETA_Mse 	= nan(inNMse, inNSmp);
    
    %Loops over mice
    for iMse = 1:length(in1U_Mse)
        bl1Mse = in1Mouse == in1U_Mse(iMse);
        % Aggregates Saline
        bl1Cond = bl1Mse;
        if ~isempty(bl1Cond)
            db2ETA_Mse(iMse, :)  = ...
                NS_GrandStats(sBAND(iThr, iBnd).db2ETA(bl1Cond, :), ...
                sBAND(iThr, iBnd).db2ETVar(bl1Cond, :), sBAND(iThr, iBnd).in1NEvt(bl1Cond, :), 1);
        end
    end
    
    %Averages power over mice
    db1MeanETA 	= nanmean(db2ETA_Mse, 1);
    db1SEM_ETA 	= sqrt(nanvar(db2ETA_Mse, [], 1)./sum(~isnan(db2ETA_Mse), 1));
    
    %Sets the colors
    if ismember(cBAND{iBnd}, '15-30Hz'), cCOLOR = {[.5 .5 .5], [0 .2 1]};
    elseif ismember(cBAND{iBnd}, '30-80Hz'),  cCOLOR = {[.5 .5 .5], [1 .4 0]};
    else, cCOLOR =   {[.5 .5 .5], [.6 .2 .1]}; end
	
    %Plots the plots
    subplot(1, 3, [1 2])
    NS_MeanErrPlot(db1ETA_Time, db1MeanETA, db1SEM_ETA, cCOLOR{2});
	hold on, plot([0 0], ylim, 'k--');
    ylabel(sprintf('%s Pulse Rate (Hz)', cBAND{iBnd})); xlabel('Frequency (Hz)');
    title(sprintf('%s Pulse Rate vs %s onset (%d mice)', cBAND{iBnd}, cSTATE{iBnd}, inNMse))

    %Aggregates the rate in and out of the state of interest
    db2Rate_Mse 	= nan(inNMse, 2);
    %Loops over mice
    for iMse = 1:length(in1U_Mse)
        bl1Mse = in1Mouse == in1U_Mse(iMse);
        % Aggregates Saline
        bl1Cond = bl1Mse;
        if ~isempty(bl1Cond)
            db2Rate_Mse(iMse, 1)  = mean(sBAND(iThr, iBnd).db1RateOut(bl1Cond));
            db2Rate_Mse(iMse, 2)  = mean(sBAND(iThr, iBnd).db1RateIn(bl1Cond));
        end
    end
	%Formats the rate in and out of pulses
	db1AvRate 	= nanmean(db2Rate_Mse, 1);
	db1SEMRate 	= sqrt(nanvar(db2Rate_Mse, [], 1) ./ sum(~isnan(db2Rate_Mse), 1)); 
	db1YL 		= NS_Plt_Range(db2Rate_Mse);

	%Computes significance
	[h,p,ci(1,:),stats] = ttest(db2Rate_Mse(:, 2), db2Rate_Mse(:, 1));
    o=db1AvRate(2)-db1AvRate(1);
	db1PY = max(db1AvRate + db1SEMRate) + [0.1 0.2] * range(db1YL);
      
    %Plots the rate in and out of pulses
    subplot(1, 3, 3); hold on
	plot([1 2], db2Rate_Mse', 'Color', [.7 .7 .7]);
	errorbar(1, db1AvRate(1), db1SEMRate(1), db1SEMRate(1), 'o', 'Color', cCOLOR{1}, 'LineWidth', 2);
	errorbar(2, db1AvRate(2), db1SEMRate(2), db1SEMRate(2), 'o', 'Color', cCOLOR{2}, 'LineWidth', 2);
	NS_Plt_Sig([1 2], db1PY, p);
	set(gca, 'XTick', [1 2], 'XTickLabel', {cSTATE{iBnd}, 'Quiet'}); xlim([0 3]);
	ylabel(sprintf('%s Pulse Rate (Hz)', cBAND{iBnd})); 
	
end, end

% Saves the figures
chFigDirName    = chSessionDir;
if ~exist(fullfile('Figure', chFigDirName, 'dir')), mkdir('Figure', chFigDirName); end
savefig(hFIG,fullfile('Figure', chFigDirName, 'Figure'));
NS_SaveFig(fullfile('Figure', chFigDirName), hFIG, cFIGNAME);
close all