clear
% run StartupAnalysis
% cd '/media/storage/Quentin/Analyses/GammaChronicProbe';

%Defines the info file
sINFO = VEHA_DefineINFO();
sREC = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = 1;
sCFG.sPARAM.blPlot = true; % Recomanded just to see if it works fine

%loops through the files
for i = 1:length(sREC)
    try
        VEHA_L5_FourierPower(sCFG, sREC(i));
        pause(.2), close all;
    catch ME
        getReport(ME)
    end
end
%%
clear, close all
% run StartupAnalysis
% cd '/media/storage/Quentin/Analyses/GammaChronicProbe';
chSessionDir = 'VEHA_L5_FourierPower';
chFileName = [chSessionDir '.mat'];
sDIR = dir(chSessionDir);

sINFO = VEHA_DefineINFO();
in1Session  = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR(:).name})));
in1InfoIdx  = VEHA_U_FindSessionIndex(sINFO, {sDIR(in1Session).name});
in1Mouse    = [sINFO.sREC.inMouseID];
in1Mouse    = in1Mouse(in1InfoIdx);
% cDAY        = cellfun(@(x) datestr(x(1:10)), {sINFO.sREC.chNlxSessionDir}, 'UniformOutput', false);
% cDAY        = cDAY(in1InfoIdx);

[in1NChunkRun, db2MeanPwr_Run, db2VarPwr_Run, in1NChunkPres, db2MeanPwr_Pres, db2VarPwr_Pres, ...
    in1NChunkQuiet, db2MeanPwr_Quiet, db2VarPwr_Quiet] = deal([]);

% Aggregates the data
fprintf('Aggregating data... ')
blInit = true;
%Loops over sessions
for iSes = in1Session
    try
        % Loads the session data
        sLD = load(fullfile(chSessionDir, sDIR(iSes).name, chFileName)); % loads the file
        sLD = sLD.sCFG;
        
        % Initialize power paramters and checks for their consistency
        % across sessions
        if blInit
            dbWinLenSec = sLD.sPARAM.dbWinLenSec;
            inTopFreq   = sLD.sPARAM.inTopFreq;
            blInit = false;
        else
            if dbWinLenSec ~= sLD.sPARAM.dbWinLenSec | inTopFreq  ~= sLD.sPARAM.inTopFreq
                fprintf('The power parameters are inconsistent in session %s\r', sDIR(iSes).name);
                continue
            end
        end
        % Aggregates power for wanted conditions
        in1NChunkRun        = cat(1, in1NChunkRun, sLD.sL5FP.inNChunkRun);
        db2MeanPwr_Run      = cat(1, db2MeanPwr_Run, sLD.sL5FP.db1MeanPwr_Run);
        db2VarPwr_Run       = cat(1, db2VarPwr_Run, sLD.sL5FP.db1SEMPwr_Run .^ 2 * sLD.sL5FP.inNChunkRun);
        in1NChunkPres       = cat(1, in1NChunkPres, sLD.sL5FP.inNChunkPres);
        db2MeanPwr_Pres     = cat(1, db2MeanPwr_Pres, sLD.sL5FP.db1MeanPwr_Pres);
        db2VarPwr_Pres      = cat(1, db2VarPwr_Pres, sLD.sL5FP.db1SEMPwr_Pres .^ 2 * sLD.sL5FP.inNChunkPres);
        in1NChunkQuiet      = cat(1, in1NChunkQuiet, sLD.sL5FP.inNChunkQuiet);
        db2MeanPwr_Quiet    = cat(1, db2MeanPwr_Quiet, sLD.sL5FP.db1MeanPwr_Quiet);
        db2VarPwr_Quiet     = cat(1, db2VarPwr_Quiet, sLD.sL5FP.db1SEMPwr_Quiet .^ 2 * sLD.sL5FP.inNChunkQuiet);
    catch ME
        fprintf('\rError loading %s', sDIR(in1Session(iSes)).name)
        getReport(ME)
    end
end

fprintf('\rDone!\r');
%% Averages and plots the data
clear hFIG

%Averages conditions over session for each individual mouse
in1U_Mse = unique(in1Mouse);
[db2MeanPwr_Quiet_Sal, db2VarPwr_Quiet_Sal, ...
    db2MeanPwr_Run_Sal, db2VarPwr_Run_Sal, ...
    db2MeanPwr_Pres_Sal, db2VarPwr_Pres_Sal, ...
    ] = deal(nan(length(in1U_Mse), size(db2MeanPwr_Quiet, 2)));

%Loops over mice
for iMse = 1:length(in1U_Mse)
    bl1Mse = in1Mouse == in1U_Mse(iMse);
    % Aggregates Saline
    bl1Cond = bl1Mse;
    if ~isempty(bl1Cond)
        [db2MeanPwr_Quiet_Sal(iMse, :), db2VarPwr_Quiet_Sal(iMse, :)] = ...
            NS_GrandStats(db2MeanPwr_Quiet(bl1Cond, :), db2VarPwr_Quiet(bl1Cond, :), in1NChunkQuiet(bl1Cond), 1);
        db2VarPwr_Quiet_Sal(iMse, :) = db2VarPwr_Quiet_Sal(iMse, :) ./ sum(in1NChunkQuiet(bl1Cond));
        
        [db2MeanPwr_Run_Sal(iMse, :), db2VarPwr_Run_Sal(iMse, :)] = ...
            NS_GrandStats(db2MeanPwr_Run(bl1Cond, :), db2VarPwr_Run(bl1Cond, :), in1NChunkRun(bl1Cond), 1);
        db2VarPwr_Run_Sal(iMse, :) = db2VarPwr_Run_Sal(iMse, :) ./ sum(in1NChunkRun(bl1Cond));
        
        [db2MeanPwr_Pres_Sal(iMse, :), db2VarPwr_Pres_Sal(iMse, :)] = ...
            NS_GrandStats(db2MeanPwr_Pres(bl1Cond, :), db2VarPwr_Pres(bl1Cond, :), in1NChunkPres(bl1Cond), 1);
        db2VarPwr_Pres_Sal(iMse, :) = db2VarPwr_Pres_Sal(iMse, :) ./ sum(in1NChunkPres(bl1Cond));
    end
end

%Computes the mean and SD over mice
db1MeanPwr_Quiet_Sal    = nanmean(db2MeanPwr_Quiet_Sal, 1);
db1SEMPwr_Quiet_Sal     = sqrt(nanvar(db2MeanPwr_Quiet_Sal, [], 1)./nansum(~isnan(db2MeanPwr_Quiet_Sal), 1));
db1MeanPwr_Run_Sal      = nanmean(db2MeanPwr_Run_Sal, 1);
db1SEMPwr_Run_Sal       = sqrt(nanvar(db2MeanPwr_Run_Sal, [], 1)./nansum(~isnan(db2MeanPwr_Run_Sal), 1));
db1MeanPwr_Pres_Sal     = nanmean(db2MeanPwr_Pres_Sal, 1);
db1SEMPwr_Pres_Sal      = sqrt(nanvar(db2MeanPwr_Pres_Sal, [], 1)./nansum(~isnan(db2MeanPwr_Pres_Sal), 1));

%Computes significance
db1Freq = 0:1/dbWinLenSec:inTopFreq;
inNFrq  = length(db1Freq);
db1PRun     = nan(1, inNFrq);   for iFrq = 1:inNFrq, [~, db1PRun(iFrq)] = ttest(db2MeanPwr_Quiet_Sal(:, iFrq), db2MeanPwr_Run_Sal(:, iFrq)); end
bl1Sig_Run  = logical(fdr_bh(db1PRun));
db1Ptim     = nan(1, inNFrq);  for iFrq = 1:inNFrq, [~, db1Ptim(iFrq)] = ttest(db2MeanPwr_Quiet_Sal(:, iFrq), db2MeanPwr_Pres_Sal(:, iFrq)); end
bl1Sig_Stim = logical(fdr_bh(db1Ptim));

%Initializes figure variables
cCOLOR  = {[.5 .5 .5], [1 .4 0], [0 .2 1]};
db1XF   = [db1Freq db1Freq(end:-1:1)];

cFIGNAME    = {'Power_Stim_Run_sit'};
hFIG        = figure('Position', [100 100 1600 900]);

% Plots Quiet vs Running
hAX(1)  = subplot(1, 2, 1); hold on
db1Y    = db1MeanPwr_Quiet_Sal;
db1YF   = [db1MeanPwr_Quiet_Sal + db1SEMPwr_Quiet_Sal db1MeanPwr_Quiet_Sal(end:-1:1) - db1SEMPwr_Quiet_Sal(end:-1:1)];
fill(db1XF, db1YF, cCOLOR{1}, 'LineStyle', 'none', 'FaceAlpha', .3);
hPLT(1) = plot(db1Freq, db1Y, 'color', cCOLOR{1});
db1Y    = db1MeanPwr_Run_Sal;
db1YF   = [db1MeanPwr_Run_Sal + db1SEMPwr_Run_Sal db1MeanPwr_Run_Sal(end:-1:1) - db1SEMPwr_Run_Sal(end:-1:1)];
fill(db1XF, db1YF, cCOLOR{2}, 'LineStyle', 'none', 'FaceAlpha', .3);
hPLT(2) = plot(db1Freq, db1Y, 'color', cCOLOR{2});
dbY = -10; db1SigVec = nan(size(db1Freq)); db1SigVec(bl1Sig_Run) = 1;
plot(db1Freq, dbY * db1SigVec, 'k', 'LineWidth', 2);  
ylabel('Power (dB)'); xlabel('Frequency (Hz)');
legend(hPLT, {'Quiet' 'Running'})

% Plots Quiet vs Stim
hAX(1)  = subplot(1, 2, 2); hold on
db1Y    = db1MeanPwr_Quiet_Sal;
db1YF   = [db1MeanPwr_Quiet_Sal + db1SEMPwr_Quiet_Sal db1MeanPwr_Quiet_Sal(end:-1:1) - db1SEMPwr_Quiet_Sal(end:-1:1)];
fill(db1XF, db1YF, cCOLOR{1}, 'LineStyle', 'none', 'FaceAlpha', .3);
hPLT(1) = plot(db1Freq, db1Y, 'color', cCOLOR{1});
db1Y    = db1MeanPwr_Pres_Sal;
db1YF   = [db1MeanPwr_Pres_Sal + db1SEMPwr_Pres_Sal db1MeanPwr_Pres_Sal(end:-1:1) - db1SEMPwr_Pres_Sal(end:-1:1)];
fill(db1XF, db1YF, cCOLOR{3}, 'LineStyle', 'none', 'FaceAlpha', .3);
hPLT(2) = plot(db1Freq, db1Y, 'color', cCOLOR{3});
dbY = -10; db1SigVec = nan(size(db1Freq)); db1SigVec(bl1Sig_Stim) = 1;
plot(db1Freq, dbY * db1SigVec, 'k', 'LineWidth', 2);
ylabel('Power (dB)'); xlabel('Frequency (Hz)');
legend(hPLT, {'Quiet' 'Stim'})
title(sprintf('Average Power (Mean +/- S.E.M.; N = %d mice)', length(in1U_Mse)));

%% Saves the figures
chFigDirName = [chSessionDir, 'Stim_Run_sit'];
if ~exist(fullfile('Figure', chFigDirName, 'dir')), mkdir('Figure', chFigDirName); end
savefig(hFIG,fullfile('Figure', chFigDirName, 'Figure'));

NS_SaveFig(fullfile('Figure', chFigDirName), hFIG, cFIGNAME);
%%
close all
