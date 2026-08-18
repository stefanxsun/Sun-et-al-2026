function [db1YL, dbScale] = NS_PlotLFP(db2LFP, db1Time, dbScale)
%Checks number of arguments
narginchk(2, 3)

%Gets the number of channels
inNChan = size(db2LFP, 1);

%Sets the scaling between channels
if nargin < 3, dbScale     = 0.7 * max(range(db2LFP, 2)); end
db1YL       = dbScale * [-.5 inNChan + 1.5];

%Plots the LFP
hold on
for iChan = 1:inNChan
    plot(db1Time, (dbScale * (inNChan - iChan + 1)) + db2LFP(iChan, :), 'k');
end
set(gca, 'YTick', dbScale * (1:inNChan), 'YTickLabel', inNChan:-1:1);
ylim(db1YL)
ylabel('Channel'); xlabel('Time (s)');