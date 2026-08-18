clear
% run StartupAnalysis.m
% cd '/media/storage/Quentin/Analyses/GammaChronicProbe';

%Defines the info file
sINFO = VEHA_DefineINFO();
sREC    = sINFO.sREC;
%Defines the parameters
sCFG.sPARAM.cTHRESHOLD = {'MahalDNorm'};
sCFG.sPARAM.chBaseDirectory = sINFO.chBaseDirectory;
sCFG.sPARAM.blOverwrite = true;

% cSESSION = {'2019-07-21_15-03-40_1'};
% in1Idx = VEHA_U_FindSessionIndex(sINFO, cSESSION);
% 
% %loops through the files
% for i = in1Idx
parfor i = 1:length(sINFO.sREC)
    try
        VEHA_L6_Pulse_SFrCtrSSz(sCFG,sREC(i));
    catch ME
        getReport(ME)
    end
end

%error('VOLONTARY SCRIPT STOP');
%% Aggregates the data accross the sessions into different figures for each subsequent day
clear, close all
% run StartupAnalysis.m
% cd '/media/storage/Quentin/Analyses/GammaChronicProbe';
chSessionDir 	= 'VEHA_L6_Pulse_SFrCtrSSz';
chFileName 		= [chSessionDir '.mat'];
chFigDir 		= fullfile('Figure', chSessionDir); if ~exist(chFigDir, 'dir'); mkdir('Figure', chSessionDir); end
blVisible 		= 1;
sDIR 			= dir(chSessionDir);

%Sets the bands
cBAND 		= {'15-30Hz', '30-80Hz'};
cSTATE 		= {'Stim', 'Running'};
inNBnd 		= length(cBAND); 

%Sets the thresholds
cTHRESHOLD 	= {'MahalDNorm'}; 
inNThr 		= length(cTHRESHOLD);
 
%Defines the info file and get the sessions for which the protocol exist
sINFO 		= VEHA_DefineINFO();
in1Session  = find(~isnan(VEHA_U_FindSessionIndex(sINFO, {sDIR(:).name})));
in1InfoIdx  = VEHA_U_FindSessionIndex(sINFO, {sDIR(in1Session).name});
in1Day      = VEHA_U_FindSessionDayNum(sINFO, chSessionDir);
in1Day      = in1Day(in1InfoIdx);
in1Mouse    = [sINFO.sREC.inMouseID];
in1Mouse    = in1Mouse(in1InfoIdx);

% Initializes sCOND
[db2SesCond, db3Powr, db3Z_Powr, BasPowr, BasPowrSD, db3Rate, db3Z_Rate, BasRate, BasRateSD, in1SesDay, in1SesMouse] = deal([]);

% Aggregates the data
fprintf('Aggregating data... ')
for iSes = 1:length(in1Session)
%     try
        sLD = load(fullfile(chSessionDir, sDIR(in1Session(iSes)).name, chFileName)); % loads the file
        
        for iCnd = 1:size(sLD.db2Cond, 2)
            % Aggregates pulse rate for each condition
            db2SesCond     	= cat(1, db2SesCond, sLD.db2Cond(:, iCnd)');
			[db2Powr, db2Z_Powr, db2Rate, db2Z_Rate] = deal(nan(inNThr, inNBnd));
			for iThr =  1:inNThr
				for iBnd = 1:inNBnd
					bl1Thr = ismember({sLD.sBAND(:, 1).chThreshold}, cTHRESHOLD(iThr));
					bl1Bnd = ismember({sLD.sBAND(1, :).chBandLabel}, cBAND(iBnd));
					if ~any(bl1Thr) | ~any(bl1Bnd), continue; end 
					db2Powr(bl1Thr, bl1Bnd) 	= sLD.sBAND(bl1Thr, bl1Bnd).sCOND(iCnd).dbPowr; 
					db2Z_Powr(bl1Thr, bl1Bnd) 	= sLD.sBAND(bl1Thr, bl1Bnd).sCOND(iCnd).dbZ_Powr; 
					db2Rate(bl1Thr, bl1Bnd) 	= sLD.sBAND(bl1Thr, bl1Bnd).sCOND(iCnd).dbRate; 
					db2Z_Rate(bl1Thr, bl1Bnd) 	= sLD.sBAND(bl1Thr, bl1Bnd).sCOND(iCnd).dbZ_Rate; 
                    
                    
				end
			end
			db3Powr 		= cat(3, db3Powr, db2Powr);
			db3Z_Powr 		= cat(3, db3Z_Powr, db2Z_Powr);
			db3Rate 		= cat(3, db3Rate, db2Rate);
			db3Z_Rate 		= cat(3, db3Z_Rate, db2Z_Rate);
            in1SesDay       = cat(1, in1SesDay, in1Day(iSes));
            in1SesMouse     = cat(1, in1SesMouse, in1Mouse(iSes));
            
        end
                
        % Aggregates pulse rate for baseline
        db2SesCond     	= cat(1, db2SesCond, nan(1, size(db2SesCond, 2)));
		[db2Powr, db2Rate] = deal(nan(inNThr, inNBnd));
		for iThr =  1:inNThr
			for iBnd = 1:inNBnd
				bl1Thr = ismember({sLD.sBAND(:, 1).chThreshold}, cTHRESHOLD(iThr));
				bl1Bnd = ismember({sLD.sBAND(1, :).chBandLabel}, cBAND(iBnd));
				if ~any(bl1Thr) | ~any(bl1Bnd), continue; end 
				db2Powr(bl1Thr, bl1Bnd) 	= sLD.sBAND(bl1Thr, bl1Bnd).dbBasPowr; 
				db2Rate(bl1Thr, bl1Bnd) 	= sLD.sBAND(bl1Thr, bl1Bnd).dbBasRate; 
			end
		end
		db3Powr 		= cat(3, db3Powr, db2Powr);
		db3Z_Powr 		= cat(3, db3Z_Powr, zeros(inNThr, inNBnd));
		db3Rate 		= cat(3, db3Rate, db2Rate);
		db3Z_Rate 		= cat(3, db3Z_Rate, zeros(inNThr, inNBnd));
        in1SesDay   	= cat(1, in1SesDay, in1Day(iSes));
        in1SesMouse     = cat(1, in1SesMouse, in1Mouse(iSes));
        
        %Stefan added 1/9/2024 edited 03/10/2025
        BasPowr = cat(1, BasPowr, db2Powr);
        
        %Stefan added 03/10/2025
        BasRate = cat(1, BasRate, db2Rate);

%     catch ME
%         getReport(ME)
%     end
end

% organize into day in column and mouse in row  Stefan 03/10/2025
BasPowr = permute(reshape(BasPowr(:,1),length(unique(in1Mouse)),length(unique(in1Day))),[2 1]);
BasRate = permute(reshape(BasRate(:,1),length(unique(in1Mouse)),length(unique(in1Day))),[2 1]);

fprintf('Done !\r');

%% PLot the increase in a color map
close all, clear hFIG hPLOT
in3PlotIdx  = permute(reshape(1:64, 4, 4, 4), [1 3 2]);
in1U_Day    = unique(in1SesDay);
inNDay      = length(in1U_Day);
in1U_Mse    = unique(in1SesMouse);
inNMse      = length(in1U_Mse);
bl10Ctr     = db2SesCond(:, 4) == 0; % Removes 0 pct contrast that can have occured by accident
bl1Bas 		= all(isnan(db2SesCond), 2);
db2U_Cnd    = unique(db2SesCond(~bl1Bas & ~bl10Ctr, :), 'row');
db1U_SF     = unique(db2U_Cnd(:, 2));
db1U_Sz     = unique(db2U_Cnd(:, 5));
db1U_Ct     = unique(db2U_Cnd(:, 4));
db2Temp  	= nan(inNMse, inNDay);
sCOND       = struct('db2Powr', repmat({db2Temp}, 1, size(db2U_Cnd, 1)), ...
				'db2Z_Powr', repmat({db2Temp}, 1, size(db2U_Cnd, 1)), ...
				'db2Rate', repmat({db2Temp}, 1, size(db2U_Cnd, 1)), ...
				'db2Z_Rate', repmat({db2Temp}, 1, size(db2U_Cnd, 1)));

%Initializes loops what we are plotting
cVAR_LABEL 	= {'Power', 'ZScored_Power', 'Rate', 'ZScored_Rate'};
cCND_FIELD 	= {'db2Powr', 'db2Z_Powr', 'db2Rate', 'db2Z_Rate'}; 	
inNVar 		= length(cVAR_LABEL);

%Initializes some overal plotting variables
cCOLOR = {[0 .3 .9], [0 .6 .9] [.9 .6 0] [.9 .3 0]};
in1Offset = linspace(-.2, .2, 4);
cSz_LEGEND = cellfun(@(x) sprintf('%d Size' , 2*x), num2cell(db1U_Sz), 'UniformOutput', false);
	
%Loops over thresholds
for iThr = 1:inNThr
	
	%Intializes loop specific plotting variables
	iFig  = 0; cFIGNAME = {}; cAX = cell(1, inNVar); in1I_Ax = zeros(1, inNVar); 
	cCLIMAX = repmat({[Inf -Inf]}, 1, inNVar); %Appreciate the pun

	% Loops over bands 
	for iBnd = 1:length(cBAND)
	
        % Loops over conditions and gathers data in a convenient way
        for iCt = 1:4
            for iDay = 1:length(in1U_Day)
                % Selects the days of interest
                bl1Day   = in1SesDay == in1U_Day(iDay);
                for iSF = 1:4
                    for iSz = 1:4
                        % Finds the condition
                        iCnd        = in3PlotIdx(iSz, iSF, iCt);
                        bl1Cnd      = bl1Day & all(db2SesCond == db2U_Cnd(iCnd, :), 2);
                        % Assigns the response of each mouse for a given day to its proper row
                        [db1CndRate_Mse db1CndZ_Rate_Mse] = deal(nan(inNMse, 1));
                        for iMse = 1:inNMse
                            bl1Mse = in1SesMouse  == in1U_Mse(iMse);
                            sCOND(iCnd).db2Powr(iMse, iDay) = mean(db3Powr(iThr, iBnd, bl1Cnd & bl1Mse), 3);
                            sCOND(iCnd).db2Z_Powr(iMse, iDay) = mean(db3Z_Powr(iThr, iBnd, bl1Cnd & bl1Mse), 3);
                            sCOND(iCnd).db2Rate(iMse, iDay) = mean(db3Rate(iThr, iBnd, bl1Cnd & bl1Mse), 3);
                            sCOND(iCnd).db2Z_Rate(iMse, iDay) = mean(db3Z_Rate(iThr, iBnd, bl1Cnd & bl1Mse), 3);
                        end
                    end
                end
            end
        end

		%Plot 1: images
		%--------------------------------------------------------------------------------------------------------------------
		% Loops over variables
		for iVar = 1:inNVar
	    	iFig = iFig + 1;
	    	hFIG(iFig)  = figure('Position', [100, 100, 1600 800], 'Visible', blVisible);
	    	cFIGNAME{iFig} = sprintf('%s_Image_%s', cVAR_LABEL{iVar}, cBAND{iBnd});
	    	iPlt = 0;
	    	
	    	%Loops over conditions
	    	for iCt = 1:4
	    	    for iDay = 1:length(in1U_Day)
	    	        % Selects the days of interest
	    	        bl1Day   = in1SesDay == in1U_Day(iDay);
	
	    	        % Computes the image
	    	        db2Im_Av = nan(4, 4);
	    	        for iSF = 1:4
	    	            for iSz = 1:4
	    	                iCnd        = in3PlotIdx(iSz, iSF, iCt);
	    	                bl1Cnd      = bl1Day & all(db2SesCond == db2U_Cnd(iCnd, :), 2);
	    	                db2Im_Av(iSF, iSz) =  nanmean(sCOND(iCnd).(cCND_FIELD{iVar})(:, iDay), 1);
	    	            end
	    	        end
	    	        in1I_Ax(iVar) = in1I_Ax(iVar) + 1;
	    	        iPlt = iPlt + 1;
	    	        cAX{iVar}(in1I_Ax(iVar)) = subplot(4, length(in1U_Day), iPlt);
	    	        imagesc(db2Im_Av)
	    	        set(gca, 'XTick', 1:4, 'XTickLabel', db1U_Sz, 'YTick', 1:4, 'YTickLabel', db1U_SF);
	    	        cCLIMAX{iVar}(1) = min(cCLIMAX{iVar}(1), min(db2Im_Av(:)));
	    	        cCLIMAX{iVar}(2) = max(cCLIMAX{iVar}(2), max(db2Im_Av(:)));
	    	        title(sprintf('Day %d: %.0f%% Ctrst', iDay, 100*db1U_Ct(iCt)));
	    	        if iCt  == 4 && iDay == round(inNDay/2), xlabel('Stim Radius (Deg)'); end
	    	        if iDay == 1 && iCt == 2, ylabel('Spatial frequency (Cyc/Deg)'); end
	    	        if iDay == 1 && iCt == 3, ylabel(sprintf('%s Pulse %s', cBAND{iBnd}, cVAR_LABEL{iVar})); end
	    	    end
	    	end
	    	set(cAX{iVar}, 'CLim', cCLIMAX{iVar})
		end
	    
		%Plot 2: plots of changes along days with significance and error bars for each variable of intererst
		%--------------------------------------------------------------------------------------------------------------------
		% Loops over variables
		for iVar = 1:inNVar
	    	iFig = iFig + 1;
	    	iPlt = 0; hAX = []; hPLOT = [];
	    	hFIG(iFig) = figure('Position', [100, 100, 1600 800], 'Visible', blVisible);
	    	cFIGNAME = cat(2, cFIGNAME, sprintf('%s_Plots_%s', cVAR_LABEL{iVar}, cBAND{iBnd}));
	    	for iCt = 1:4
	    	    for iSF = 1:4
	    	        iPlt = iPlt + 1;
	    	        hAX(iPlt) = subplot(4, 4, iPlt); hold on
	    	        for iSz = 1:4
	    	            iCnd        = in3PlotIdx(iSz, iSF, iCt);
	    	            
	    	            % Plots the average evoked power for the band of interest
	    	            db1RateAv   = nanmean(sCOND(iCnd).(cCND_FIELD{iVar}), 1);
	    	            db1RateSEM  = sqrt(nanvar(sCOND(iCnd).(cCND_FIELD{iVar}), [], 1)./nansum(~isnan(sCOND(iCnd).(cCND_FIELD{iVar})), 1)); 
	    	            hPLOT(iSz)  = errorbar(in1Offset(iSz) + in1U_Day, db1RateAv, db1RateSEM, db1RateSEM, 'o-', 'Linewidth', 2, 'color', cCOLOR{iSz});
	    	            
	    	            % Plots an additional asterisk if the last day is
	    	            % significantly different from the first
	    	            db1FirstDay     = sCOND(iCnd).(cCND_FIELD{iVar})(:, 1);
                        db1LastDay      = sCOND(iCnd).(cCND_FIELD{iVar})(:, end);
                        
                        %%%%%%%%%%% Stefan added, now use permutation test then
                        %%%%%%%%%%% correct for multiple comparison  03/10/2025
                        [permuteP(iCnd,:),o(iCnd,:),e(iCnd,:),ci(iCnd,:)] = permutationTest_Stefan(db1LastDay, db1FirstDay, 1,'exact',1);
                        
                        % This is the original, commented out 03/10/2025
%                         if all(~isnan([db1FirstDay; db1LastDay]))
% 	    	                blSig = ttest(db1FirstDay - db1LastDay);
% 	    	            elseif all(isnan(db1FirstDay)) | all(isnan(db1LastDay))
% 	    	                blSig = false;
% 	    	            else
% 	    	                blSig = ttest2(db1FirstDay(~isnan(db1FirstDay)), db1LastDay(~isnan(db1LastDay)));
%                         end
%                         if isnan(blSig)   %%% STEFAN ADDED
%                             blSig =0;
%                         end
% 	    	            if blSig, plot(inNDay + 1, db1RateAv(end), '*', 'color', cCOLOR{iSz}); end
	    	        end
	    	        xlim([0 inNDay + 2])
	    	        title(sprintf('Contrast: %.2f, SF: %.2f', db1U_Ct(iCt), db1U_SF(iSF)));
	    	        xlabel('Day');
	    	        if iSF == 1
	    	            if iCt == 2, ylabel(sprintf('%s Pulse', cBAND{iBnd})); end
	    	            if iCt == 3, ylabel(sprintf('%s', cVAR_LABEL{iVar})); end
	    	        end
	    	    end
            end

            %%% Stefan added multi comparison correction
            [permuteH, ~, adj_permuteP]=fdr_bh(permuteP); %#ok<ASGLU>
            iPlt = 0;
            for iCt = 1:4
                for iSF = 1:4
                    iPlt = iPlt + 1;
                    for iSz = 1:4
                        iCnd        = in3PlotIdx(iSz, iSF, iCt);
                        db1RateAv   = nanmean(sCOND(iCnd).(cCND_FIELD{iVar}), 1);
                        if permuteH(iCnd); plot(hAX(iPlt),inNDay + 1, db1RateAv(end), '*', 'color', cCOLOR{iSz}); end
                    end
                end
            end
            
            sgtitle(sprintf('%s Plots %s', cVAR_LABEL{iVar}, cBAND{iBnd}));
            linkaxes(hAX);
            axP = get(gca,'Position'); legend(hPLOT, cSz_LEGEND,'Location','NorthEastOutside');
            set(gca, 'Position', axP);
        end
    end
	
	% Saves the figures
	warning off
	chThrDir = fullfile(chFigDir, cTHRESHOLD{iThr}); if ~exist(chThrDir, 'dir'); mkdir(chFigDir, cTHRESHOLD{iThr}); end
	save(fullfile(chThrDir, 'Workspace'), '-v7.3')
	savefig(hFIG, fullfile(chThrDir, 'Pool_Figures'));
	
	NS_SaveFig(chThrDir, hFIG, cFIGNAME);
	pause(.5); close all;
end
