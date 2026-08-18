function VEHA_L7_plot_power_spectrum(in1SesDay,db2SesCond,db2AvPower,chSessionDir, state)

close all, clear hFIG
cPAR = {'Ori', 'SFr', 'TFr', 'Ctr', 'Sze', 'Opt'};

% Computes the days we are going to iterate over
in1U_Day    = unique(in1SesDay);
inNDay      = length(in1U_Day);
sDAY        = struct('sCOND', repmat({struct()}, 1, inNDay), 'db2Cond', cell(1, inNDay));


% Computes useful variables that can be computed outside the loop 
bl1Bas = all(isnan(db2SesCond), 2);
hFIG = [];
hFIGEvoke =[];
hFIGRe = [];
hFIGSepRe = [];
for iDay = in1U_Day'
    % Determines the number of conditions and intializes the aggregation
    % structure
    bl1Day = in1SesDay == iDay;
    %bl1Day  = in1SesDay == in1U_Day(1); For testing
    db2Cond = unique(db2SesCond(bl1Day & ~bl1Bas, :), 'row');
    inNCnd = size(db2Cond, 1);
    sCOND   = struct('db2AvCCPower', cell(1, inNCnd), 'db2SECCPower', cell(1, inNCnd), ...
        'db2AvCCPower_Diff', cell(1, inNCnd), 'db2SECCPower_Diff', cell(1, inNCnd), ...
        'db2AvCCRePower', cell(1, inNCnd), 'db2SECCRePower', cell(1, inNCnd));  %% Stefan added relative power
    % Loops over conditions and calculates teh spectra
    for iCnd = 1:inNCnd
        bl1Cond = all(db2SesCond == db2Cond(iCnd, :), 2);
        %Raw evoked power
        db2AvPwr_Sel = db2AvPower(bl1Cond & bl1Day, :); 
        sCOND(iCnd).db2AvCCPower = mean(db2AvPwr_Sel, 1);
        sCOND(iCnd).db2SECCPower = sqrt(var(db2AvPwr_Sel, [], 1)./sum(bl1Cond & bl1Day));
        if  iDay ==1
            PowerREF{iCnd} = db2AvPwr_Sel;
        end
        %Evoked power subtracted by baseline 
        db2AvPwr_Sel_Diff = db2AvPwr_Sel - db2AvPower(bl1Bas & bl1Day, :);
        sCOND(iCnd).db2AvCCPower_Diff = mean(db2AvPwr_Sel_Diff,1);
        sCOND(iCnd).db2SECCPower_Diff = sqrt(var(db2AvPwr_Sel_Diff, [], 1)./sum(bl1Cond & bl1Day));
        if  iDay ==1
            PowerDiffREF{iCnd} = db2AvPwr_Sel_Diff;
        end
        % Power changes relative to Day 1      %% Stefan added relative power
%         db2AvPwr_Sel_Re = db2AvPwr_Sel - PowerREF{iCnd};  %% this is the relative power calculated using raw power
        db2AvPwr_Sel_Re = db2AvPwr_Sel_Diff - PowerDiffREF{iCnd};  %% this is the relative power calculated using evoked power
        sCOND(iCnd).db2CCRePower = db2AvPwr_Sel_Re;
        sCOND(iCnd).db2AvCCRePower = mean(db2AvPwr_Sel_Re,1);
        sCOND(iCnd).db2SECCRePower = sqrt(var(db2AvPwr_Sel_Re, [], 1)./sum(bl1Cond & bl1Day));
    end
    
    % Plots the results and aggregates the figures into the output
    % structure
    hFIG_DAY = VEHA_U_PlotStimPower2(sCOND, db2Cond', cPAR);
    hFIG = cat(1, hFIG, hFIG_DAY(1));
    hFIGEvoke = cat(1, hFIGEvoke, hFIG_DAY(2));
    hFIGRe = cat(1, hFIGRe, hFIG_DAY(3));
    hFIGSepRe = cat(1, hFIGSepRe, hFIG_DAY(4));
end

% Saves the figures
chFigDirName = fullfile('Figure', chSessionDir, state); if ~exist(chFigDirName, 'dir'), mkdir(chFigDirName); end
% save(fullfile(chFigDirName, 'Workspace1'), '-v7.3')
% savefig(hFIG,fullfile(chFigDirName, 'Pool_Figures1'));

cFIGNAME = cellfun(@(x) sprintf('RawPower_Day%d', x), num2cell(1:length(hFIG)), 'UniformOutput', false);
cFIGNAMEEvoke = cellfun(@(x) sprintf('RawPowerDiff_Day%d', x), num2cell(1:length(hFIGEvoke)), 'UniformOutput', false);
cFIGNAMERe = cellfun(@(x) sprintf('RelativePower_Day%d', x), num2cell(1:length(hFIGRe)), 'UniformOutput', false);
cFIGNAMESepRe = cellfun(@(x) sprintf('SeperateRelativePower_Day%d', x), num2cell(1:length(hFIGSepRe)), 'UniformOutput', false);
NS_SaveFig(chFigDirName, hFIG, cFIGNAME); 
NS_SaveFig(chFigDirName, hFIGEvoke, cFIGNAMEEvoke); 
NS_SaveFig(chFigDirName, hFIGRe, cFIGNAMERe); 
NS_SaveFig(chFigDirName, hFIGSepRe, cFIGNAMESepRe); 
pause(.1), close all


end
