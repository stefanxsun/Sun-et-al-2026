clear
%
%Defines the info file
sINFO 	= VEHA_DefineINFO();
sREC 	= sINFO.sREC;

%Defines the parameters
sCFG.sPARAM.chBaseDirectory     = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite         = 1;
sCFG.sPARAM.cTHRESHOLD          = {'MahalDNorm'}; %Thresholds for the score
sCFG.sPARAM.inNBin          	= 20;
sCFG.sPARAM.inNCycle          	= 2;

%loops through the files
for i = 1:length(sREC)
    try
        VEHA_L6_Pulse_vs_MUA_ETA(sCFG, sREC(i));
    catch ME
        getReport(ME)
    end
end

%error('INTENTIONAL SCRIPT STOP');
%% Aggregates the data accross the sessions and do plots
clear, close all
chSessionDir    = 'VEHA_L6_Pulse_vs_MUA_ETA';
chFileName      = [chSessionDir '.mat'];
sDIR            = dir(chSessionDir);

%Sets if figure option
blVisible   = false;
chFigDir    = fullfile('Figure', chSessionDir); if ~exist(chFigDir, 'dir'); mkdir(chFigDir); end

% %Cleans up the session file
for iDir = 3:length(sDIR)
    if ~exist(fullfile(chSessionDir, sDIR(iDir).name, chFileName), 'file')
        blSuccess = rmdir(fullfile(chSessionDir, sDIR(iDir).name));
    end
end

%Defines info and the supplementary informations
sINFO       = VEHA_DefineINFO();
in1SesDir   = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR.name})));
in1Day      = VEHA_U_FindSessionDayNum(sINFO, chSessionDir);
% Defines bands and thresholds
cBAND       = {'15-30Hz', '30-80Hz'};
cSTATE      = {'Stim', 'Running'};
inNBnd 		= length(cBAND);
cTHRESHOLD 	= {'MahalDNorm'};
inNThr 		= length(cTHRESHOLD);

%Sets conditions
cCOND 	= {'Baseline', 'Stimulation', 'Running', 'All Conditions'};
inNCnd 	= length(cCOND);

% Initializes aggregation variables
clear sETA sBAND
sETA 	= struct('chBand', repmat(cBAND', 1, inNCnd), ...
    'db2ETA_H_In', cell(inNBnd, inNCnd), 'db2ETA_H_Out', cell(inNBnd, inNCnd), 'db2ETA_H_Rnd', cell(inNBnd, inNCnd),...
    'db2Spk_H_In', cell(inNBnd, inNCnd), 'db2Spk_H_Out', cell(inNBnd, inNCnd), 'db2Spk_H_Rnd', cell(inNBnd, inNCnd),...
    'db2ETA_H_Nrm_In', cell(inNBnd, inNCnd), 'db2ETA_H_Nrm_Out', cell(inNBnd, inNCnd), 'db2ETA_H_Nrm_Rnd', cell(inNBnd, inNCnd), ...
    'in1NEvt_In', cell(inNBnd, inNCnd), 'in1NEvt_Out', cell(inNBnd, inNCnd), 'in1NEvt_Rnd', cell(inNBnd, inNCnd),...
    'in1SesDay', cell(inNBnd, inNCnd), 'in1Mouse', cell(inNBnd, inNCnd), 'layerIdx', cell(inNBnd, inNCnd));

fprintf('Loading data... ');
%Loops through file and aggregates CSD
blInit = true;

for iDir = in1SesDir
    %Loads the file
    try
        sINP    = load(fullfile(chSessionDir, sDIR(iDir).name, chFileName));
        sMUA = sINP.sCFG.sL6.sMUA;
        if isempty(sMUA), continue; end
        
        %Initializes time reference for ETAs for each band and threshold
        if blInit
            cHTIME = cell(inNBnd, inNThr);
            for iBnd = 1:inNBnd
                for iThr = 1:inNThr
                    sBAND = sMUA.sBAND;
                    bl2Band = ismember({sBAND.chBandLabel}, cBAND{iBnd}) & ismember({sBAND.chStateLabel}, cSTATE{iBnd}) ...
                        & ismember({sBAND.chThreshold}, cTHRESHOLD{iThr});
                    cHTIME{iThr, iBnd} = sBAND(bl2Band).db1ETA_H_Time;
                end
            end
        end
        
        %Gets the mouse ID
        inInfoIdx 	= VEHA_U_FindSessionIndex(sINFO, {sDIR(iDir).name});
        inMouseID 	= sINFO.sREC(inInfoIdx).inMouseID;
        in1SesDay   = in1Day(inInfoIdx);
        
        %Loops over band and threshold
        %Get the band structure for the cluster of interest
        sBAND = sMUA.sBAND;
        for iBnd = 1:inNBnd
            
            %Finds the band of interest and copy the corresponding ETA structure
            bl2Band = ismember({sBAND.chBandLabel}, cBAND{iBnd}) & ismember({sBAND.chStateLabel}, cSTATE{iBnd}) ...
                & ismember({sBAND.chThreshold}, cTHRESHOLD{1});
            if ~any(bl2Band(:)), continue; end
            if sum(bl2Band(:)) ~= 1, continue; end
            
            %Loops over conditions
            for iCnd = 1:inNCnd
                sETA(iBnd, iCnd).db2Spk_H_In    	= cat(1, sETA(iBnd, iCnd).db2Spk_H_In, sBAND(bl2Band).sCOND(iCnd).db1Spk_H_In);
                sETA(iBnd, iCnd).db2ETA_H_In     	= cat(1, sETA(iBnd, iCnd).db2ETA_H_In, sBAND(bl2Band).sCOND(iCnd).db1ETA_H_In);
                sETA(iBnd, iCnd).db2ETA_H_Nrm_In 	= cat(1, sETA(iBnd, iCnd).db2ETA_H_Nrm_In, sBAND(bl2Band).sCOND(iCnd).db1ETA_H_Nrm_In);
                sETA(iBnd, iCnd).in1NEvt_In       	= cat(1, sETA(iBnd, iCnd).in1NEvt_In, repmat(sBAND(bl2Band).sCOND(iCnd).inNEvt_In,5,1));
                sETA(iBnd, iCnd).db2Spk_H_Out    	= cat(1, sETA(iBnd, iCnd).db2Spk_H_Out, sBAND(bl2Band).sCOND(iCnd).db1Spk_H_Out);
                sETA(iBnd, iCnd).db2ETA_H_Out     	= cat(1, sETA(iBnd, iCnd).db2ETA_H_Out, sBAND(bl2Band).sCOND(iCnd).db1ETA_H_Out);
                sETA(iBnd, iCnd).db2ETA_H_Nrm_Out 	= cat(1, sETA(iBnd, iCnd).db2ETA_H_Nrm_Out, sBAND(bl2Band).sCOND(iCnd).db1ETA_H_Nrm_Out);
                sETA(iBnd, iCnd).in1NEvt_Out       	= cat(1, sETA(iBnd, iCnd).in1NEvt_Out, repmat(sBAND(bl2Band).sCOND(iCnd).inNEvt_Out,5,1));
                sETA(iBnd, iCnd).db2Spk_H_Rnd    	= cat(1, sETA(iBnd, iCnd).db2Spk_H_Rnd, sBAND(bl2Band).sCOND(iCnd).db1Spk_H_Rnd);
                sETA(iBnd, iCnd).db2ETA_H_Rnd     	= cat(1, sETA(iBnd, iCnd).db2ETA_H_Rnd, sBAND(bl2Band).sCOND(iCnd).db1ETA_H_Rnd);
                sETA(iBnd, iCnd).db2ETA_H_Nrm_Rnd 	= cat(1, sETA(iBnd, iCnd).db2ETA_H_Nrm_Rnd, sBAND(bl2Band).sCOND(iCnd).db1ETA_H_Nrm_Rnd);
                sETA(iBnd, iCnd).in1NEvt_Rnd       	= cat(1, sETA(iBnd, iCnd).in1NEvt_Rnd, repmat(sBAND(bl2Band).sCOND(iCnd).inNEvt_Rnd,5,1));
                sETA(iBnd, iCnd).in1Mouse    		= cat(1, sETA(iBnd, iCnd).in1Mouse, repmat(inMouseID,5,1));
                sETA(iBnd, iCnd).in1SesDay    		= cat(1, sETA(iBnd, iCnd).in1SesDay, repmat(in1SesDay,5,1));
                sETA(iBnd, iCnd).layerIdx    		= cat(1, sETA(iBnd, iCnd).layerIdx, [1:5]');
            end
        end
        
    catch ME
        getReport(ME)
        continue
    end
end
fprintf('Ready\r');

%%
%Plots the figures  (over layers)
%Adds a condition that pools all layers %Stefan edited
cLAYER = ["Layer 2/3"; "Layer 4"; "Layer 5"; "Layer 6"; "All_Layers"];
inNLyr = 5;
%Gets the number of mouses
in1U_Mouse = unique(cat(1, sETA(:, :, :).in1Mouse));

%Sets variable to loop over ETA types
cETA_TYPE 	= {'Spike', 'Rate', 'Norm_Rate'};
cETA_NAME 	= {'db2Spk_H', 'db2ETA_H', 'db2ETA_H_Nrm'};
cYLABEL 	= {'Fraction of Total spikes', 'Spike Rate (Hz)', 'Normalized Spike Rate (S.D.)'};

%for iMseGp = 1:length(in1U_Mouse) + 1
for iMseGp = length(in1U_Mouse) + 1 % Does only the average accross mice
    if iMseGp <= length(in1U_Mouse)
        chSesAggregate = num2str(in1U_Mouse(iMseGp));
    else
        chSesAggregate = 'AllMice';
    end
    clear hFIG cFIGNAME
    iFig = 0;
    
    %Loops over band and thresholds
    for iThr = 1:inNThr
        for iBnd = 1:inNBnd
            if iBnd == 1; cCOLOR = {[.5 .5 .5], [0 .2 1]};
            else, cCOLOR =   {[.5 .5 .5], [1 .4 0]}; end
            db1Time = cHTIME{iThr, iBnd};
            
            %Loops over ETA types
            for iETp = 1:3
                %Loops over cell types
                %Creates the figure
                iFig = iFig + 1;
                hFIG(iFig) = figure('Position', [100 100 1600 900], 'Visible', blVisible);
                cFIGNAME{iFig} 	= sprintf('%s_%s_%s_%s_BasStimRun', cETA_TYPE{iETp}, cBAND{iBnd}, cSTATE{iBnd}, ...
                    cTHRESHOLD{iThr});
                inNRow = inNLyr; inNCol = inNCnd - 1;
                iPlt = 0;
                
                %Creates the figure
                iFig = iFig + 1;
                hFIG(iFig) = figure('Position', [100 100 1600 900], 'Visible', blVisible);
                cFIGNAME{iFig} 	= sprintf('%s_%s_%s_%s_All', cETA_TYPE{iETp}, cBAND{iBnd}, cSTATE{iBnd}, ...
                    cTHRESHOLD{iThr});
                [inNRow2, inNCol2] 	= FindPlotNum(inNLyr);
                iPlt2 = 0;
                clear hLIN hPLT hPLT2
                
                %Loops over layers
                for iLyr = 1:inNLyr
                    %Loops over condition
                    for iCnd = 1:inNCnd
                        cETA_NAME 	= {'db2Spk_H', 'db2ETA_H', 'db2ETA_H_Nrm'};
                        
                        %Selections the layer of interest
                        layerIdx = sETA(iBnd, iCnd).layerIdx;
                        bl1Lyr = layerIdx == iLyr;

                        %Selects mouse
                        in1Mouse = sETA(iBnd, iCnd).in1Mouse;
                        if iMseGp <= length(in1U_Mouse), bl1Mse = in1Mouse == in1U_Mouse(iMseGp);
                        else, bl1Mse = true(size(in1Mouse)); end
                        
                        %Select celltypes and layer
                        bl1Sel =  bl1Lyr & bl1Mse;
                        
                        %Extract the histogram of interest
                        db2H_In 	= sETA(iBnd, iCnd).([cETA_NAME{iETp} '_In'])(bl1Sel, :);
%                         db2H_Out 	= sETA(iBnd, iCnd).([cETA_NAME{iETp} '_Out'])(bl1Sel, :); %% try random instead out for comparison Stefan 2024/09/18
                        db2H_Rnd 	= sETA(iBnd, iCnd).([cETA_NAME{iETp} '_Rnd'])(bl1Sel, :);   

                        
                        %Computes the average PPC coherence for each layer and estimate the variance over cells
                        if iETp == 1
                            [db1H_In, db1H_Var_In] 		= NS_JackKnifeNormSum(db2H_In);
%                             [db1H_Out, db1H_Var_Out] 	= NS_JackKnifeNormSum(db2H_Out);
                            [db1H_Rnd, db1H_Var_Rnd] 	= NS_JackKnifeNormSum(db2H_Rnd);
                        else
                            [db1H_In, db1H_Var_In] 		= NS_WeightedStats(db2H_In, sETA(iBnd, iCnd).in1NEvt_In(bl1Sel));
%                             [db1H_Out, db1H_Var_Out] 	= NS_WeightedStats(db2H_Out, sETA(iBnd, iCnd).in1NEvt_Out(bl1Sel));
                            [db1H_Rnd, db1H_Var_Rnd] 	= NS_WeightedStats(db2H_Rnd, sETA(iBnd, iCnd).in1NEvt_Rnd(bl1Sel));
                        end
                        inNClu_In 			= size(db2H_In, 1);
                        db1H_SEM_In 	= sqrt(db1H_Var_In ./ inNClu_In);
%                         inNClu_Out 		= size(db2H_Out, 1);
%                         db1H_SEM_Out 	= sqrt(db1H_Var_Out ./ inNClu_Out);
                        inNClu_Rnd 		= size(db2H_Rnd, 1);
                        db1H_SEM_Rnd 	= sqrt(db1H_Var_Rnd ./ inNClu_Rnd);
                        
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
                        
                        %Plot the the phase histograms
                        hLIN(1) = errorbar(db1Time, db1H_In, db1H_SEM_In, db1H_SEM_In, '--o', 'Color', cCOLOR{2}, 'DisplayName', 'In');
%                         hLIN(2) = errorbar(db1Time, db1H_Out, db1H_SEM_Out, db1H_SEM_Out, '--o', 'Color', cCOLOR{1}, 'DisplayName', 'Out');
                        hLIN(2) = errorbar(db1Time, db1H_Rnd, db1H_SEM_Rnd, db1H_SEM_Rnd, '--o', 'Color', cCOLOR{1}, 'DisplayName', 'Rnd');
                        title(sprintf('%s %s', strrep(cLAYER{iLyr}, '_', ' '), cCOND{iCnd}));
                        if iLyr == 1, legend(hLIN); end
                    end
                end
                warning off, linkaxes(hPLT, 'y'); linkaxes(hPLT2, 'y'); warning on
            end
        end
        
    end
    
    %Saves the figure
    chSubDir1   = fullfile([chFigDir '_Layers'], chSesAggregate); if ~exist(chSubDir1, 'dir'); mkdir(chSubDir1); end
    NS_SaveFig(chSubDir1, hFIG, cFIGNAME);
    close all
end


%% plot only all Layers, but all 7 days
%Plots the figures
%Adds a condition that pools all layers %Stefan edited
cLAYER = "All_Layers";

%Gets the number of mouses
in1U_Mouse = unique(cat(1, sETA(:, :, :).in1Mouse));

%Sets variable to loop over ETA types
cETA_TYPE 	= {'Spike', 'Rate', 'Norm_Rate'};
cETA_NAME 	= {'db2Spk_H', 'db2ETA_H', 'db2ETA_H_Nrm'};
cYLABEL 	= {'Fraction of Total spikes', 'Spike Rate (Hz)', 'Normalized Spike Rate (S.D.)'};

%for iMseGp = 1:length(in1U_Mouse) + 1
for iMseGp = length(in1U_Mouse) + 1 % Does only the average accross mice
    if iMseGp <= length(in1U_Mouse)
        chSesAggregate = num2str(in1U_Mouse(iMseGp));
    else
        chSesAggregate = 'AllMice';
    end
    clear hFIG cFIGNAME
    iFig = 0;
    
    %Loops over band and thresholds
    for iThr = 1:inNThr
        for iBnd = 1:inNBnd
            if iBnd == 1; cCOLOR = {[.5 .5 .5], [0 .2 1]};
            else, cCOLOR =   {[.5 .5 .5], [1 .4 0]}; end
            db1Time = cHTIME{iThr, iBnd};
            
            %Loops over ETA types
            for iETp = 1:3
                %Loops over cell types
                %Creates the figure
                iFig = iFig + 1;
                hFIG(iFig) = figure('Position', [100 100 1600 900], 'Visible', blVisible);
                cFIGNAME{iFig} 	= sprintf('%s_%s_%s_%s_BasStimRun', cETA_TYPE{iETp}, cBAND{iBnd}, cSTATE{iBnd}, ...
                    cTHRESHOLD{iThr});
                inNRow = 7; inNCol = inNCnd - 1;
                iPlt = 0;
                
                %Creates the figure
                iFig = iFig + 1;
                hFIG(iFig) = figure('Position', [100 100 1600 900], 'Visible', blVisible);
                cFIGNAME{iFig} 	= sprintf('%s_%s_%s_%s_All', cETA_TYPE{iETp}, cBAND{iBnd}, cSTATE{iBnd}, ...
                    cTHRESHOLD{iThr});
                [inNRow2, inNCol2] 	= FindPlotNum(7);
                iPlt2 = 0;
                clear hLIN hPLT hPLT2
                
                %Loops over layers
                for iDay = 1:7
                    %Loops over condition
                    for iCnd = 1:inNCnd
                        cETA_NAME 	= {'db2Spk_H', 'db2ETA_H', 'db2ETA_H_Nrm'};
                        
%                         %Selections the layer of interest
%                         layerIdx = sETA(iBnd, iCnd).layerIdx;
%                         if strcmp(cLAYER{iLyr}, 'All_Layers')
%                             bl1Lyr = true(size(layerIdx));
%                         else
%                             bl1Lyr = layerIdx == iLyr;
%                         end
                        
                        %Selects mouse
                        in1Mouse = sETA(iBnd, iCnd).in1Mouse;
                        if iMseGp <= length(in1U_Mouse), bl1Mse = in1Mouse == in1U_Mouse(iMseGp);
                        else, bl1Mse = true(size(in1Mouse)); end
                        
                        %Selects days
                        in1SesDay = sETA(iBnd, iCnd).in1SesDay;
                        bl1Day = in1SesDay == iDay;
                        
                        %Selects "All layer"
                        layerIdx = sETA(iBnd, iCnd).layerIdx;
                        bl1Lyr = layerIdx == 5;
                        
                        %Select day and layer
                        bl1Sel =  bl1Mse & bl1Day & bl1Lyr;
                        
                        %Extract the histogram of interest
                        db2H_In 	= sETA(iBnd, iCnd).([cETA_NAME{iETp} '_In'])(bl1Sel, :);
%                         db2H_Out 	= sETA(iBnd, iCnd).([cETA_NAME{iETp} '_Out'])(bl1Sel, :);
                        db2H_Rnd 	= sETA(iBnd, iCnd).([cETA_NAME{iETp} '_Rnd'])(bl1Sel, :);
                        
                        %Computes the average PPC coherence for each layer and estimate the variance over cells
                        if iETp == 1
                            [db1H_In, db1H_Var_In] 		= NS_JackKnifeNormSum(db2H_In);
%                             [db1H_Out, db1H_Var_Out] 	= NS_JackKnifeNormSum(db2H_Out);
                            [db1H_Rnd, db1H_Var_Rnd] 	= NS_JackKnifeNormSum(db2H_Rnd);
                        else
                            [db1H_In, db1H_Var_In] 		= NS_WeightedStats(db2H_In, sETA(iBnd, iCnd).in1NEvt_In(bl1Sel));
%                             [db1H_Out, db1H_Var_Out] 	= NS_WeightedStats(db2H_Out, sETA(iBnd, iCnd).in1NEvt_Out(bl1Sel));
                            [db1H_Rnd, db1H_Var_Rnd] 	= NS_WeightedStats(db2H_Rnd, sETA(iBnd, iCnd).in1NEvt_Rnd(bl1Sel));
                        end
                        inNClu_In 			= size(db2H_In, 1);
                        db1H_SEM_In 	= sqrt(db1H_Var_In ./ inNClu_In);
%                         inNClu_Out 		= size(db2H_Out, 1);
%                         db1H_SEM_Out 	= sqrt(db1H_Var_Out ./ inNClu_Out);
                        inNClu_Rnd 		= size(db2H_Rnd, 1);
                        db1H_SEM_Rnd 	= sqrt(db1H_Var_Rnd ./ inNClu_Rnd);
                        
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
                        
                        %Plot the the phase histograms
                        hLIN(1) = errorbar(db1Time, db1H_In, db1H_SEM_In, db1H_SEM_In, '--o', 'Color', cCOLOR{2}, 'DisplayName', 'In');
%                         hLIN(2) = errorbar(db1Time, db1H_Out, db1H_SEM_Out, db1H_SEM_Out, '--o', 'Color', cCOLOR{1}, 'DisplayName', 'Out');
                        hLIN(2) = errorbar(db1Time, db1H_Rnd, db1H_SEM_Rnd, db1H_SEM_Rnd, '--o', 'Color', cCOLOR{1}, 'DisplayName', 'Rnd');
                        ylabel(cYLABEL{iETp}), xlabel('Time (s)')
                        title(sprintf('%s %s', ['Day ' num2str(iDay)], cCOND{iCnd}));
                        if iDay == 1, legend(hLIN); end
                    end
                end
                warning off, linkaxes(hPLT, 'y'); linkaxes(hPLT2, 'y'); warning on
            end
        end
    end
    
    %Saves the figure
    chSubDir1   = fullfile([chFigDir '_Days'], chSesAggregate); if ~exist(chSubDir1, 'dir'); mkdir(chSubDir1); end
    NS_SaveFig(chSubDir1, hFIG, cFIGNAME);
    close all
end
