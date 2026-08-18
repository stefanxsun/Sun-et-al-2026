clear
cd 'E:\Ephy\VisExpHighAll';
%Adds the CLAMS codes to the path
% addpath(genpath('/media/storage/Quentin/Scripts/Matlab/gamma_bouts'))

%Defines the info file
sINFO   = VEHA_DefineINFO();
sREC    = sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory     = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite         = 1;
sCFG.sPARAM.cTHRESHOLD 			= {'MahalDNorm'};
sCFG.sPARAM.db1Freq 			= 2:2:120;
sCFG.sPARAM.inMrltSRate 		= 500;
sCFG.sPARAM.in1SpkRemInt_ms 	= [-1 4];

% %Only computest interesting sessions optional.
% sXTR_INF    = VEHA_U_BuildExtraTskInfo(sINFO);
% in1Compute  = find(ismember({sXTR_INF.chTask}, {'Psych'})  & ... % only keep the mice that ran on psych
%     [sXTR_INF.dbFAR] < .45 & ismember([sXTR_INF.inDayOnBlock], 4:15) & ...
%     [sXTR_INF.inTaskBlock] == 1); % Exclude sessions where the false alarm rate was too hig

%loops through the files
for i = 1:length(sREC)
    % for i = in1Compute
    try
        VEHA_L6_Pulse_vs_MUA_PPCSpectra(sCFG, sREC(i));
        pause(.1), close all
    catch ME
        getReport(ME)
    end
end

% error('INTENTIONAL ERROR STOP');
%% Aggregates the data accross all sessions to investigates how the units of different layers phase lock to each rythm
clear
chSessionDir = 'VEHA_L6_Pulse_vs_MUA_PPCSpectra';
chFileName = [chSessionDir '.mat'];
sDIR = dir(chSessionDir);

%Sets if figure option
blVisible   = 1;
chFigDir    = fullfile('Figure', chSessionDir); if ~exist(chFigDir, 'dir'); mkdir(chFigDir); end

% %Cleans up the session file
for iDir = 3:length(sDIR)
    if ~exist(fullfile(chSessionDir, sDIR(iDir).name, chFileName), 'file')
        blSuccess = rmdir(fullfile(chSessionDir, sDIR(iDir).name));
    end
end

%Find the sessions to be aggregated
sINFO 		= VEHA_DefineINFO();
in1SesDir   = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR.name})));

%Sets the frequency vector <---- change if frequency is changed
db1Freq = 2:2:120;
inNFreq = length(db1Freq);

% Set layers
cLyr = {'23','4','5','6','ALL'};
inNLyr 		= length(cLyr);

% Set session day
in1Day = VEHA_U_FindSessionDayNum(sINFO, chSessionDir);   %% Stefan added it
inNDay = max(in1Day);

% Defines a band of interest
cBAND       = {'15-30Hz', '30-80Hz'};
cSTATE      = {'Stim', 'Running'};
inNBnd 		= length(cBAND);
cTHRESHOLD 	= {'MahalDNorm'};
inNThr 		= length(cTHRESHOLD);

% Initialzes the output
[cp3Spk_STR, bl1Spk_Bas, bl1Spk_Stim, bl1Spk_Run, in1LyrIdx, in1CluTypIdx, in1CluNum, in1Mouse, in1DayIdx] = deal([]);
sBAND 	= struct('chBandLabel', repmat(cBAND, inNThr, 1), 'chStateLabel', repmat(cSTATE, inNThr, 1), ...
    'chThreshold', repmat(cTHRESHOLD', 1, inNBnd), 'bl1Spk_Pls', cell(inNThr, inNBnd), ...
    'bl1Exclude', cell(inNThr, inNBnd));
% inCluNum = 0;

% Aggregates the cluster in one simple structure
fprintf('Aggregating Clusters ... ') % Communicates with the angry me
for iDir = in1SesDir
    try
        % Loads the session data
        sINP    = load(fullfile(chSessionDir, sDIR(iDir).name, chFileName));
        sINP = sINP.sCFG;
        sMUA    = sINP.sL6.sMUA;
        fprintf('\nSession %s:', sDIR(iDir).name);

        %Determines the task and the number of days on that task
        inInfoIdx 	= VEHA_U_FindSessionIndex(sINFO, {sDIR(iDir).name});

        %Gets the mouse ID
        inMouseID 	= sINFO.sREC(inInfoIdx).inMouseID;

        %Gets the day
        inSesDay   = in1Day(inInfoIdx); %% Stefan added it

        %Gets the conditions of the gratings for the session and determins what indices are considered
        %Full stims
        db2SesCnd 		= sINP.sL6.db2Cond;
        % in1FullPresIdx 	= find(db2SesCnd(2, :) >= .02 & db2SesCnd(2, :) <= .16 & db2SesCnd(4, :) >= .32 & db2SesCnd(5, :) >= 20);
        in1FullPresIdx 	= find(db2SesCnd(4, :) >= .32);
        % Computes the PPC for each band and each cluster and aggregate it
        % in the right bin of the output structure
        for iLyr = 1:inNLyr

            %Gets the number of spikes
            inNSpk 		= length(sMUA(iLyr).bl1SpkRun);

            %Extract spike state indices
            db1SesSpkCnd 	= sMUA(iLyr).db1SpkCnd;
            bl1SesSpkBas 	= sMUA(iLyr).bl1SpkBas;
            bl1SesSpkRun 	= sMUA(iLyr).bl1SpkRun;

            %Rearrange state indices in a convenient way
            bl1SesSpkStim 	= ismember(db1SesSpkCnd, in1FullPresIdx);

            %Aggregate states
            bl1Spk_Bas 	= cat(1, bl1Spk_Bas, bl1SesSpkBas');
            bl1Spk_Stim = cat(1, bl1Spk_Stim, bl1SesSpkStim');
            bl1Spk_Run 	= cat(1, bl1Spk_Run, bl1SesSpkRun');

            %Aggregate spectro-temporal representation at spike time
            cp3Spk_STR 	= cat(1, cp3Spk_STR, sMUA(iLyr).cp3SpkSTR);

            %Aggregates Layer and cell ID
            in1LyrIdx 		= cat(1, in1LyrIdx, iLyr * ones(inNSpk, 1));
            in1Mouse 		= cat(1, in1Mouse, inMouseID * ones(inNSpk, 1));
            in1DayIdx 		= cat(1, in1DayIdx, inSesDay * ones(inNSpk, 1));

            %Get the band structure for the cluster of interest
            sBND_IN1 = sMUA(1).sBAND; % this is for all other info except for bl1Bout
            sBND_IN = sMUA(iLyr).sBAND; % this is for bl1Bout
            for iThr = 1:inNThr
                for iBnd = 1:inNBnd
                    %Finds the index of the band and threshold of interest
                    bl2Band = ismember({sBND_IN1.chBandLabel}, cBAND{iBnd}) & ismember({sBND_IN1.chStateLabel}, cSTATE{iBnd}) ...
                        & ismember({sBND_IN1.chThreshold}, cTHRESHOLD{iThr});
                    if ~any(bl2Band(:)) | sum(bl2Band(:)) ~= 1 %Adds excluded spikes if the CLAMS band of interest is not found
                        fprintf('\n\t%s - %s Adding %d excluded spikes to %d', cTHRESHOLD{iThr}, cBAND{iBnd}, ...
                            inNSpk, length(sBAND(iThr, iBnd).bl1Spk_Pls));
                        sBAND(iThr, iBnd).bl1Spk_Pls 	= cat(1, sBAND(iThr, iBnd).bl1Spk_Pls, false(inNSpk, 1));
                        sBAND(iThr, iBnd).bl1Exclude 	= cat(1, sBAND(iThr, iBnd).bl1Exclude, true(inNSpk, 1));
                    else %Other wise appends spikes and loops for PPC bands
                        fprintf('\n\t%s - %s Adding %d spikes to %d', cTHRESHOLD{iThr}, cBAND{iBnd}, ...
                            inNSpk, length(sBAND(iThr, iBnd).bl1Spk_Pls));
                        sBAND(iThr, iBnd).bl1Spk_Pls 	= cat(1, sBAND(iThr, iBnd).bl1Spk_Pls, ...
                            sBND_IN(bl2Band).bl1Bout');

                        %Appends phase
                        fprintf('\tDone');
                        sBAND(iThr, iBnd).bl1Exclude 	= cat(1, sBAND(iThr, iBnd).bl1Exclude, false(inNSpk, 1));
                    end
                end
            end
        end

    catch ME
        getReport(ME)
    end
end
fprintf(' Done !\n');

%% Plots the figures
clear hFIG cFIGNAME
cLAYER = {'23', '4', '5', '6', 'All'};
iFig    = 0;
cCOND 	= {'Baseline', 'Stimulation', 'Running', 'All'};
inNCnd 	= length(cCOND);

% Figure
inNLyr  = length(cLAYER);

%Gets the number of mouses
in1U_Mouse = unique(in1Mouse);

%Sets the number of bins
inNBin 		= 12;
db1BinEdge 	= linspace(0, 2*pi, inNBin + 1);
db1Bin 		= median([db1BinEdge(1:end - 1); db1BinEdge(2:end)]);

%for iMseGp = 1:length(in1U_Mouse) + 1
for iMseGp = length(in1U_Mouse) + 1 % Does only the average accross mice
    if iMseGp <= length(in1U_Mouse)
        chSesAggregate = num2str(in1U_Mouse(iMseGp));
        bl1Mse = in1Mouse == in1U_Mouse(iMseGp);
    else
        chSesAggregate = 'AllMice';
        bl1Mse = true(size(in1Mouse));
    end
    chSubDir   = fullfile(chFigDir, chSesAggregate); if ~exist(chSubDir, 'dir'); mkdir(chSubDir); end

    for iThr = 1:inNThr
        for iBnd = 1:inNBnd
            if iBnd == 1; cCOLOR = {[.5 .5 .5], [0 .2 1]};
            else, cCOLOR =   {[.5 .5 .5], [1 .4 0]}; end

            %Extract the spike phase and exclusion vector
            bl1Exclude 	= sBAND(iThr, iBnd).bl1Exclude;
            bl1Spk_Pls 	= sBAND(iThr, iBnd).bl1Spk_Pls;

            %Creates the figure
            iFig = iFig + 1;
            hFIG(iFig) = figure('Position', [100 100 1600 900], 'Visible', blVisible);
            cFIGNAME{iFig} 	= sprintf('Phase_%s_%s_%s_BasStimRun', cBAND{iBnd}, cSTATE{iBnd}, ...
                cTHRESHOLD{iThr});
            inNRow = inNLyr; inNCol = inNCnd - 1;
            iPlt = 0;

            %Creates the figure
            iFig = iFig + 1;
            hFIG(iFig) = figure('Position', [100 100 1600 900], 'Visible', blVisible);
            cFIGNAME{iFig} 	= sprintf('Phase_%s_%s_%s_All', cBAND{iBnd}, cSTATE{iBnd}, ...
                cTHRESHOLD{iThr});
            [inNRow2, inNCol2] 	= FindPlotNum(inNLyr);
            iPlt2 = 0;
            clear hLIN hPLT hPLT2

            %Loops over layers
            for iLyr = 1:inNLyr
                %Selections the layer of interest
                bl1Lyr = in1LyrIdx == iLyr;

                %Loops over condition
                for iCnd = 1:inNCnd
                    %Selects the condition
                    if strcmp(cCOND{iCnd}, 'Baseline'), bl1Cnd = bl1Spk_Bas;
                    elseif strcmp(cCOND{iCnd}, 'Stimulation'), bl1Cnd = bl1Spk_Stim;
                    elseif strcmp(cCOND{iCnd}, 'Running'), bl1Cnd = bl1Spk_Run;
                    elseif strcmp(cCOND{iCnd}, 'All'), bl1Cnd = true(size(bl1Spk_Stim));
                    end

                    %Selects spikes that were in our out of pulse
                    bl1In 	= bl1Lyr & bl1Cnd &  bl1Spk_Pls & ~bl1Exclude;
                    bl1Out 	= bl1Lyr & bl1Cnd & ~bl1Spk_Pls & ~bl1Exclude;

                    %Computes the average PPC coherence for each layer and estimate the variance over cells
                    if sum(bl1In) > 2
                        [db1PPC, db1PPCVar] = NS_PPC_MultiChan(cp3Spk_STR(bl1In, :, :), in1Mouse(bl1In), 'mean');
                        inNMse = length(unique(in1Mouse(bl1In)));
                        db1PPC_SEM 		= sqrt(db1PPCVar ./  inNMse);
                    else
                        [db1PPC, db1PPC_SEM] = deal(nan(inNFreq, 1));
                    end
                    if sum(bl1Out) > 2
                        [db1PPC_O, db1PPCVar_O] = NS_PPC_MultiChan(cp3Spk_STR(bl1Out, :, :), in1Mouse(bl1Out), 'mean');
                        inNMse = length(unique(in1Mouse(bl1Out)));
                        db1PPC_SEM_O 		= sqrt(db1PPCVar_O ./  inNMse);
                    else
                        [db1PPC_O, db1PPC_SEM_O] = deal(nan(inNFreq, 1));
                    end

                    %Initializes the local plots
                    if iCnd < inNCnd
                        figure(hFIG(iFig - 1));
                        iPlt = iPlt + 1;
                        hPLT(iPlt) = subplot(inNRow, inNCol, iPlt); hold on
                    else
                        figure(hFIG(iFig));
                        iPlt2 = iPlt2 + 1;
                        hPLT2(iPlt2) = subplot(inNRow2, inNCol2, iPlt2); hold on
                    end

                    %Sort out weird values
                    db1PPC(isnan(db1PPC) | ~isfinite(db1PPC)) = 0;
                    db1PPC_SEM(isnan(db1PPC_SEM) | ~isfinite(db1PPC_SEM)) = 0;
                    db1PPC_O(isnan(db1PPC_O) | ~isfinite(db1PPC_O)) = 0;
                    db1PPC_SEM_O(isnan(db1PPC_SEM_O) | ~isfinite(db1PPC_SEM_O)) = 0;

                    %Plot the the phase histograms
                    hLIN(1) = NS_MeanErrPlot(db1Freq, db1PPC, db1PPC_SEM, cCOLOR{2});
                    hLIN(2) = NS_MeanErrPlot(db1Freq, db1PPC_O, db1PPC_SEM_O, cCOLOR{1});
                    ylabel('PPC'), xlabel('Frequency (Hz)')
                    title(sprintf('%s %s', strrep(cLAYER{iLyr}, '_', ' '), cCOND{iCnd}));
                    if iLyr == 1, legend(hLIN, {'In', 'Out'}); end
                end
            end
            warning off, linkaxes(hPLT, 'x'); linkaxes(hPLT2, 'x'); warning on
        end

    end

    %Saves the figure
    NS_SaveFig(chSubDir, hFIG, cFIGNAME);
    close all
end
%% Plot spectra over days
clear hFIG cFIGNAME
cLAYER = {'23', '4', '5', '6', 'All'};
iFig    = 0;
cCOND 	= {'Baseline', 'Stimulation', 'Running', 'All'};
inNCnd 	= length(cCOND);

% Figure
inNLyr  = length(cLAYER);

%Gets the number of mouses
in1U_Mouse = unique(in1Mouse);

%Sets the number of bins
inNBin 		= 12;
db1BinEdge 	= linspace(0, 2*pi, inNBin + 1);
db1Bin 		= median([db1BinEdge(1:end - 1); db1BinEdge(2:end)]);

%for iMseGp = 1:length(in1U_Mouse) + 1
for iMseGp = length(in1U_Mouse) + 1 % Does only the average accross mice
    if iMseGp <= length(in1U_Mouse)
        chSesAggregate = num2str(in1U_Mouse(iMseGp));
        bl1Mse = in1Mouse == in1U_Mouse(iMseGp);
    else
        chSesAggregate = 'AllMice';
        bl1Mse = true(size(in1Mouse));
    end
    chSubDir   = fullfile(chFigDir, chSesAggregate); if ~exist(chSubDir, 'dir'); mkdir(chSubDir); end

    for iThr = 1:inNThr
        for iBnd = 1:inNBnd

            %Opens a Stat File in the output figure dir
            chStatFile = sprintf('Stat_%s_%s.txt', cBAND{iBnd}, cTHRESHOLD{iThr});
            hFID = fopen(fullfile(chSubDir, chStatFile), 'w');

            if iBnd == 1; cCOLOR = {[.5 .5 .5], [0 .2 1]};
            else, cCOLOR =   {[.5 .5 .5], [1 .4 0]}; end

            %Extract the spike phase and exclusion vector
            bl1Exclude 	= sBAND(iThr, iBnd).bl1Exclude;
            bl1Spk_Pls 	= sBAND(iThr, iBnd).bl1Spk_Pls;

            %Creates the figure
            iFig = iFig + 1;
            hFIG(iFig) = figure('Position', [100 100 1600 900], 'Visible', blVisible);
            cFIGNAME{iFig} 	= sprintf('Phase_%s_%s_%s_d1-d7_BasStimRun', cBAND{iBnd}, cSTATE{iBnd}, ...
                cTHRESHOLD{iThr});
            inNRow = inNLyr; inNCol = inNCnd - 1;
            cSIG = {};
            iPlt = 0;

            %Creates the figure
            iFig = iFig + 1;
            hFIG(iFig) = figure('Position', [100 100 1600 900], 'Visible', blVisible);
            cFIGNAME{iFig} 	= sprintf('Phase_%s_%s_%s_d1_d7_All', cBAND{iBnd}, cSTATE{iBnd}, ...
                cTHRESHOLD{iThr});
            [inNRow2, inNCol2] 	= FindPlotNum(inNLyr);
            cSIG2 = {};
            iPlt2 = 0;
            clear hLIN hPLT hPLT2

            %Loops over layers
            for iLyr = 1:inNLyr
                %Selections the layer of interest
                bl1Lyr = in1LyrIdx == iLyr;

                %Loops over condition
                for iCnd = 1:inNCnd
                    %Selects the condition
                    if strcmp(cCOND{iCnd}, 'Baseline'), bl1Cnd = bl1Spk_Bas;
                    elseif strcmp(cCOND{iCnd}, 'Stimulation'), bl1Cnd = bl1Spk_Stim;
                    elseif strcmp(cCOND{iCnd}, 'Running'), bl1Cnd = bl1Spk_Run;
                    elseif strcmp(cCOND{iCnd}, 'All'), bl1Cnd = true(size(bl1Spk_Stim));
                    end

                    %Initializes the local plots
                    if iCnd < inNCnd
                        figure(hFIG(iFig - 1));
                        iPlt = iPlt + 1;
                        hPLT(iPlt) = subplot(inNRow, inNCol, iPlt); hold on
                    else
                        figure(hFIG(iFig));
                        iPlt2 = iPlt2 + 1;
                        hPLT2(iPlt2) = subplot(inNRow2, inNCol2, iPlt2); hold on
                    end

                    %Loops over days
                    for iDay = [1 inNDay]
                        %Select the day of interest
                        bl1Day = in1DayIdx == iDay;

                        %Selects spikes that were in our out of pulse
                        bl1In 	= bl1Lyr & bl1Cnd &  bl1Spk_Pls & bl1Day & ~bl1Exclude;

                        %Computes the average PPC coherence for each layer and estimate the variance over cells
                        if sum(bl1In) > 2
                            [db1PPC, db1PPCVar] = NS_PPC_MultiChan(cp3Spk_STR(bl1In, :, :), in1Mouse(bl1In), 'mean');
                            inNMse = length(unique(in1Mouse(bl1In)));
                            db1PPC_SEM 		= sqrt(db1PPCVar ./  inNMse);
                        else
                            [db1PPC, db1PPC_SEM] = deal(nan(inNFreq, 1));
                        end
                        if iDay == 1
                            db1PPC_Fst = db1PPC;
                            db1PPCVar_Fst = db1PPCVar;
                            inNMse_Fst = inNMse;
                        elseif iDay == inNDay
                            db1PPC_Lst = db1PPC;
                            db1PPCVar_Lst = db1PPCVar;
                            inNMse_Lst = inNMse;
                        end

                        %Sort out weird values
                        db1PPC(isnan(db1PPC) | ~isfinite(db1PPC)) = 0;
                        db1PPC_SEM(isnan(db1PPC_SEM) | ~isfinite(db1PPC_SEM)) = 0;

                        %Plot the the phase histograms
                        hLIN(iLyr) = NS_MeanErrPlot(db1Freq, db1PPC, db1PPC_SEM, cCOLOR{2} * iDay ./ inNDay);
                        ylabel('PPC'), xlabel('Frequency (Hz)')
                        title(sprintf('%s %s', strrep(cLAYER{iLyr}, '_', ' '), cCOND{iCnd}));
                        if iCnd == inNCnd & iLyr == inNLyr
                            legend(hLIN, {sprintf('d%d', 1) sprintf('d%d', inNDay)})
                        end
                           
                        % Calculate significance
                        if iDay == inNDay
                            bl1Sig = fdr_bh(NS_WelchTest(db1PPC_Fst(:)', db1PPC_Lst(:)', db1PPCVar_Fst(:)', db1PPCVar_Lst(:)', inNMse_Fst, inNMse_Lst));
                            bl1Sig(isnan(bl1Sig)) = 0; bl1Sig = logical(bl1Sig);
                            in1Sig 	= nan(size(bl1Sig));
                            in1Sig(logical(bl1Sig)) = 1;
                            if iCnd < inNCnd, cSIG{iPlt} = in1Sig;
                            else, cSIG2{iPlt2} = in1Sig; end

                            %Print the significance in the stat file
                            fprintf('L%s %s:Significant at Freq (Hz) (fdr corrected Welch t-test, n First = %d, n Last = %d):', ...
                                cLAYER{iLyr}, cCOND{iCnd}, inNMse_Fst, inNMse_Lst);
                            fprintf(hFID, 'L%s %s:Significant at Freq (Hz) (fdr corrected Welch t-test, n First = %d, n Last = %d):', ...
                                cLAYER{iLyr}, cCOND{iCnd}, inNMse_Fst, inNMse_Lst);
                            [in1On, in1Off]	= NS_FindONnOFFPoints(bl1Sig);
                            if isempty(in1On)
                                fprintf('None\n');
                                fprintf(hFID, 'None\n');
                            else
                                db1SigFreq = db1Freq(bl1Sig);
                                for iFq = 1:length(in1On); fprintf('[%d %d] ', db1Freq(in1On(iFq)), db1Freq(in1Off(iFq))); end; fprintf('\n');
                                for iFq = 1:length(in1On); fprintf(hFID, '[%d %d] ', db1Freq(in1On(iFq)), db1Freq(in1Off(iFq))); end; fprintf(hFID, '\n');
                            end
                        end
                    end
                end
            end
            figure(hFIG(iFig - 1));
            warning off, linkaxes(hPLT); warning on
            % Plots the zeros line and sets the ylim
            for iPlt = 1:iPlt
                subplot(hPLT(iPlt)); hold on
                db1YL = ylim;
                dbYSig = db1YL(2) - .05 * range(db1YL);
                plot(db1Freq, cSIG{iPlt} * dbYSig, 'k', 'LineWidth', 2);
                try, ylim(db1YL), end
            end
            figure(hFIG(iFig));
            warning off, linkaxes(hPLT2); warning on
            for iPlt2 = 1:iPlt2
                subplot(hPLT2(iPlt2)); hold on
                db1YL = ylim;
                dbYSig = db1YL(2) - .05 * range(db1YL);
                plot(db1Freq, cSIG2{iPlt2} * dbYSig, 'k', 'LineWidth', 2);
                try, ylim(db1YL), end
            end
        end
    end

    %Saves the figure
    chSubDir   = fullfile(chFigDir, chSesAggregate); if ~exist(chSubDir, 'dir'); mkdir(chSubDir); end
    NS_SaveFig(chSubDir, hFIG, cFIGNAME);
    close all
end