function NS_L5_Hilbert_SFrCtrSSz_Plot(in1SesDay, in1SesMouse, db2SesCond, ...
    db3Power, db3Z_Power, cBAND, blVisible, chFigDir, stateFolder, PowerAllTrial, ZPowerAllTrial)
%%% edited 2023/10/31 to do 64 stimuli, i.e. 4 contrast instead of 1
%%% edited 2023/11/08 to plot the four sizes on the same subplot for the
%%% third and fourth ones
%%% edited 2023/11/16 by Stefan to correct for the multiple comparison
%%% updated 11/23/2023, this is for now a final version that can treat 64
%%% stiumli. But additionally have the capability of do statistics using
%%% all trials for individual mouse
 
%%%%%%%%% PLot the increase in a color map
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

Alltrials   = cell(inNMse,inNDay);

sCOND       = struct('db2Power', repmat({db2Temp}, 1, size(db2U_Cnd, 1)), ...
				'db2Z_Power', repmat({db2Temp}, 1, size(db2U_Cnd, 1)),...
                'PowerAllTrial', repmat({Alltrials}, 1, size(db2U_Cnd, 1)),...
                'ZPowerAllTrial', repmat({Alltrials}, 1, size(db2U_Cnd, 1)));

%Initializes some overal plotting variables
cCOLOR = {[0 .3 .9], [0 .6 .9] [.9 .6 0] [.9 .3 0]};
in1Offset = linspace(-.2, .2, 4);	
cSz_LEGEND = cellfun(@(x) sprintf('%d Size' , 2*x), num2cell(db1U_Sz), 'UniformOutput', false);

%Intializes loop specific plotting variables
iFig  = 0; cFIGNAME = {}; hAX1 = []; iAx1 = 0; hAX2 = []; iAx2 = 0; 
[db1ClimMax1, db1ClimMax2] = deal([Inf -Inf]); %Appreciate the pun

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
                    for iMse = 1:inNMse
                        bl1Mse = in1SesMouse  == in1U_Mse(iMse);
                        sCOND(iCnd).db2Power(iMse, iDay) = mean(db3Power(1, iBnd, bl1Cnd & bl1Mse), 3);    %%I don't really need ths mean right? there is only one number -SS
                        sCOND(iCnd).db2Z_Power(iMse, iDay) = mean(db3Z_Power(1, iBnd, bl1Cnd & bl1Mse), 3);
                        
                        sCOND(iCnd).PowerAllTrial(iMse, iDay) = PowerAllTrial(bl1Cnd & bl1Mse,iBnd);
                        sCOND(iCnd).ZPowerAllTrial(iMse, iDay) = ZPowerAllTrial(bl1Cnd & bl1Mse,iBnd);
                        
                    end
                end
            end
        end
    end
    
    %Plot 1: images of the rate change
    %--------------------------------------------------------------------------------------------------------------------
    iFig = iFig + 1;
    hFIG(iFig)  = figure('Position', [100, 100, 1600 800], 'Visible', blVisible);
    cFIGNAME{iFig} = sprintf('PowerImage_%s', cBAND{iBnd});
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
                    db2Im_Av(iSF, iSz) =  nanmean(sCOND(iCnd).db2Power(:, iDay), 1);
                end
            end
            iAx1 = iAx1 + 1;
            iPlt = iPlt + 1;
            hAX1(iAx1) = subplot(4, length(in1U_Day), iPlt);
            imagesc(db2Im_Av)
            set(gca, 'XTick', 1:4, 'XTickLabel', db1U_Sz*2, 'YTick', 1:4, 'YTickLabel', db1U_SF);
            db1CLim         = get(gca, 'CLim');
            db1ClimMax1(1)   = min(db1ClimMax1(1), min(db2Im_Av(:)));
            db1ClimMax1(2)   = max(db1ClimMax1(2), max(db2Im_Av(:)));
            title(sprintf('Day %d: %.0f%% Ctr', iDay, 100*db1U_Ct(iCt)));
            pbaspect([1 1 1])
        end
    end
    set(hAX1, 'CLim', db1ClimMax1)
    han=axes(hFIG(iFig),'visible','off'); 
    han.XLabel.Visible='on';
    han.YLabel.Visible='on';
    xlabel(han,'Stim Diameter (Deg)');
    ylabel(han,'Spatial frequency (Cyc/Deg)','Position',[-0.03,0.5]);
    set(hAX1, 'CLim', db1ClimMax1);
    sgtitle(sprintf('%s Pulse', cBAND{iBnd}));
    colorbar('Position',[0.92,0.16,0.013,0.6]) %%%%%%%%%Stefan edited


	%Plot 2: images of the zscored rate change
	%--------------------------------------------------------------------------------------------------------------------
    iFig = iFig + 1;
    hFIG(iFig)  = figure('Position', [100, 100, 1600 800], 'Visible', blVisible);
    cFIGNAME{iFig} = sprintf('ZScored_PowerImage_%s', cBAND{iBnd});
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
                    db2Im_Av(iSF, iSz) =  nanmean(sCOND(iCnd).db2Z_Power(:, iDay), 1);
                end
            end
            iAx2 = iAx2 + 1;
            iPlt = iPlt + 1;
            hAX2(iAx2) = subplot(4, length(in1U_Day), iPlt);
            imagesc(db2Im_Av)
            set(gca, 'XTick', 1:4, 'XTickLabel', db1U_Sz, 'YTick', 1:4, 'YTickLabel', db1U_SF);
            db1CLim         = get(gca, 'CLim');
            db1ClimMax2(1)   = min(db1ClimMax2(1), min(db2Im_Av(:)));
            db1ClimMax2(2)   = max(db1ClimMax2(2), max(db2Im_Av(:)));
            title(sprintf('Day %d: %.0f%% Ctrst', iDay, 100*db1U_Ct(iCt)));
            pbaspect([1 1 1])
        end
        
    end
    set(hAX2, 'CLim', db1ClimMax2)
    set(hAX1, 'CLim', db1ClimMax1)
    han=axes(hFIG(iFig),'visible','off'); 
    han.XLabel.Visible='on';
    han.YLabel.Visible='on';
    xlabel(han,'Stim Diameter (Deg)');
    ylabel(han,'Spatial frequency (Cyc/Deg)','Position',[-0.03,0.5]);
    set(hAX1, 'CLim', db1ClimMax1);
    sgtitle(sprintf('%s Pulse', cBAND{iBnd}));
    colorbar('Position',[0.92,0.16,0.013,0.6]) %%%%%%%%%Stefan edited
    
	%Plot 3: plots of the changes along days with significance and error bars
	%--------------------------------------------------------------------------------------------------------------------
    iFig = iFig + 1;
    iPlt = 0; hAX = []; hPLOT = [];
    hFIG(iFig) = figure('Position', [100, 100, 1600 800], 'Visible', blVisible);
    cFIGNAME = cat(2, cFIGNAME, sprintf('PowerPlots_%s', cBAND{iBnd})); 
    for iCt = 1:4
        for iSF = 1:4
            iPlt = iPlt + 1;
            hAX(iPlt) = subplot(4, 4, iPlt); hold on
            for iSz = 1:4
                iCnd        = in3PlotIdx(iSz, iSF, iCt);
                % Plots the average evoked power for the band of interest
                db1PowerAv   = nanmean(sCOND(iCnd).db2Power, 1);
                db1PowerSEM  = sqrt(nanvar(sCOND(iCnd).db2Power, [], 1)./nansum(~isnan(sCOND(iCnd).db2Power), 1)); 
                hPLOT(iSz)  = errorbar(in1Offset(iSz) + in1U_Day, db1PowerAv, db1PowerSEM, db1PowerSEM, 'o-', 'Linewidth', 2, 'color', cCOLOR{iSz});
                
                % Plots an additional asterisk if the last day is
                % significantly different from the first
                db1FirstDay     = sCOND(iCnd).db2Power(:, 1);
                db1LastDay      = sCOND(iCnd).db2Power(:, end);
                
                %%%%%%%%%%% Stefan added, now use permutation test then correct for multiple comparison
                permuteP(iCnd) = permutationTest(db1FirstDay, db1LastDay, 1,'sidedness','smaller','exact',1);
                
                
                %%%%% Stefan added 2023/11/21 to do statistics for each mouse using all trials on day 1 and 7
%                 for iMse = 1:inNMse
%                     FirstDay =  sCOND(iCnd).PowerAllTrial{iMse, 1};
%                     LastDay  =  sCOND(iCnd).PowerAllTrial{iMse, end};
%                     if length(FirstDay)~= length(LastDay)
%                         minLen = min(length(FirstDay),length(LastDay));
%                         FirstDay = FirstDay(1:minLen);
%                         LastDay = LastDay(1: minLen);
%                     end
%                     [Sig(iCnd,iMse), Pval(iCnd,iMse)] = ttest(FirstDay,LastDay);
%                 end
                %%%%%%%%%  
            end
            xlim([0 inNDay + 2])
            title(sprintf('Contrast: %d%%, SF: %.2f', db1U_Ct(iCt)*100, db1U_SF(iSF)));
            xlabel('Day');
            if iCt == 1
                if iSF == 1, legend(hPLOT, cSz_LEGEND, 'Location', 'NorthWest'); end
                if iSF == 2, ylabel(sprintf('%s Power', cBAND{iBnd})); end
                if iSF == 3, ylabel('Power (dB)'); end
            end
        end
    end
    
    %%% Stefan added multi comparison correction
    [permuteH, ~, adj_permuteP]=fdr_bh(permuteP'); %#ok<ASGLU>
    iPlt = 0;
    for iCt = 1:4
        for iSF = 1:4
            iPlt = iPlt + 1;
            for iSz = 1:4
                iCnd        = in3PlotIdx(iSz, iSF, iCt);
                db1PowerAv   = nanmean(sCOND(iCnd).db2Z_Power, 1);
                if permuteH(iCnd); plot(hAX(iPlt),inNDay + 1, db1PowerAv(end), '*', 'color', cCOLOR{iSz}); end
            end
        end
    end
%         linkaxes(hAX);


	%Plot 4: plots of the changes along days with significance and error bars
	%--------------------------------------------------------------------------------------------------------------------
    iFig = iFig + 1;
    iPlt = 0; hAX = []; hPLOT = [];
    hFIG(iFig) = figure('Position', [100, 100, 1600 800], 'Visible', blVisible);
    cFIGNAME = cat(2, cFIGNAME, sprintf('ZScoredPowerPlots_%s', cBAND{iBnd}));
    for iCt = 1:4
        for iSF = 1:4
            iPlt = iPlt + 1;
            hAX(iPlt) = subplot(4, 4, iPlt); hold on
            for iSz = 1:4
                iCnd        = in3PlotIdx(iSz, iSF, iCt);
                % Plots the average evoked power for the band of interest
                db1PowerAv   = nanmean(sCOND(iCnd).db2Z_Power, 1);
                db1PowerSEM  = sqrt(nanvar(sCOND(iCnd).db2Z_Power, [], 1)./nansum(~isnan(sCOND(iCnd).db2Z_Power), 1)); 
                hPLOT(iSz) 	= errorbar(in1Offset(iSz) + in1U_Day, db1PowerAv, db1PowerSEM, db1PowerSEM, 'o-', 'Linewidth', 2, 'color', cCOLOR{iSz});
                
                % Plots an additional asterisk if the last day is
                % significantly different from the first
                db1FirstDay     = sCOND(iCnd).db2Z_Power(:, 1);
                db1LastDay      = sCOND(iCnd).db2Z_Power(:, end);         
                
                %%%%%%%%%%%
                ZpermuteP(iCnd) = permutationTest(db1FirstDay, db1LastDay, 1,'sidedness','smaller','exact',1);
              
            end
            xlim([0 inNDay + 2])
           title(sprintf('Contrast: %d%%, SF: %.2f', db1U_Ct(iCt)*100, db1U_SF(iSF)));
           xlabel('Day');
           if iCt == 1
               if iSF == 1, legend(hPLOT, cSz_LEGEND, 'Location', 'NorthWest'); end
               if iSF == 2, ylabel(sprintf('%s Power', cBAND{iBnd})); end
               if iSF == 3, ylabel('Power (dB)'); end
           end
        end
    end
    %     linkaxes(hAX);
    
    %%% Stefan added multi comparison correction
    [ZpermuteH, ~, adj_ZpermuteP]=fdr_bh(ZpermuteP'); %#ok<ASGLU>
    iPlt = 0;
    for iCt = 1:4
        for iSF = 1:4
            iPlt = iPlt + 1;
            for iSz = 1:4
                iCnd        = in3PlotIdx(iSz, iSF, iCt);
                db1PowerAv   = nanmean(sCOND(iCnd).db2Z_Power, 1);
                if ZpermuteH(iCnd); plot(hAX(iPlt),inNDay + 1, db1PowerAv(end), '*', 'color', cCOLOR{iSz}); end
            end
        end
    end




end


% Saves the figures
warning off
mkdir (fullfile(chFigDir, stateFolder));
save(fullfile(chFigDir, stateFolder,'Workspace'), '-v7.3')
savefig(hFIG, fullfile(chFigDir, stateFolder,'Pool_Figures'));

NS_SaveFig(fullfile(chFigDir, stateFolder), hFIG, cFIGNAME);
pause(.5); close all;

end