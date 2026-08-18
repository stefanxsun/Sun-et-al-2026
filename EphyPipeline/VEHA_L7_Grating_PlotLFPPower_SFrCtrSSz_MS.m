clear
cd 'E:\Ephy\VisExpHighAll';

%Defines the info file
sINFO = VEHA_DefineINFO();

%Defines the parameters
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = true;
sCFG.sPARAM.blDoPlot = 0;


for i = 1:length(sINFO.sREC)
    sCFG.sREC = sINFO.sREC(i);
    try
        VEHA_L7_Grating_PlotLFPPower_SFrCtrSSz(sCFG)
        close all
    catch ME
        getReport(ME)
    end
end
% error('VOLONTARY SCRIPT STOP');
%% Aggregates the data accross the sessions into an excel file (doesn't work in linux)(not neccessary step)
% clear, close all
% cd 'E:\Ephy\VisExpHighAll';
% chSessionDir = 'VEHA_L7_Grating_PlotLFPPower_SFrCtrSSz';
% chFileName = [chSessionDir '.mat'];
% sDIR = dir(chSessionDir);
% 
% %Defines the info file and get the sessions for which the protocol exist
% sINFO = VEHA_DefineINFO();
% in1Session  = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR(:).name})));
% in1InfoIdx  = VEHA_U_FindSessionIndex(sINFO, {sDIR(in1Session).name});
% in1Day      = VEHA_U_FindSessionDayNum(sINFO, chSessionDir);
% in1Day      = in1Day(in1InfoIdx);
% in1Mouse    = [sINFO.sREC.inMouseID];
% in1Mouse    = in1Mouse(in1InfoIdx);
% 
% % Initialize the excel file
% chXL_FileName1   = fullfile(chSessionDir, 'PWR_dB_vs_SFrCtrSSz');
% cXLS_FILE1_CND   = {'Mouse', 'Day', 'Cond', 'Contrast', 'SpatFreq',  'Size'};
% cXLS_FILE1_PWR   = 0:2:120;
% chXL_FileName2   = fullfile(chSessionDir, 'PWR_dB_MinusSpont_vs_SFrCtrSSz');
% cXLS_FILE2_CND   = {'Mouse', 'Day', 'Cond', 'Contrast', 'SpatFreq',  'Size'};
% cXLS_FILE2_PWR   = 0:2:120;
% 
% % Aggregates the data
% for iSes = 1:length(in1Session)
%     try
%         sLD = load(fullfile(chSessionDir, sDIR(in1Session(iSes)).name, chFileName)); % loads the file
%         cXLS_FILE1_CND = cat(1, cXLS_FILE1_CND, {in1Mouse(iSes) in1Day(iSes), 'Spont', NaN, NaN, NaN});
%         cXLS_FILE1_PWR = cat(1, cXLS_FILE1_PWR, sLD.db2AvCCPower_Spt);
%         for iCnd = 1:size(sLD.sCOND, 2)
%             cXLS_FILE1_CND = cat(1, cXLS_FILE1_CND, {in1Mouse(iSes) in1Day(iSes), iCnd, sLD.db2Cond(4, iCnd), sLD.db2Cond(2, iCnd), sLD.db2Cond(5, iCnd)});
%             cXLS_FILE1_PWR = cat(1, cXLS_FILE1_PWR, sLD.sCOND(iCnd).db2AvCCPower);
%             cXLS_FILE2_CND = cat(1, cXLS_FILE2_CND, {in1Mouse(iSes) in1Day(iSes), iCnd, sLD.db2Cond(4, iCnd), sLD.db2Cond(2, iCnd), sLD.db2Cond(5, iCnd)});
%             cXLS_FILE2_PWR = cat(1, cXLS_FILE2_PWR, sLD.sCOND(iCnd).db2AvCCPower_Diff);
%         end
%     catch ME
%         getReport(ME)
%     end
% end
% 
% %Writes the data into the excel Sheet
% xlswrite(chXL_FileName1, cXLS_FILE1_CND, 1, 'A1')
% xlswrite(chXL_FileName1, cXLS_FILE1_PWR, 1, 'G1')
% xlswrite(chXL_FileName2, cXLS_FILE2_CND, 1, 'A1')
% xlswrite(chXL_FileName2, cXLS_FILE2_PWR, 1, 'G1')
%% Exports the figures for individual sessions
% clear, close all
% cd 'E:\Ephy\VisExpHighAll';
% chSessionDir = 'VEHA_L7_Grating_PlotLFPPower_SFrCtrSSz';
% chFileName = [chSessionDir '.fig'];
% sDIR = dir(chSessionDir);
% 
% %Defines the info file and get the sessions for which the protocol exist
% sINFO = VEHA_DefineINFO();
% in1Session  = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR(:).name})));
% 
% cFIGNAME = {'EvokedPower', 'EvokdedPowerMinusSpont'};
% 
% for iDir = in1Session
%     hFIG = openfig(fullfile(chSessionDir, sDIR(iDir).name, chFileName)); % loads the file
%     NS_SaveFig(fullfile(chSessionDir, sDIR(iDir).name), hFIG, cFIGNAME);
%     close all
% end
%% Aggregates the data accross the sessions into different figures for each subsequent day
clear, close all
cd 'E:\Ephy\VisExpHighAll';
chSessionDir = 'VEHA_L7_Grating_PlotLFPPower_SFrCtrSSz';
chFileName = [chSessionDir '.mat'];
sDIR = dir(chSessionDir);

%Defines the info file and get the sessions for which the protocol exist
sINFO = VEHA_DefineINFO();
in1Session  = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR(:).name})));
in1InfoIdx  = VEHA_U_FindSessionIndex(sINFO, {sDIR(in1Session).name});
in1Day      = VEHA_U_FindSessionDayNum(sINFO, chSessionDir);
in1Day      = in1Day(in1InfoIdx);
in1Mouse    = [sINFO.sREC.inMouseID];
in1Mouse    = in1Mouse(in1InfoIdx);


% Initializes sCOND
[db2SesCond, db2AvPower, PowerQLF, PowerQHF,PowerLoc, in1NChunk, in1SesDay, in1SesMouse] = deal([]); %%%%%Stefan edited

% Aggregates the data
fprintf('Aggregating data... ')
for iSes = 1:length(in1Session)
%     try
        sLD = load(fullfile(chSessionDir, sDIR(in1Session(iSes)).name, chFileName)); % loads the file
        db2Cond = [];
        for iCnd = 1:size(sLD.db2Cond, 2)
            % Aggregates spetra and number of chunks averages to compute them
            db2SesCond     	= cat(1, db2SesCond, sLD.db2Cond(:, iCnd)');
            db2Cond     	= cat(1, db2Cond, sLD.db2Cond(:, iCnd)');
            db2AvPower      = cat(1, db2AvPower, sLD.sCOND(iCnd).db2AvCCPower);
            PowerQLF         = cat(1, PowerQLF, sLD.sCOND(iCnd).db2AvCCPowerQLF);
            PowerQHF         = cat(1, PowerQHF, sLD.sCOND(iCnd).db2AvCCPowerQHF);
            PowerLoc         = cat(1, PowerLoc, sLD.sCOND(iCnd).db2AvCCPowerLoc);
            in1NChunk       = cat(1, in1NChunk, sum(sLD.sCOND(iCnd).bl1FChunk));
            in1SesDay       = cat(1, in1SesDay, in1Day(iSes));
            in1SesMouse     = cat(1, in1SesMouse, in1Mouse(iSes));
            %Aggregate stimulation chunks into a single vector
            if iCnd == 1 % Initialize
                bl1Stim_Chunk   = sLD.sCOND(iCnd).bl1FChunk; 
            else % or aggregates
                bl1Stim_Chunk   = bl1Stim_Chunk | sLD.sCOND(iCnd).bl1FChunk;
            end
        end
                
        % Aggregates the baseline power and the number of chuncks necessary
        % to computes them
        db2SesCond     	= cat(1, db2SesCond, nan(1, size(db2SesCond, 2)));
        db2AvPower      = cat(1, db2AvPower, sLD.db2AvCCPower_Spt);
        PowerQLF      = cat(1, PowerQLF, sLD.db2AvCCPower_Spt);     %%%%%%%%%%%Stefan added
        PowerQHF      = cat(1, PowerQHF, sLD.db2AvCCPower_Spt);
        PowerLoc      = cat(1, PowerLoc, sLD.db2AvCCPower_Spt);
        
        in1NChunk       = cat(1, in1NChunk, sum(~bl1Stim_Chunk));

        % Aggregates the day of presentation and the mouse
        in1SesDay       = cat(1, in1SesDay, in1Day(iSes));
        in1SesMouse     = cat(1, in1SesMouse, in1Mouse(iSes));
            
        %%%% STEFAN ADDED 07/31/2024 to uniform the stimuli parameters %%%%%%%%%%%%
        [SFs,~,isf] = unique(db2Cond(:,2));
        [Ctr,~,ictr] = unique(db2Cond(:,4));
        [Size,~,isz] = unique(db2Cond(:,5));
        
        
        db2SesCond(db2SesCond(:,2) == SFs(1),2) =0.01;
        db2SesCond(db2SesCond(:,2) == SFs(2),2) =0.04;
        db2SesCond(db2SesCond(:,2) == SFs(3),2) =0.16;
        db2SesCond(db2SesCond(:,2) == SFs(4),2) =0.64;
        
        db2SesCond(db2SesCond(:,4) == Ctr(1),4) =0.02;
        db2SesCond(db2SesCond(:,4) == Ctr(2),4) =0.08;
        db2SesCond(db2SesCond(:,4) == Ctr(3),4) =0.32;
        db2SesCond(db2SesCond(:,4) == Ctr(4),4) =1;
        
        db2SesCond(db2SesCond(:,5) == Size(1),5) =5;
        db2SesCond(db2SesCond(:,5) == Size(2),5) =10;
        db2SesCond(db2SesCond(:,5) == Size(3),5) =20;
        db2SesCond(db2SesCond(:,5) == Size(4),5) =40;
        
        
        %     catch ME
%         getReport(ME)
%     end
end

fprintf('Done !\r');
%% Plots the stimulus evoked power spectrum each days
state = 'All';
VEHA_L7_plot_power_spectrum(in1SesDay,db2SesCond,db2AvPower,chSessionDir, state);

state = 'QuiescenceLF';
VEHA_L7_plot_power_spectrum(in1SesDay,db2SesCond,PowerQLF,chSessionDir, state);

state = 'QuiescenceHF';
VEHA_L7_plot_power_spectrum(in1SesDay,db2SesCond,PowerQHF,chSessionDir, state);

state = 'Locomotion';
VEHA_L7_plot_power_spectrum(in1SesDay,db2SesCond,PowerLoc,chSessionDir, state);

%% PLot the increase in a color map
% close all, clear hFIG hPLOT hAX1 hAX2
% in3PlotIdx  = reshape(1:16, 4, 4);
% db1Freq     = 0:2:120;
% cBAND       = {[15 30], [30 80]};
% in1U_Day    = unique(in1SesDay);
% inNDay      = length(in1U_Day);
% in1U_Mse    = unique(in1SesMouse);
% inNMse      = length(in1U_Mse);
% bl10Ctr     = db2SesCond(:, 4) == 0; % Removes 0 pct contrast that can have occured by accident
% db2U_Cnd    = unique(db2SesCond(~bl1Bas & ~bl10Ctr, :), 'row');
% db1U_SF     = unique(db2U_Cnd(:, 2));
% db1U_Sz     = unique(db2U_Cnd(:, 5));
% db1U_Ct     = unique(db2U_Cnd(:, 4));
% db2PwrTemp  = nan(inNMse, inNDay);
% sCOND       = struct('db2Pwr', repmat({db2PwrTemp}, 1, size(db2U_Cnd, 1)));
% 
% 
% %Intialize plotting variables
%     %Plt 1
% iFig  = 0;
% cFIGNAME = {};
% iPlt1 = 0;
% db1CLimMax   = [Inf -Inf]; %Appreciate the pun
%     %Plt 2
% cCOLOR = {[0 .3 .9], [0 .6 .9] [.9 .6 0] [.9 .3 0]};
% in1Offset = linspace(-.2, .2, 4);
% cCTR_LEGEND = cellfun(@(x) sprintf('%d%% Ctr' , 100*x), num2cell(db1U_Ct), 'UniformOutput', false);
% for iBnd = 1:length(cBAND)
%     %Boolean of the frequency band of interest
%     bl1Bnd = db1Freq > cBAND{iBnd}(1) & db1Freq < cBAND{iBnd}(2);
%     
%     %Initializes figure and figure handle
%     iFig = iFig + 1;
%     hFIG(iFig)  = figure('Position', [100, 100, 1600 800]);
%     cFIGNAME = cat(2, cFIGNAME, sprintf('PowerImage_%d-%dHz', cBAND{iBnd}));
%     iPlt2 = 0;
%     
%     %Loops over conditions
%     for iCt = 1:4
%         for iDay = 1:length(in1U_Day)
%             % Selects the days of interest
%             bl1Day   = in1SesDay == in1U_Day(iDay);
% 
%             db2Im_Av = nan(4, 4);
%             for iSF = 1:4
%                 for iSz = 1:4
%                     iCnd        = in3PlotIdx(iSz, iSF, iCt);
%                     bl1Cnd      = bl1Day & all(db2SesCond == db2U_Cnd(iCnd, :), 2);
%                     db1CndPwr   = mean(db2AvPower(bl1Cnd, bl1Bnd), 2);
%                     in1CndMse   = in1SesMouse(bl1Cnd);
%                     in1CndNChnk = in1NChunk(bl1Cnd);
%                     
%                     % Assigns the response of each mouse for a given day to its proper row
%                     db1CndPwr_Mse = nan(inNMse, 1);
%                     for iMse = 1:inNMse
%                         bl1Mse = in1CndMse == in1U_Mse(iMse);
%                         db1CndPwr_Mse(iMse) = NS_WeightedStats(db1CndPwr(bl1Mse), in1CndNChnk(bl1Mse), 1);
%                     end
%                     
%                     %Save the aggregate response over days for subsequent
%                     %plots
%                     sCOND(iCnd).db2Pwr(:, iDay) = db1CndPwr_Mse;
%                         
%                     % Computes the imge
%                     db2Im_Av(iSF, iSz) =  nanmean(db1CndPwr_Mse, 1);
%                     db2Im_SEM(iSF, iSz) = sqrt(nanvar(db1CndPwr_Mse, [], 1)./nansum(~isnan(db1CndPwr_Mse))); % not really useful. But well 
%                 end
%             end
%             iPlt1 = iPlt1 + 1;
%             iPlt2 = iPlt2 + 1;
%             hAX1(iPlt1) = subplot(4, length(in1U_Day), iPlt2);
%             imagesc(db2Im_Av)
%             set(gca, 'XTick', 1:4, 'XTickLabel', db1U_Sz, 'YTick', 1:4, 'YTickLabel', db1U_SF);
%             db1CLim         = get(gca, 'CLim');
%             db1CLimMax(1)   = min(db1CLimMax(1), min(db2Im_Av(:)));
%             db1CLimMax(2)   = max(db1CLimMax(2), max(db2Im_Av(:)));
%             title(sprintf('Day %d: %.0f%% Ctrst', iDay, 100*db1U_Ct(iCt)));
%             if iCt  == 4 && iDay == round(inNDay/2), xlabel('Stim Radius (Deg)'); end
%             if iDay == 1 && iCt == 2, ylabel('Spatial frequency (Cyc/Deg)'); end
%             if iDay == 1 && iCt == 3, ylabel(sprintf('%d-%dHz', cBAND{iBnd})); end
%         end
%     end
%     set(hAX1, 'CLim', db1CLimMax)
%     
%     iFig = iFig + 1;
%     iPlot = 0;
%     hFIG(iFig) = figure('Position', [100, 100, 1600 800]);
%     cFIGNAME = cat(2, cFIGNAME, sprintf('PowerIncrease_%d-%dHz', cBAND{iBnd}));
%     for iSF = 1:4
%         for iSz = 1:4
%             iPlot = iPlot + 1;
%             hAX2(iPlot) = subplot(4, 4, iPlot); hold on
%             for iCt = 1:4
%                 iCnd        = in3PlotIdx(iSz, iSF, iCt);
%                 
%                 % Plots the average evoked power for the band of interest
%                 db1PwrAv    =  nanmean(sCOND(iCnd).db2Pwr, 1);
%                 db1PwrSEM   = sqrt(nanvar(sCOND(iCnd).db2Pwr, [], 1)./nansum(~isnan(sCOND(iCnd).db2Pwr), 1)); % not really useful. But well
%                 hPLOT(iCt)  = errorbar(in1Offset(iCt) + in1U_Day, db1PwrAv, db1PwrSEM, db1PwrSEM, 'o-', 'Linewidth', 2, 'color', cCOLOR{iCt});
%                 
%                 % Plots an additional asterisk if the last day is
%                 % significantly different from the first
%                 db1FirstDay     = sCOND(iCnd).db2Pwr(:, 1);
%                 db1LastDay      = sCOND(iCnd).db2Pwr(:, end);
%                 if all(~isnan([db1FirstDay; db1LastDay]))
%                     blSig = ttest(db1FirstDay - db1LastDay);
%                 elseif all(isnan(db1FirstDay)) | all(isnan(db1LastDay))
%                     blSig = false;
%                 else
%                     blSig = ttest2(db1FirstDay(~isnan(db1FirstDay)), db1LastDay(~isnan(db1LastDay)));
%                 end
%                 if blSig, plot(inNDay + 1, db1PwrAv(end), '*', 'color', cCOLOR{iCt}); end
%             end
%             xlim([0 inNDay + 2])
%             title(sprintf('SF: %.2f, Size: %.2f', db1U_SF(iSF), db1U_Sz(iSz)));
%             xlabel('Day');
%             if iSz == 1
%                 if iSF == 1, legend(hPLOT, cCTR_LEGEND, 'Location', 'North'); end
%                 if iSF == 2, ylabel(sprintf('%d-%dHz', cBAND{iBnd})); end
%                 if iSF == 3, ylabel('Power (dB)'); end
%             end
%         end
%     end
%     linkaxes(hAX2);
% end
% 
% % Saves the figures
% save(fullfile(chFigDirName, 'Workspace2'), '-v7.3')
% savefig(hFIG,fullfile(chFigDirName, 'Pool_Figures2'));
% 
% NS_SaveFig(chFigDirName, hFIG, cFIGNAME); 
% pause(1); close all;