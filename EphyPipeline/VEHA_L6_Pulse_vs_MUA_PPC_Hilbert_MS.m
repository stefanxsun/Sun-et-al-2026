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
sCFG.sPARAM.cTHRESHOLD 			= {'MahalDNorm'};
sCFG.sPARAM.db1Freq 			= 2:2:120; 
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
        VEHA_L6_Pulse_vs_MUA_PPC_Hilbert(sCFG, sREC(i));
        pause(.1), close all
    catch ME
        getReport(ME)
    end
end

% error('INTENTIONAL ERROR STOP');
%% Aggregates the data accross all sessions to investigates how the units of different layers phase lock to each rythm
clear
chSessionDir = 'VEHA_L6_Pulse_vs_MUA_PPC_Hilbert';
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

cLyr = {'23','4','5','6','ALL'}; 
inNLyr 		= length(cLyr);  
in1Day      = VEHA_U_FindSessionDayNum(sINFO, chSessionDir);   %% Stefan added it

% Defines a band of interest
cBAND       = {'15-30Hz', '30-80Hz'};
cSTATE      = {'Stim', 'Running'};
inNBnd 		= length(cBAND);
cTHRESHOLD 	= {'MahalDNorm'};
inNThr 		= length(cTHRESHOLD);

% Initialzes the output
[bl1Spk_Bas, bl1Spk_Stim, bl1Spk_Run, in1LyrIdx, in1Mouse,in1DayIdx] = deal([]);
sBAND 	= struct('chBandLabel', repmat(cBAND, inNThr, 1), 'chStateLabel', repmat(cSTATE, inNThr, 1), ...
	'chThreshold', repmat(cTHRESHOLD', 1, inNBnd), 'bl1Spk_Pls', cell(inNThr, inNBnd), ... 
	'bl1Exclude', cell(inNThr, inNBnd), 'cp3Spk_STR', cell(inNThr, inNBnd));

% Aggregates the cluster in one simple structure
fprintf('Aggregating Layers ... ') % Communicates with the angry me
for iDir = in1SesDir
    try
        % Loads the session data
        sINP        = load(fullfile(chSessionDir, sDIR(iDir).name, chFileName)); sINP = sINP.sCFG;
        sMUA    = sINP.sL6.sMUA;
        inNLyr      = length(sMUA);
		fprintf('\nSession %s:', sDIR(iDir).name);
        
        %Determines the task and the number of days on that task
        inInfoIdx 	= VEHA_U_FindSessionIndex(sINFO, {sDIR(iDir).name});
		
		%Gets the mouse ID
		inMouseID 	= sINFO.sREC(inInfoIdx).inMouseID;
		
        %Gets the day
        in1SesDay   = in1Day(inInfoIdx); %% Stefan added it
        
		%Gets the conditions of the gratings for the session and determins what indices are considered
		%Full stims
		db2SesCnd 		= sINP.sL6.db2Cond;
% 		in1FullPresIdx 	= find(db2SesCnd(2, :) >= .02 & db2SesCnd(2, :) <= .16 & db2SesCnd(4, :) >= .32 & db2SesCnd(5, :) >= 20);
        in1FullPresIdx 	= find(db2SesCnd(4, :) >= .32);
        % STEFAN edited SF to be >=0.02 because the numbers for later mice are different for 0.04
        
        % Computes the PPC for each band and each cluster and aggregate it
        % in the right bin of the output structure
        for iLyr = 1:inNLyr
            %Gets the number of spikes
            inNSpk 		= length(sMUA(iLyr).bl1SpkBas);
            
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
            
            %Aggregates Layer and cell ID and Days
            in1LyrIdx 		= cat(1, in1LyrIdx, iLyr * ones(inNSpk, 1));
            in1Mouse 		= cat(1, in1Mouse, inMouseID * ones(inNSpk, 1));
            in1DayIdx 		= cat(1, in1DayIdx, in1SesDay * ones(inNSpk, 1));
            
            %Get the band structure for the cluster of interest
            sBND_IN = sMUA(iLyr).sBAND;
            for iThr = 1:inNThr
                for iBnd = 1:inNBnd
                    %Finds the index of the band and threshold of interest
                    bl2Band = ismember({sBND_IN.chBandLabel}, cBAND{iBnd}) & ismember({sBND_IN.chStateLabel}, cSTATE{iBnd}) ...
                        & ismember({sBND_IN.chThreshold}, cTHRESHOLD{iThr});
                    if ~any(bl2Band(:)) | sum(bl2Band(:)) ~= 1 %Adds excluded spikes if the CLAMS band of interest is not found
                        fprintf('\n\t%s - %s Adding %d excluded spikes to %d', cTHRESHOLD{iThr}, cBAND{iBnd}, ...
                            inNSpk, length(sBAND(iThr, iBnd).bl1Spk_Pls));
                        sBAND(iThr, iBnd).bl1Spk_Pls 	= cat(1, sBAND(iThr, iBnd).bl1Spk_Pls, false(inNSpk, 1));
                        sBAND(iThr, iBnd).bl1Exclude 	= cat(1, sBAND(iThr, iBnd).bl1Exclude, true(inNSpk, 1));
                        sBAND(iThr, iBnd).bl1Exclude 	= cat(1, sBAND(iThr, iBnd).cp3SpkSTR, nan(inNSpk, 1, 16));
                        
                    else %Other wise appends spikes and loops for PPC bands
                        fprintf('\n\t%s - %s Adding %d spikes to %d', cTHRESHOLD{iThr}, cBAND{iBnd}, ...
                            inNSpk, length(sBAND(iThr, iBnd).bl1Spk_Pls));
                        sBAND(iThr, iBnd).bl1Spk_Pls 	= cat(1, sBAND(iThr, iBnd).bl1Spk_Pls, ...
                            sBND_IN(bl2Band).bl1Bout');
                        %Aggregate spectro-temporal representation at spike time
                        sBAND(iThr, iBnd).cp3Spk_STR 	= cat(1, sBAND(iThr, iBnd).cp3Spk_STR, sBND_IN(bl2Band).cp3Spk_STR);
                        sBAND(iThr, iBnd).bl1Exclude 	= cat(1, sBAND(iThr, iBnd).bl1Exclude, false(inNSpk, 1));
                        fprintf('\tDone');
                    end
                end 
            end
        end
        
    catch ME
        getReport(ME)
    end
end
fprintf(' Done !\n');
%% Plots the coherence for each layers
clear hFIG cFIGNAME
cLAYER = {'23', '4', '5', '6', 'All'};
iFig    = 0;
cCOND 	= {'Baseline', 'Stimulation', 'Running', 'All'};
inNCnd 	= length(cCOND);

%Loops over LFP bands
for iBnd = 1:inNBnd
    clear hPLT
    
    if iBnd == 1; cCOLOR = {[.5 .5 .5], [0 .2 1]};
    else, cCOLOR =   {[.5 .5 .5], [1 .4 0]}; end
    
    %Extract the spike phase and exclusion vector
    cp3Spk_STR  = sBAND(iThr, iBnd).cp3Spk_STR;
    bl1Exclude 	= sBAND(iThr, iBnd).bl1Exclude;
    bl1Spk_Pls 	= sBAND(iThr, iBnd).bl1Spk_Pls;
    
    %Creates the figure
    iFig = iFig + 1;
    hFIG(iFig) = figure('Position', [100 100 1600 900], 'Visible', blVisible);
    cFIGNAME{iFig} 	= sprintf('PPC_%s_%s_%s', cBAND{iBnd}, cSTATE{iBnd}, ...
        cTHRESHOLD{iThr});
    [inNRow, inNCol] 	= FindPlotNum(inNCnd);
    
    %Loops over Layers
    for iCnd = 1:inNCnd
        %Selects the condition
        if strcmp(cCOND{iCnd}, 'Baseline'), bl1Cnd = bl1Spk_Bas;
        elseif strcmp(cCOND{iCnd}, 'Stimulation'), bl1Cnd = bl1Spk_Stim;
        elseif strcmp(cCOND{iCnd}, 'Running'), bl1Cnd = bl1Spk_Run;
        elseif strcmp(cCOND{iCnd}, 'All'), bl1Cnd = true(size(bl1Spk_Stim));
        end
        
        %Initializes the local plots
        hPLT(iCnd) 	= subplot(inNRow, inNCol, iCnd); hold on
        
        %Initializes aggregate variables
        [db1PPC, in1NClu, db1PPC_Var, db1PPC_O, in1NClu_O, db1PPC_Var_O] = deal(nan(1, inNLyr));
        
        %Loops over Layers
        for iLyr = 1:inNLyr
            %Select the layer
            bl1Lyr 		= ismember(in1LyrIdx, iLyr);
            %Selects spikes that were in our out of pulse
            bl1In 	= bl1Lyr & bl1Cnd & bl1Spk_Pls & ~bl1Exclude;
            bl1Out 	= bl1Lyr & bl1Cnd & ~bl1Spk_Pls & ~bl1Exclude;
            
            %Computes the average PPC coherence for each layer and estimate the variance over cells
            if any(bl1In)
                [db1PPC(iLyr), db1PPC_Var(iLyr)] = NS_PPC_MultiChan(cp3Spk_STR(bl1In, :, :));
                in1NClu(iLyr) 		= 1;
            else
                db1PPC(iLyr) = nan; db1PPC_Var(iLyr) = nan; in1NClu(iLyr) = nan;
            end
            
            if any(bl1Out)
                [db1PPC_O(iLyr), db1PPC_Var_O(iLyr)] = NS_PPC_MultiChan(cp3Spk_STR(bl1Out, :, :));
                in1NClu_O(iLyr) 	= 1;
            else
                db1PPC_O(iLyr) = nan; db1PPC_Var_O(iLyr) = nan; in1NClu_O(iLyr) = nan;
            end
        end
        db1PPC_SEM 			= sqrt(db1PPC_Var ./ in1NClu);
        db1PPC_SEM_O 		= sqrt(db1PPC_Var_O ./ in1NClu_O);
        
        %Plots the averages
        hLIN(1) = errorbar(1:2:inNLyr * 2 - 1, db1PPC_O, db1PPC_SEM_O, db1PPC_SEM_O, 'o', ...
            'Color', cCOLOR{1}, 'DisplayName', 'Outside Pulses');
        hLIN(2) = errorbar(2:2:inNLyr * 2, db1PPC, db1PPC_SEM, db1PPC_SEM, 'o', ...
            'Color', cCOLOR{2}, 'DisplayName', 'During Pulses');
        
        %Sets levels for the significance plots
        db1Range 	= range([db1PPC + db1PPC_SEM db1PPC - db1PPC_SEM db1PPC_O + db1PPC_SEM_O db1PPC_O - db1PPC_SEM_O]);
        db1Max 		= max([db1PPC + db1PPC_SEM db1PPC - db1PPC_SEM db1PPC_O + db1PPC_SEM_O db1PPC_O - db1PPC_SEM_O]);
        dbYSg 		= db1Max + 0.1 * db1Range;
        
        %Plots significance between coherence in and out of pulses
        for iLyr = 1:inNLyr
            dbP = NS_WelchTest(db1PPC(iLyr), db1PPC_O(iLyr), db1PPC_Var(iLyr), db1PPC_Var_O(iLyr), ...
                in1NClu(iLyr), in1NClu_O(iLyr));
            NS_Plt_Sig(iLyr * 2 + [-1 0], dbYSg + [0 .1] * db1Range, dbP);
        end
        
        % 				%Plots significance between layers within pulses
        % 				dbYSg 		= db1Max + 0.3 * db1Range;
        % 				dbYMx 		= dbYSg;
        % 				for iLyr1 = 1:inNLyr - 1
        % 					for iLyr2 = iLyr1:inNLyr
        % 						dbP = NS_WelchTest(db1PPC(iLyr1), db1PPC(iLyr2), db1PPC_Var(iLyr1), db1PPC_Var(iLyr2), ...
        % 							in1NClu(iLyr1), in1NClu(iLyr2));
        % 						if iLyr2 - iLyr1 == 1,
        % 							db1Y = dbYSg + ([0 .1] * db1Range);
        % 						else
        % 							db1Y 	= dbYMx + ([.2 .3] * db1Range);
        % 							dbYMx 	= dbYMx + (.2 * db1Range);
        % 						end
        % 						NS_Plt_Sig([iLyr1 iLyr2] * 2 , db1Y, dbP);
        % 					end
        % 				end
        
        %Sets Graphs labesl and legends
        ylabel(sprintf('%s Spike-LFP PPC', cBAND{iBnd}));
        set(gca, 'XTick', (2:2:inNLyr * 2) - .5, 'XTickLabel', cLAYER)
        xlim([0 inNLyr * 2 + 1]);
        if iCnd == 1, legend(hLIN, 'Location', 'East'); end
        title(sprintf('%s:', cCOND{iCnd}));
        %linkaxes(hPLT, 'y');
    end % End of the Hilbert band loop
end
%% Saves the figures
chFigDir = fullfile('Figure', chSessionDir); if ~exist(chFigDir, 'dir'); mkdir('Figure', chSessionDir); end
chFigDir2 	= fullfile(chFigDir, 'Layer_Averages'); if ~exist(chFigDir2, 'dir'); mkdir(chFigDir, 'Layer_Averages'); end
% savefig(hFIG, fullfile(chFigDir2, 'Pool_Figures'));
NS_SaveFig(chFigDir2, hFIG, cFIGNAME)
close all

%% Plots the coherence for each layers each days
clear hFIG cFIGNAME
cLAYER = {'23', '4', '5', '6', 'All'};
iFig    = 0;
cCOND 	= {'Baseline', 'Stimulation', 'Running', 'All'};
inNCnd 	= length(cCOND);

%Loops over LFP bands
for iBnd = 1:inNBnd
    for iDay = 1:max(in1Day)
    clear hPLT
    
    if iBnd == 1; cCOLOR = {[.5 .5 .5], [0 .2 1]};
    else, cCOLOR =   {[.5 .5 .5], [1 .4 0]}; end
    
    %Extract the spike phase and exclusion vector
    cp3Spk_STR  = sBAND(iThr, iBnd).cp3Spk_STR;
    bl1Exclude 	= sBAND(iThr, iBnd).bl1Exclude;
    bl1Spk_Pls 	= sBAND(iThr, iBnd).bl1Spk_Pls;
    
    %Creates the figure
    iFig = iFig + 1;
    hFIG(iFig) = figure('Position', [100 100 1600 900], 'Visible', blVisible);
    cFIGNAME{iFig} 	= sprintf('PPC_%s_%s_%s', cBAND{iBnd}, cSTATE{iBnd}, ...
        cTHRESHOLD{iThr});
    [inNRow, inNCol] 	= FindPlotNum(inNCnd);
    
    %Loops over Layers
    for iCnd = 1:inNCnd
        %Selects the condition
        if strcmp(cCOND{iCnd}, 'Baseline'), bl1Cnd = bl1Spk_Bas;
        elseif strcmp(cCOND{iCnd}, 'Stimulation'), bl1Cnd = bl1Spk_Stim;
        elseif strcmp(cCOND{iCnd}, 'Running'), bl1Cnd = bl1Spk_Run;
        elseif strcmp(cCOND{iCnd}, 'All'), bl1Cnd = true(size(bl1Spk_Stim));
        end
        
        %Initializes the local plots
        hPLT(iCnd) 	= subplot(inNRow, inNCol, iCnd); hold on
        
        %Initializes aggregate variables
        [db1PPC, in1NClu, db1PPC_Var, db1PPC_O, in1NClu_O, db1PPC_Var_O] = deal(nan(1, inNLyr));
        
        %Loops over Layers
        for iLyr = 1:inNLyr
            %Select the layer
            bl1Lyr 		= ismember(in1LyrIdx, iLyr);
            
            %Select the day
            bl1Day 		= ismember(in1DayIdx, iDay);
            
            %Selects spikes that were in our out of pulse
            bl1In 	= bl1Lyr & bl1Cnd & bl1Day & bl1Spk_Pls & ~bl1Exclude;
            bl1Out 	= bl1Lyr & bl1Cnd & bl1Day & ~bl1Spk_Pls & ~bl1Exclude;
            
            %Computes the average PPC coherence for each layer and estimate the variance over cells
            if any(bl1In)
                [db1PPC(iLyr), db1PPC_Var(iLyr)] = NS_PPC_MultiChan(cp3Spk_STR(bl1In, :, :));
                in1NClu(iLyr) 		= 1;
            else
                db1PPC(iLyr) = nan; db1PPC_Var(iLyr) = nan; in1NClu(iLyr) = nan;
            end
            
            if any(bl1Out)
                [db1PPC_O(iLyr), db1PPC_Var_O(iLyr)] = NS_PPC_MultiChan(cp3Spk_STR(bl1Out, :, :));
                in1NClu_O(iLyr) 	= 1;
            else
                db1PPC_O(iLyr) = nan; db1PPC_Var_O(iLyr) = nan; in1NClu_O(iLyr) = nan;
            end
        end
        db1PPC_SEM 			= sqrt(db1PPC_Var ./ in1NClu);
        db1PPC_SEM_O 		= sqrt(db1PPC_Var_O ./ in1NClu_O);
        
        %Plots the averages
        hLIN(1) = errorbar(1:2:inNLyr * 2 - 1, db1PPC_O, db1PPC_SEM_O, db1PPC_SEM_O, 'o', ...
            'Color', cCOLOR{1}, 'DisplayName', 'Outside Pulses');
        hLIN(2) = errorbar(2:2:inNLyr * 2, db1PPC, db1PPC_SEM, db1PPC_SEM, 'o', ...
            'Color', cCOLOR{2}, 'DisplayName', 'During Pulses');
        
        %Sets levels for the significance plots
        db1Range 	= range([db1PPC + db1PPC_SEM db1PPC - db1PPC_SEM db1PPC_O + db1PPC_SEM_O db1PPC_O - db1PPC_SEM_O]);
        db1Max 		= max([db1PPC + db1PPC_SEM db1PPC - db1PPC_SEM db1PPC_O + db1PPC_SEM_O db1PPC_O - db1PPC_SEM_O]);
        dbYSg 		= db1Max + 0.1 * db1Range;
        
        %Plots significance between coherence in and out of pulses
        for iLyr = 1:inNLyr
            dbP = NS_WelchTest(db1PPC(iLyr), db1PPC_O(iLyr), db1PPC_Var(iLyr), db1PPC_Var_O(iLyr), ...
                in1NClu(iLyr), in1NClu_O(iLyr));
            NS_Plt_Sig(iLyr * 2 + [-1 0], dbYSg + [0 .1] * db1Range, dbP);
        end
        
        % 				%Plots significance between layers within pulses
        % 				dbYSg 		= db1Max + 0.3 * db1Range;
        % 				dbYMx 		= dbYSg;
        % 				for iLyr1 = 1:inNLyr - 1
        % 					for iLyr2 = iLyr1:inNLyr
        % 						dbP = NS_WelchTest(db1PPC(iLyr1), db1PPC(iLyr2), db1PPC_Var(iLyr1), db1PPC_Var(iLyr2), ...
        % 							in1NClu(iLyr1), in1NClu(iLyr2));
        % 						if iLyr2 - iLyr1 == 1,
        % 							db1Y = dbYSg + ([0 .1] * db1Range);
        % 						else
        % 							db1Y 	= dbYMx + ([.2 .3] * db1Range);
        % 							dbYMx 	= dbYMx + (.2 * db1Range);
        % 						end
        % 						NS_Plt_Sig([iLyr1 iLyr2] * 2 , db1Y, dbP);
        % 					end
        % 				end
        
        %Sets Graphs labesl and legends
        ylabel(sprintf('%s Spike-LFP PPC', cBAND{iBnd}));
        set(gca, 'XTick', (2:2:inNLyr * 2) - .5, 'XTickLabel', cLAYER)
        xlim([0 inNLyr * 2 + 1]);
        if iCnd == 1, legend(hLIN, 'Location', 'East'); end
        title(sprintf('%s:', cCOND{iCnd}));
        %linkaxes(hPLT, 'y');
    end % End of the Hilbert band loop
    end
    sgtitle(sprintf('Day %d', iDay))
end

%% Plots the coherence for all the days each layers
clear hFIG cFIGNAME
close all
cLAYER = {'23', '4', '5', '6', 'All'};
iFig    = 0;
cCOND 	= {'Baseline', 'Stimulation', 'Running', 'All'};
inNCnd 	= length(cCOND);

%Loops over LFP bands
for iBnd = 1:inNBnd
    
    if iBnd == 1; cCOLOR = {[.5 .5 .5], [0 .2 1]};
    else, cCOLOR =   {[.5 .5 .5], [1 .4 0]}; end
    
    %Extract the spike phase and exclusion vector
    cp3Spk_STR  = sBAND(iBnd).cp3Spk_STR;
    bl1Exclude 	= sBAND(iBnd).bl1Exclude;
    bl1Spk_Pls 	= sBAND(iBnd).bl1Spk_Pls;
    
    %Loops over Layers
    for iLyr = 1:inNLyr
        %Creates the figure
        clear hPLT
        iFig = iFig + 1;
        hFIG(iFig) = figure('Position', [100 100 1600 900], 'Visible', blVisible);
        cFIGNAME{iFig} 	= sprintf('PPC_%s_%s_%s_Layer%s', cBAND{iBnd}, cSTATE{iBnd}, ...
            cTHRESHOLD{1}, cLAYER{iLyr});
        [inNRow, inNCol] 	= FindPlotNum(inNCnd);
        
        %Loops over condition
        for iCnd = 1:inNCnd
            %Selects the condition
            if strcmp(cCOND{iCnd}, 'Baseline'), bl1Cnd = bl1Spk_Bas;
            elseif strcmp(cCOND{iCnd}, 'Stimulation'), bl1Cnd = bl1Spk_Stim;
            elseif strcmp(cCOND{iCnd}, 'Running'), bl1Cnd = bl1Spk_Run;
            elseif strcmp(cCOND{iCnd}, 'All'), bl1Cnd = true(size(bl1Spk_Stim));
            end
            
            %Initializes the local plots
            hPLT(iCnd) 	= subplot(inNRow, inNCol, iCnd); hold on
            
            %Initializes aggregate variables
            [db1PPC, in1NClu, db1PPC_Var, db1PPC_O, in1NClu_O, db1PPC_Var_O] = deal(nan(1, max(in1Day)));
            
            for iDay = 1:max(in1Day)
                %Select the layer
                bl1Lyr 		= ismember(in1LyrIdx, iLyr);
                
                %Select the day
                bl1Day 		= ismember(in1DayIdx, iDay);
                
                %Selects spikes that were in our out of pulse
                bl1In 	= bl1Lyr & bl1Cnd & bl1Day & bl1Spk_Pls & ~bl1Exclude;
                bl1Out 	= bl1Lyr & bl1Cnd & bl1Day & ~bl1Spk_Pls & ~bl1Exclude;
                
                %Computes the average PPC coherence for each layer and estimate the variance over cells
                if any(bl1In)
                    [db1PPC(iDay), db1PPC_Var(iDay)] = NS_PPC_MultiChan(cp3Spk_STR(bl1In, :, :));
%                     [db1PPC(iDay), db1PPC_Var(iDay)] = NS_PPC_MultiChan(cp3Spk_STR(bl1In, :, :), in1Mouse(bl1In));

                    in1NClu(iDay) 		= 1;
                else
                    db1PPC(iDay) = nan; db1PPC_Var(iDay) = nan; in1NClu(iDay) = nan;
                end
                
                if any(bl1Out)
                    [db1PPC_O(iDay), db1PPC_Var_O(iDay)] = NS_PPC_MultiChan(cp3Spk_STR(bl1Out, :, :));
%                     [db1PPC_O(iDay), db1PPC_Var_O(iDay)] = NS_PPC_MultiChan(cp3Spk_STR(bl1Out, :, :), in1Mouse(bl1Out));

                    in1NClu_O(iDay) 	= 1;
                else
                    db1PPC_O(iDay) = nan; db1PPC_Var_O(iDay) = nan; in1NClu_O(iDay) = nan;
                end
            end
            db1PPC_SEM 			= sqrt(db1PPC_Var ./ in1NClu);
            db1PPC_SEM_O 		= sqrt(db1PPC_Var_O ./ in1NClu_O);
            
            %Plots the averages
            hLIN(1) = errorbar((1:max(in1Day))-0.1, db1PPC_O, db1PPC_SEM_O, db1PPC_SEM_O, 'o', ...
                'Color', cCOLOR{1}, 'DisplayName', 'Outside Pulses');
            hLIN(2) = errorbar(1:max(in1Day), db1PPC, db1PPC_SEM, db1PPC_SEM, 'o', ...
                'Color', cCOLOR{2}, 'DisplayName', 'During Pulses');
            
            %Sets levels for the significance plots
            db1Range 	= range([db1PPC + db1PPC_SEM db1PPC - db1PPC_SEM db1PPC_O + db1PPC_SEM_O db1PPC_O - db1PPC_SEM_O]);
            db1Max 		= max([db1PPC + db1PPC_SEM db1PPC - db1PPC_SEM db1PPC_O + db1PPC_SEM_O db1PPC_O - db1PPC_SEM_O]);
            dbYSg 		= db1Max + 0.1 * db1Range;
            
            %Plots significance between coherence in and out of pulses
            %             for iLyr = 1:inNLyr
            %                 dbP = NS_WelchTest(db1PPC(iLyr), db1PPC_O(iLyr), db1PPC_Var(iLyr), db1PPC_Var_O(iLyr), ...
            %                     in1NClu(iLyr), in1NClu_O(iLyr));
            %                 NS_Plt_Sig(iLyr * 2 + [-1 0], dbYSg + [0 .1] * db1Range, dbP);
            %             end
            
            % 				%Plots significance between layers within pulses
            % 				dbYSg 		= db1Max + 0.3 * db1Range;
            % 				dbYMx 		= dbYSg;
            % 				for iLyr1 = 1:inNLyr - 1
            % 					for iLyr2 = iLyr1:inNLyr
            % 						dbP = NS_WelchTest(db1PPC(iLyr1), db1PPC(iLyr2), db1PPC_Var(iLyr1), db1PPC_Var(iLyr2), ...
            % 							in1NClu(iLyr1), in1NClu(iLyr2));
            % 						if iLyr2 - iLyr1 == 1,
            % 							db1Y = dbYSg + ([0 .1] * db1Range);
            % 						else
            % 							db1Y 	= dbYMx + ([.2 .3] * db1Range);
            % 							dbYMx 	= dbYMx + (.2 * db1Range);
            % 						end
            % 						NS_Plt_Sig([iLyr1 iLyr2] * 2 , db1Y, dbP);
            % 					end
            % 				end
            
            %Sets Graphs labesl and legends
            ylabel(sprintf('%s Spike-LFP PPC', cBAND{iBnd}));
%             set(gca, 'XTick', 1:max(in1Day), 'XTickLabel', cLAYER)
            xlim([0.5 max(in1Day)]);
            if iCnd == 1, legend(hLIN, 'Location', 'East'); end
            title(sprintf('%s:', cCOND{iCnd}));
            %linkaxes(hPLT, 'y');
        end % End of the Hilbert band loop
        sgtitle(sprintf('Layer %s', cLAYER{iLyr}))
    end
end
%% Saves the figures
chFigDir3 	= fullfile(chFigDir, 'LayersAndDays'); if ~exist(chFigDir3, 'dir'); mkdir(chFigDir, 'LayersAndDays'); end
NS_SaveFig(chFigDir3, hFIG, cFIGNAME)
close all
