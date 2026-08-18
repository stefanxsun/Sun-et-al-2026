clear, close all
cd 'E:\Ephy\VisExpHighAll';
%Sets output directory
chOutDir    = 'VEHA_L6_Pulse_vs_LFP_Example';
chOutPath   = fullfile('Figure', chOutDir); if ~exist(chOutPath, 'dir'); mkdir('Figure', chOutDir); end 

%Sets the example session name 
chSessionName   = 'ss0110_d231018_1';

%Sets the path to the wanted files
chSourcePath_1 = 'VEHA_L4_MakeMetaDataStructure';
chMDSFile = 'VEHA_L4_MakeMetaDataStructure.mat';
chSourcePath_2 = 'VEHA_L5_GetPulse';
chGPFile = 'VEHA_L5_GetPulse.mat';
chSourcePath_3 = 'VEHA_L2_MatchStimLogWithPresentationSet';
chSLPFile = 'VEHA_L2_MatchStimLogWithPresentationSet';
%Loads the input
%-------------------------------------------------------------------------------------------------------
sINPUT_1 = load(fullfile(chSourcePath_1, chSessionName, chMDSFile), '-mat'); sINPUT_1 = sINPUT_1.sCFG;
sINPUT_2 = load(fullfile(chSourcePath_2, chSessionName, chGPFile), '-mat'); sINPUT_2 = sINPUT_2.sCFG;
sINPUT_3 = load(fullfile(chSourcePath_3, chSessionName, chSLPFile), '-mat'); sINPUT_3 = sINPUT_3.sCFG;
%% Extracts the input

%Get the sample rate and LFP
inSampleRate = sINPUT_1.sL4MMDS.inWorkSampleRate;
db2LFP = sINPUT_1.sL4MMDS.db2LFP;
db2LFP = PCP_U_NormalizeLFP(db2LFP, inSampleRate, 2:size(db2LFP, 1));

%Extract the band structure
sBND_IN 	= sINPUT_2.sL5.sBAND;
inNBnd 		= length(sBND_IN);

%Gets the reference channel used for CLAMS
inRefChan   = sINPUT_2.sL5.inRefChan - 1;

%Extracts states
db1TStamps = sINPUT_1.sL4MMDS.db1TStamps;
sGRAT = sINPUT_3.sL2MSLPS.sSTIMLOG.sGRATING ;
for iSet = 1:length(sGRAT)
    in1PresOnIdx       = NS_GetTStampEventIndex(db1TStamps, sGRAT(iSet).db1PresOnTStamp);
    in1PresOffIdx      = NS_GetTStampEventIndex(db1TStamps, sGRAT(iSet).db1PresOffTStamp);
end
bl1Stim     = NS_MakeEpochVector(in1PresOnIdx, in1PresOffIdx, length(db1TStamps));
bl1Run 		= sINPUT_1.sL4MMDS.bl1WheelOn;

%% Plots the figure
%Initializes plot counter if needed
iFig = 0;

% Loops through trials and bands and aggregates the pulse data for each
% band
for iBnd = 1:inNBnd
    %Extracts state labels
    chBandLabel 	= sBND_IN(iBnd).chBandLabel;
    db1Band         = sBND_IN(iBnd).db1Band;
    chStateLabel    = sBND_IN(iBnd).chStateLabel;
    
    %Extracts input variables
    in1Index 		= sBND_IN(iBnd).in1Index;
    db1Score 		= sBND_IN(iBnd).db1Score;
    db1Score_Rnd 	= sBND_IN(iBnd).db1Score_Rnd;
    
    % Gets the threshold
    dbScoreThreshold = sBND_IN(iBnd).dbThreshold;
    
    %Gets the state of interest
    if strcmp(chStateLabel, 'Stim'), bl1State = bl1Stim;
    elseif strcmp(chStateLabel, 'Running'), bl1State = bl1Run;
    else, error('State non recognized'); end
    
    %Computes index vectors for pulse (P) and trough out of pulse (TO)
    in1PulseIdx = in1Index(db1Score > dbScoreThreshold);
    
    %Setsthe state transition index as a function of the band
    if ismember(chBandLabel, '15-30Hz'), inStONIdx =140;     %%% Manually choose one vis stim trial!!!
    elseif ismember(chBandLabel, '30-80Hz'),  inStONIdx = 24;
    else, inStONIdx = 5; end
    
    % Sets parameters for plotting the trough
    in1StateON  = 1 + find(~bl1State(1:end - 1) & bl1State(2:end));
    inAnchor    = in1StateON(inStONIdx);
    if ismember(chBandLabel, '15-30Hz'),  db1WinSec  = [-.8 .7] * round(50 ./ median(db1Band), 2);
    elseif ismember(chBandLabel, '30-80Hz'), db1WinSec  = [-8 8] * round(50 ./ median(db1Band), 2);
    end
    
    %Sets the time vectors
    in1RelIdx  = round(inSampleRate * db1WinSec(1)): round(inSampleRate .* db1WinSec(2));
    in1Sel     = in1RelIdx + inAnchor;
    db1Time    = in1RelIdx ./ inSampleRate;

    %Sets the parameters of the short-time Fourier Transform
    dbWinLenSec     = .5;
    inTopFreq       = 120;
	dbCLimFact 		= 0.2; %<----------------------------------------------- Edit to change color scale

    % Initializizes the figure
    iFig            = iFig + 1;
    hFIG(iFig)      = figure('Position', [100 100 1700 900]);
    cFIG_NAME(iFig) = {[chSessionName '_' chBandLabel '_ShortTimeFourier_' num2str(dbCLimFact * 100) 'pct']};
    
    %Plots the reference channel
    subplot(4, 1, 1), hold on
    hP1(1) = plot(db1Time, db2LFP(inRefChan, in1Sel), 'r', 'DisplayName', 'RefChan');
    db1YL = ylim;
    db1State = nan(size(db1Time)); db1State(bl1State(in1Sel)) = db1YL(1);
    hP1(2) = plot(db1Time, db1State, ...
        'k', 'LineWidth', 2, 'DisplayName', chStateLabel);
    legend(hP1)
    xlim(db1Time([1 end]));
    xlabel('Time (s)'), ylabel('Field (A.U.)');
    
    %Calculates the short time Fourier transform of the LFP in the
		%Recalculates the window to take the loss on the side into account	
    db1WSecPwr  = db1WinSec + ([-.5 .5] .* dbWinLenSec);
    in1RfIdxPwr = round(inSampleRate * db1WSecPwr(1)): round(inSampleRate .* db1WSecPwr(2));
    in1SelPwr   = in1RfIdxPwr + inAnchor;
    db1TimePwr  = in1RfIdxPwr ./ inSampleRate;
    [db2Power, in1CntrIdx] = NS_FourierPower(db2LFP(inRefChan, in1SelPwr), inSampleRate, dbWinLenSec, 50);
    db1Freq 	= 0 : 1/dbWinLenSec : inTopFreq;
    in1FreqIdx 	= 1:inTopFreq * dbWinLenSec + 1;
    
    subplot(4, 1, [2 4]);
%     imagesc(db1TimePwr(in1CntrIdx), db1Freq, 10 * log10(db1Freq' .* db2Power(in1FreqIdx, :)));
%     imagesc(db1TimePwr(in1CntrIdx), db1Freq, 10 * log10(db2Power(in1FreqIdx, :)));
    imagesc(db1TimePwr(in1CntrIdx), db1Freq, db1Freq' .* db2Power(in1FreqIdx, :)); colorbar
	db1CLim = get(gca, 'CLim');
	db1CLim(2) = dbCLimFact .* range(db1CLim) + db1CLim(1);
	set(gca, 'CLim', db1CLim, 'YDir', 'reverse');
	xlabel('Time (s)'), ylabel('Frequency (Hz)');
    
    % Plot 2 --- LFP examples
        % Sets parameters for plotting the trough
    in1StateON  = 1 + find(~bl1State(1:end - 1) & bl1State(2:end));
    inAnchor    = in1StateON(inStONIdx);
    db1WinSec1  = [-.8 .7] * round(50 ./ median(db1Band), 2);
    db1WinSec2  = [-.4 .6] * round(13 ./ median(db1Band), 2);
    
    %Sets the time vectors
    in1RelIdx1  = round(inSampleRate * db1WinSec1(1)): round(inSampleRate .* db1WinSec1(2));
    in1Sel1     = in1RelIdx1 + inAnchor;
    db1Time1    = in1RelIdx1 ./ inSampleRate;
    in1RelIdx2  = round(inSampleRate * db1WinSec2(1)): round(inSampleRate .* db1WinSec2(2));
    in1Sel2     = in1RelIdx2 + inAnchor;
    db1Time2    = in1RelIdx2 ./ inSampleRate;

    %Sets the color scheme as a function of the band
    if ismember(chBandLabel, '15-30Hz'), cCOLOR = {[.5 .5 .5], [0 .2 1]};
    elseif ismember(chBandLabel, '30-80Hz'),  cCOLOR = {[.5 .5 .5], [1 .4 0]};
    else, cCOLOR =   {[.5 .5 .5], [.6 .2 .1]}; end
    
    % Initializizes the figure
    iFig            = iFig + 1;
    hFIG(iFig)      = figure('Position', [100 100 1700 900]);
    cFIG_NAME(iFig) = {[chSessionName '_' chBandLabel]};

    %Plots the wanted chunk of the LFP, the state and an inset for the
    %second selection
    subplot(2, 2, 1);
    db1YL = NS_PlotLFP(db2LFP(:, in1Sel1), db1Time1);
    hold on, hP1(1) = plot(db1Time1(bl1State(in1Sel1)), db1YL(1) .* ones(1, sum(bl1State(in1Sel1))), ...
        'k', 'LineWidth', 2, 'DisplayName', chStateLabel);
    db1SqrX     = db1Time2([1 end end 1 1]);
    db1SqrY     = 0.95 * (db1YL([1 1 2 2 1]) - mean(db1YL)) + mean(db1YL);
    hP1(2) = plot(db1SqrX, db1SqrY, '--k', 'LineWidth' , 1, 'DisplayName', 'Inset');
    legend(hP1); title('LFP'); xlim(db1Time1([1 end]));
    
    %Plots event enrichment Filters the LFP
    [B, A] = butter(2, 2 * db1Band / inSampleRate);
    db2_Filt_LFP = filtfilt(B, A, db2LFP')'; %The LFP is transposed because filtfilt and hilbert opperates over rows
    
    %Plots the filtered LFP
    subplot(2, 2, 2);
    db1YL = NS_PlotLFP(db2_Filt_LFP(:, in1Sel2), db1Time2);
    %Appends the reference channel
    inNChan     = size(db2_Filt_LFP, 1);
    dbScale     = db1YL(2) ./ (inNChan + 1.5);
    hP2(1) = plot(db1Time2, (dbScale * (inNChan - inRefChan + 1)) + db2_Filt_LFP(inRefChan, in1Sel2), 'r', 'DisplayName', 'Ref');
    %Appends the troughs
    in1T_Sel    = in1Index(ismember(in1Index, in1Sel2)) - in1Sel2(1) + 1;
    if ~isempty(in1T_Sel)
        hP2(2) = plot([1 1] * db1Time2(in1T_Sel(1)), db1YL, '--', 'Color', cCOLOR{1}, 'DisplayName', 'Trough');
        for iPls = 2:length(in1T_Sel)
            plot([1 1] * db1Time2(in1T_Sel(iPls)), db1YL, '--', 'Color', cCOLOR{1})
        end
    end
    xlim(db1Time2([1 end]));
    legend(hP2); title(sprintf('%s Filtered LFP (inset)', chBandLabel));
        
    %Plots the filtered LFP
    subplot(2, 2, 3);
    db1YL = NS_PlotLFP(db2_Filt_LFP(:, in1Sel2), db1Time2);
    %Appends the pulses
    in1P_Sel    = in1PulseIdx(ismember(in1PulseIdx, in1Sel2)) - in1Sel2(1) + 1;
    if ~isempty(in1P_Sel)
        hP3 = plot([1 1] * db1Time2(in1P_Sel(1)), db1YL, '--', 'Color', cCOLOR{2}, 'DisplayName', sprintf('%s pulse', chBandLabel));
        for iPls = 2:length(in1P_Sel)
            plot([1 1] * db1Time2(in1P_Sel(iPls)), db1YL, '--', 'Color', cCOLOR{2})
        end
    end
    xlim(db1Time2([1 end]));
    legend(hP3); title(sprintf('%s Pulse Selection', chBandLabel));
    
    %Plots the wanted chunk of the LFP, the state and the troughs
    subplot(2, 2, 4);
    db1YL = NS_PlotLFP(db2LFP(:, in1Sel1), db1Time1);
    db1State = nan(size(db1Time)); db1State(bl1State(in1Sel1)) = db1YL(1);
    hold on, hP4(1) = plot(db1Time, db1State, ...
        'k', 'LineWidth', 2, 'DisplayName', chStateLabel);
    %Appends the troughs
    in1P_Sel    = in1PulseIdx(ismember(in1PulseIdx, in1Sel1)) - in1Sel1(1) + 1;
    if ~isempty(in1P_Sel)
        hP4(2) = plot([1 1] * db1Time1(in1P_Sel(1)), db1YL, '--', 'Color', cCOLOR{2}, 'DisplayName', sprintf('%s pulse', chBandLabel));
        for iPls = 2:length(in1P_Sel)
            plot([1 1] * db1Time1(in1P_Sel(iPls)), db1YL, '--', 'Color', cCOLOR{2})
        end
    end
    xlim(db1Time1([1 end]));
    legend(hP4); title(sprintf('LFP and %s Pulses', chBandLabel));
end

%% Saves the figure
cd 'E:\Ephy\VisExpHighAll\';

%Sets output directory
chOutDir    = 'VEHA_Plot_Pulse_vs_LFP_Example';
chOutPath   = fullfile('Figure', chOutDir); if ~exist(chOutPath, 'dir'); mkdir('Figure', chOutDir); end 
NS_SaveFig(chOutPath, hFIG, cFIG_NAME);
close all
