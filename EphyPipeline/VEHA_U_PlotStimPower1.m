function hFIG = VEHA_U_PlotStimPower1(sCOND, db2Cond, cPAR)
% Utilities to plot evoked spectra by gratings sampled over a
% multidimensional parameter space.
narginchk(2, 3);
[inNPar, inNCnd] = size(db2Cond); 
if nargin < 3; cPAR = cellfun(@(x) sprintf('Var %d', x), num2cell(1:size(db2Cond, 1)), 'UniformOUtput', false); end

% Determines how many parameters were taken as variables in the stimulus
% presentation
in1NCnd = nan(inNPar, 1);
for iPar = 1:inNPar
    in1NCnd(iPar) = length(unique(db2Cond(iPar, :)));
end
in1VarIdx   = find(in1NCnd > 1); 
inN_Var     = length(in1VarIdx);

%Sets the number of plots according to the number of presentation variables
if inN_Var > 3; error('The number of variables in the stimulus set exceeds 3'); end 
[SF, Sz, Cntr] = deal(1);
if find(contains(cPAR(in1VarIdx), 'SFr')), SF = in1NCnd(in1VarIdx(contains(cPAR(in1VarIdx), 'SFr'))); end
if find(contains(cPAR(in1VarIdx), 'Sze')), Sz = in1NCnd(in1VarIdx(contains(cPAR(in1VarIdx), 'Sze'))); end
if find(contains(cPAR(in1VarIdx), 'Ctr')), Cntr = in1NCnd(in1VarIdx(contains(cPAR(in1VarIdx), 'Ctr'))); end

%indices of the presentation in a 3D array, wher D1 is spatial frequency, D2 is
%size and D3 is contrast
in3PlotIdx = reshape(1:inNCnd, SF, Sz, Cntr);

%Creates the figures
hFIG(1) = figure('Position', [100, 100, 1600, 900]); %Response per layer at hight Contrast
xVec = [0:2:120 120:-2:0];
db2YLim = zeros(16, 2);
iPlot = 0;
for i1 = 1:SF
    for i2= 1:Sz
        iPlot = iPlot + 1;
        ax(iPlot) = subplot(SF, Sz, iPlot); hold on
        for i3 = 1:Cntr
            db1Color = [.25 0 0]*i3;
            iCond = in3PlotIdx(i1, i2, i3);
            yVec = [sCOND(iCond).db2AvCCPower + sCOND(iCond).db2SECCPower ...
                sCOND(iCond).db2AvCCPower(end:-1:1) - sCOND(iCond).db2SECCPower(end:-1:1)];
            fill(xVec, yVec , db1Color, 'LineStyle', 'none', 'FaceAlpha', 0.2)
            hPLT(i3) = plot(0:2:120, sCOND(iCond).db2AvCCPower, 'Color', db1Color);
        end
        db2YLim(iPlot, :) = ylim;
        xlabel('Freq'), ylabel('Power'), xlim([0 120]);
        if inN_Var == 1
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond)));
        elseif inN_Var == 2
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond), cPAR{in1VarIdx(2)}, db2Cond(in1VarIdx(2), iCond)));
        end
        if inN_Var == 3 & i1 == 1 & i2 == 1, 
            cLEGEND = cellfun(@(x) sprintf('%s : %.2f', cPAR{in1VarIdx(3)}, x), num2cell(unique(db2Cond(in1VarIdx(3), :))), 'UniformOutput', false);
            legend(hPLT, cLEGEND ); 
        end
    end
end
linkaxes(ax),
ylim(ax, [-60 -30]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hFIG(2) = figure('Position', [100, 100, 1600, 900]); %Response per layer at hight Contrast
db2YLim = zeros(16, 2);
iPlot = 0;
for i1 = 1:SF
    for i2= 1:Sz
        iPlot = iPlot + 1;
        ax2(iPlot) = subplot(SF, Sz, iPlot); hold on
        for i3 = 1:Cntr
            db1Color = [.25 0 0]*i3;
            iCond = in3PlotIdx(i1, i2, i3);
            yVec = [sCOND(iCond).db2AvCCPower_Diff + sCOND(iCond).db2SECCPower_Diff ...
                sCOND(iCond).db2AvCCPower_Diff(end:-1:1) - sCOND(iCond).db2SECCPower_Diff(end:-1:1)];
            fill(xVec, yVec , db1Color, 'LineStyle', 'none', 'FaceAlpha', 0.2)
            hPLT(i3) = plot(0:2:120, sCOND(iCond).db2AvCCPower_Diff, 'Color', db1Color);
        end
        db2YLim(iPlot, :) = ylim;
        xlabel('Freq'), ylabel('Power'), xlim([0 120]);
        if inN_Var == 1
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond)));
        elseif inN_Var == 2
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond), cPAR{in1VarIdx(2)}, db2Cond(in1VarIdx(2), iCond)));
        end
        if inN_Var == 3 & i1 == 1 & i2 == 1, 
            cLEGEND = cellfun(@(x) sprintf('%s : %.2f', cPAR{in1VarIdx(3)}, x), num2cell(unique(db2Cond(in1VarIdx(3), :))), 'UniformOutput', false);
            legend(hPLT, cLEGEND ); 
        end
    end
end
linkaxes(ax2),
ylim(ax2, [min(db2YLim(:,1)) max(db2YLim(:,2))])

end