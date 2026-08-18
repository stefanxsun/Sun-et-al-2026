function hFIG = VEHA_U_PlotStimPower2(sCOND, db2Cond, cPAR)
% Utilities to plot evoked spectra by gratings sampled over a
% multidimensional parameter space.
narginchk(2, 3);
[inNPar, inNCnd] = size(db2Cond); 
if nargin < 3; cPAR = cellfun(@(x) sprintf('Var %d', x), num2cell(1:size(db2Cond, 1)), 'UniformOUtput', false); end
cCOLOR = {[0 .3 .9], [0 .6 .9] [.9 .6 0] [.9 .3 0]};
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
in3PlotIdx = reshape(1:inNCnd, SF, Cntr, Sz);

%Creates the figures
hFIG(1) = figure('Position', [100, 100, 1600, 900]); %Response per layer at hight Contrast
xVec = [0:2:120 120:-2:0];
db2YLim = zeros(16, 2);
iPlot = 0;
for i1 = 1:Cntr
    for i2= 1:SF
        iPlot = iPlot + 1;
        ax(iPlot) = subplot(Cntr, SF, iPlot); hold on
        for i3 = 1:Sz
            db1Color = cCOLOR{i3};
            iCond = in3PlotIdx(i3, i1, i2);
            yVec = [sCOND(iCond).db2AvCCPower + sCOND(iCond).db2SECCPower ...
                sCOND(iCond).db2AvCCPower(end:-1:1) - sCOND(iCond).db2SECCPower(end:-1:1)];
            fill(xVec, yVec , db1Color, 'LineStyle', 'none', 'FaceAlpha', 0.2)
            hPLT(i3) = plot(0:2:120, sCOND(iCond).db2AvCCPower, 'Color', db1Color);
        end
        db2YLim(iPlot, :) = ylim;
        xlabel('Freq'), ylabel('Power'), xlim([0 120]);
        if inN_Var == 1
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond)));
        elseif inN_Var == 2 ||inN_Var ==3 
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond), cPAR{in1VarIdx(2)}, db2Cond(in1VarIdx(2), iCond)));
        end
        if inN_Var == 3 && i1 == 1 && i2 == 1 
            cLEGEND = cellfun(@(x) sprintf('%s : %.2f', cPAR{in1VarIdx(3)}, x), num2cell(unique(db2Cond(in1VarIdx(3), :))), 'UniformOutput', false);
            legend(hPLT, cLEGEND ); 
        end
    end
end
linkaxes(ax),
ylim(ax, [min(db2YLim(:,1)) max(db2YLim(:,2))])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hFIG(2) = figure('Position', [100, 100, 1600, 900]); %Response per layer at hight Contrast
db2YLim = zeros(16, 2);
iPlot = 0;
for i1 = 1:Cntr
    for i2= 1:SF
        iPlot = iPlot + 1;
        ax2(iPlot) = subplot(SF, Cntr, iPlot); hold on
        for i3 = 1:Sz
            db1Color = cCOLOR{i3};
            iCond = in3PlotIdx(i3, i1, i2);
            yVec = [sCOND(iCond).db2AvCCPower_Diff + sCOND(iCond).db2SECCPower_Diff ...
                sCOND(iCond).db2AvCCPower_Diff(end:-1:1) - sCOND(iCond).db2SECCPower_Diff(end:-1:1)];
            fill(xVec, yVec , db1Color, 'LineStyle', 'none', 'FaceAlpha', 0.2)
            hPLT(i3) = plot(0:2:120, sCOND(iCond).db2AvCCPower_Diff, 'Color', db1Color);
        end
        db2YLim(iPlot, :) = ylim;
        xlabel('Freq'), ylabel('Power'), xlim([0 120]);
        if inN_Var == 1
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond)));
        elseif inN_Var == 2 ||inN_Var ==3 
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond), cPAR{in1VarIdx(2)}, db2Cond(in1VarIdx(2), iCond)));
        end
        if inN_Var == 3 && i1 == 1 && i2 == 1 
            cLEGEND = cellfun(@(x) sprintf('%s : %.2f', cPAR{in1VarIdx(3)}, x), num2cell(unique(db2Cond(in1VarIdx(3), :))), 'UniformOutput', false);
            legend(hPLT, cLEGEND ); 
        end
    end
end
linkaxes(ax2),
ylim(ax2, [min(db2YLim(:,1)) max(db2YLim(:,2))])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hFIG(3) = figure('Position', [100, 100, 1600, 900]); %Response per layer at hight Contrast
xVec = [0:2:120 120:-2:0];
db2YLim = zeros(16, 2);
iPlot = 0;
for i1 = 1:Cntr
    for i2= 1:SF
        iPlot = iPlot + 1;
        ax3(iPlot) = subplot(SF, Cntr, iPlot); hold on
        for i3 = 1:Sz
            db1Color = cCOLOR{i3};
            iCond = in3PlotIdx(i3, i1, i2);
            yVec = [sCOND(iCond).db2AvCCRePower + sCOND(iCond).db2SECCRePower ...
                sCOND(iCond).db2AvCCRePower(end:-1:1) - sCOND(iCond).db2SECCRePower(end:-1:1)];
            fill(xVec, yVec , db1Color, 'LineStyle', 'none', 'FaceAlpha', 0.2)
            hPLT(i3) = plot(0:2:120, sCOND(iCond).db2AvCCRePower, 'Color', db1Color);
        end
        db2YLim(iPlot, :) = ylim;
        xlabel('Freq'), ylabel('Power'), xlim([0 120]);
        yline(0,'Col','blue')
        if inN_Var == 1
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond)));
        elseif inN_Var == 2 ||inN_Var ==3 
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond), cPAR{in1VarIdx(2)}, db2Cond(in1VarIdx(2), iCond)));
        end
        if inN_Var == 3 && i1 == 1 && i2 == 1 
            cLEGEND = cellfun(@(x) sprintf('%s : %.2f', cPAR{in1VarIdx(3)}, x), num2cell(unique(db2Cond(in1VarIdx(3), :))), 'UniformOutput', false);
            legend(hPLT, cLEGEND ); 
        end
    end
end
linkaxes(ax3),
ylim(ax3, [min(db2YLim(:,1)) max(db2YLim(:,2))])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hFIG(4) = figure('Position', [100, 100, 1600, 900]); %Response per layer at hight Contrast
xVec = 0:2:120;
db2YLim = zeros(16, 2);
iPlot = 0;

for i1 = 1:SF
    for i2= 1:Sz
        iPlot = iPlot + 1;
        ax4(iPlot) = subplot(SF, Sz, iPlot); hold on       
        iCond = in3PlotIdx(i2, 4, i1);
        hPLT = plot(0:2:120, sCOND(iCond).db2CCRePower);
        db2YLim(iPlot, :) = ylim;
        xlabel('Freq'), ylabel('Power'), xlim([0 120]);
        yline(0,'Col','black')
        if inN_Var == 1
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond)));
        elseif inN_Var == 2 ||inN_Var ==3 
            title(sprintf('%s: %.2f, %s: %.2f', cPAR{in1VarIdx(1)}, db2Cond(in1VarIdx(1), iCond), cPAR{in1VarIdx(3)}, db2Cond(in1VarIdx(3), iCond)));
        end
        if inN_Var == 3 && i1 == 1 && i2 == 1
            cLEGEND = cellfun(@(x) sprintf('%s %d', 'Mouse', x), num2cell(1:size(sCOND(iCond).db2CCRePower,1)), 'UniformOutput', false);
            legend(hPLT, cLEGEND ); 
        end
    end
end
linkaxes(ax4),
ylim(ax4, [min(db2YLim(:,1)) max(db2YLim(:,2))])
end