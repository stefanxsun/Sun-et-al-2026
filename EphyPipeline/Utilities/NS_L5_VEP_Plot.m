%%
VEPcnd = cell(64,1);
layerSel = 4;
for iCnd = 1:size(allSesVEP{1,1},1)
    VEPmiceDay = zeros(length(MouseNum),in1Day(end));
    for imouse = 1:max(MouseSeq)
        ichan = find(chanLayer{imouse,1} == layerSel);
        for iday =1:max(in1Day)
            seldata = allSesVEP{imouse,iday}(iCnd,ichan,:);
            VEPmiceDay(imouse,iday) = mean(seldata(:));
        end
    end
    VEPcnd{iCnd} =  VEPmiceDay;
end


%%
in1Offset = linspace(-.2, .2, 4);	
in1U_Day    = unique(in1SesDay);
cCOLOR = {[0 .3 .9], [0 .6 .9] [.9 .6 0] [.9 .3 0]};
db2U_Cnd    = unique(SesCond{1}, 'row');
db1U_SF     = unique(db2U_Cnd(2,:));
db1U_Sz     = unique(db2U_Cnd(5,:));
db1U_Ct     = unique(db2U_Cnd(3,:));
inNDay = length(in1U_Day);
in3PlotIdx  = permute(reshape(1:64, 4, 4, 4), [1 3 2]);
cSz_LEGEND = cellfun(@(x) sprintf('%d Diameter' , 2*x), num2cell(db1U_Sz), 'UniformOutput', false);


iPlt = 0;
for iCt = 1:4
    for iSF = 1:4
        iPlt = iPlt + 1;
        hAX(iPlt) = subplot(4, 4, iPlt); hold on
        for iSz = 1:4
            iCnd        = in3PlotIdx(iSz, iSF, iCt);
            % Plots the average evoked power for the band of interest
            VEPmean   = nanmean(VEPcnd{iCnd}, 1);
            VEPsem  = sqrt(nanvar(VEPcnd{iCnd}, [], 1)./nansum(~isnan(VEPcnd{iCnd}), 1));
            hPLOT(iSz)  = errorbar(in1Offset(iSz) + in1U_Day, VEPmean, VEPsem, VEPsem, 'o-', 'Linewidth', 2, 'color', cCOLOR{iSz});
            
            % Plots an additional asterisk if the last day is
            % significantly different from the first
            db1FirstDay     = VEPcnd{iCnd}(:, 1);
            db1LastDay      = VEPcnd{iCnd}(:, end);
            
            %%%%%%%%%%% Stefan added, now use permutation test then correct for multiple comparison
            [permuteP(iCnd),o(iCnd),e(iCnd),ci(iCnd,:)] = permutationTest_Stefan(db1LastDay, db1FirstDay, 1,'sidedness','larger','exact',1);
            
        end
        xlim([0 inNDay + 2])
        title(sprintf('Contrast: %d%%, SF: %.2f', db1U_Ct(iCt)*100, db1U_SF(iSF)));
        xlabel('Day');
        if iCt == 1 && iSF == 1
            ylabel('volt');
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
            VEPmean   = nanmean(VEPcnd{iCnd}, 1);
            if permuteH(iCnd); plot(hAX(iPlt),inNDay + 1, VEPmean(end), '*', 'color', cCOLOR{iSz}); end
        end
    end
end

sgtitle(sprintf('Layer %d VEP', layerSel));
linkaxes(hAX);
axP = get(gca,'Position'); legend(hPLOT, cSz_LEGEND,'Location','NorthEastOutside');
set(gca, 'Position', axP);

%%
iCt=4; iSF=2; iSz=4;
iCnd        = in3PlotIdx(iSz, iSF, iCt);
% Plots the average evoked power for the band of interest
layerSel = 4;
ichan = find(chanLayer{imouse,1} == layerSel,1);
iPlt = 0;
figure
for imouse = 1:length(MouseNum)
    for iday = 1:inNDay
        iPlt = iPlt + 1;
        hAX(iPlt) = subplot(length(MouseNum),inNDay,iPlt);
        VEPtraceMean   = nanmean(alltrace{imouse,iday}{iCnd,ichan}(:,401:700), 1);
        plot(VEPtraceMean);
        
    end
end
linkaxes(hAX);
sgtitle(sprintf('Layer %d VEP', layerSel));
han = axes('Visible', 'off');
han.XLabel.Visible = 'on';
han.YLabel.Visible = 'on';

% Add shared x and y labels
xlabel(han, 'Days', 'Units', 'normalized', 'FontSize', 12);
ylabel(han, 'Mice', 'Units', 'normalized', 'FontSize', 12);

%%   layer 2/3 vs layer 4
iCt=4; iSF=2; iSz=4;
iCnd        = in3PlotIdx(iSz, iSF, iCt);
% Plots the average evoked power for the band of interest

iPlt = 0;
figure
for imouse = 1:length(MouseNum)
    chan2 = find(chanLayer{imouse,1} == 2,2);
    ichan2 = chan2(2);
    layerSel4 = 4;
    chan4 = find(chanLayer{imouse,1} == 4,2);
    ichan4 = chan4(2);
    for iday = 1:inNDay
        iPlt = iPlt + 1;
        hAX(iPlt) = subplot(length(MouseNum),inNDay,iPlt);
        VEPtraceMean2   = nanmean(alltrace{imouse,iday}{iCnd,ichan2}(:,401:1000), 1);
        VEPtraceMean4   = nanmean(alltrace{imouse,iday}{iCnd,ichan4}(:,401:1000), 1);
        plot(VEPtraceMean2,'b');
        hold on
        plot(VEPtraceMean4,'r');
    end
end
linkaxes(hAX);
sgtitle(sprintf('Layer %d VEP', layerSel));
han = axes('Visible', 'off');
han.XLabel.Visible = 'on';
han.YLabel.Visible = 'on';

% Add shared x and y labels
xlabel(han, 'Days', 'Units', 'normalized', 'FontSize', 12);
ylabel(han, 'Mice', 'Units', 'normalized', 'FontSize', 12);

%% day1 vs day 7
iCt=4; iSF=2; iSz=4;
iCnd        = in3PlotIdx(iSz, iSF, iCt);
% Plots the average evoked power for the band of interest

iPlt = 0;
figure
for imouse = 1:length(MouseNum)
    chan4 = find(chanLayer{imouse,1} == 4,2);
    ichan4 = chan4(2);    
    iPlt = iPlt + 1;
    hAX(iPlt) = subplot(length(MouseNum),1,iPlt);
    VEPtraceMean1   = nanmean(alltrace{imouse,1}{iCnd,ichan4}(:,401:1000), 1);
    VEPtraceMean7   = nanmean(alltrace{imouse,7}{iCnd,ichan4}(:,401:1000), 1);
    plot(VEPtraceMean1,'r');
    hold on
    plot(VEPtraceMean7,'b');
    
end
linkaxes(hAX);
sgtitle(sprintf('Layer %d VEP', layerSel));
han = axes('Visible', 'off');
han.XLabel.Visible = 'on';
han.YLabel.Visible = 'on';

% Add shared x and y labels
xlabel(han, 'Days', 'Units', 'normalized', 'FontSize', 12);
ylabel(han, 'Mice', 'Units', 'normalized', 'FontSize', 12);

%%
mkdir (fullfile(chFigDir, stateFolder));
save(fullfile(chFigDir, stateFolder,'Workspace'), '-v7.3')
savefig(hFIG, fullfile(chFigDir, stateFolder,'Pool_Figures'));

NS_SaveFig(fullfile(chFigDir, stateFolder), hFIG, cFIGNAME);


