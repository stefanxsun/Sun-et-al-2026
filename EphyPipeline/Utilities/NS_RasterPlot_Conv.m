function NS_RasterPlot_Conv(cTRIAL, db1Range, dbConvWin, db1Color)
%Synopsis:
%       NS_RasterPlot_Conv(cTRIAL, DB1RANGE, DBCONVWIN DB1COLOR)
%Utility to plot raster plots of events contained in a cell array CTRIAL
%plotted with the color DB1COLOR. The plots convolutes the event rate to
%highlight difference better. The function is horribly complicated and I
%sincerely hate it.

%Deals with optional arguments
narginchk(3, 4)
if nargin < 4, db1Color = [0 0 0]; end

%Checks arguments
    %cTRIAL
if ~iscell(cTRIAL), error('cTRIAL must be a cell array'); end
if any(~cellfun(@isnumeric, cTRIAL)), error('cTRIAL must only containe numberic arrays'); end
    %db1Range
if ~isnumeric(db1Range), error('db1Range must be a 2 element row vector'); end
if ~ismatrix(db1Range), error('db1Range must be a 2 element row vector'); end
if any(size(db1Range) ~= [1 2]), error('db1Range must be a 2 element row vector'); end
    %dbConWin
if ~isnumeric(dbConvWin), error('dbConvWin must be a positive scalar at most half as big as the range of db1Range'); end
if any(size(dbConvWin) ~= 1), error('dbConvWin must be a positive scalar at most half as big as the range of db1Range'); end 
if dbConvWin < 0 || dbConvWin > diff(db1Range) / 2, error('dbConvWin must be a positive scalar at most half as big as the range of db1Range'); end 
    %db1Color
if ~isnumeric(db1Color), error('db1Color must be a 3 element row vector with values comprised between 0 and 1'); end
if ~ismatrix(db1Color), error('db1Color must be a 3 element row vector with values comprised between 0 and 1'); end
if any(size(db1Color) ~= [1 3]), error('db1Color must be a 3 element row vector with values comprised between 0 and 1'); end
if any(db1Color < 0 | db1Color > 1), error('db1Color must be a 3 element row vector with values comprised between 0 and 1'); end

%Makes sure that the range is sorted in ascending order
db1Range = sort(db1Range);

%Sets time series length
db1TLen = 500;

%Gets the number of trials
inNTrl = length(cTRIAL);

%Calculates the time interval if the range is divided in 500 time points
%and the sample rate
dbTSmp  = diff(db1Range)./ (db1TLen - 1);
dbSRate = 1 ./ dbTSmp;

%Calculates the number of points to pad on each side for the convolution,
%and the convolution window
inNPt   = ceil(dbConvWin .* dbSRate);
db1Win  = rectwin(inNPt);
inNPad  = round(inNPt ./ 2);

%Sets the time vector that things will be aligned to
db1Time = linspace(db1Range(1) - (inNPad + .5) .* dbTSmp, ...
    db1Range(2) + (inNPad + .5) .* dbTSmp , ...
    500 + (inNPad .* 2) + 1);
in1Idx = inNPad + 1:length(db1Time) - 1 - inNPad;

%Perform the convolution and the rate image
db2Im   = zeros(inNTrl, 500);
for iTrl = 1:inNTrl
    db1Hit          = any(cTRIAL{iTrl}(:) > db1Time(1:end - 1) & cTRIAL{iTrl}(:) < db1Time(2:end) , 1);
    db1Hit_Conv     = conv(db1Hit, db1Win, 'same');
    db2Im(iTrl, :)  = db1Hit_Conv(in1Idx);
end

%Sets the colormap for the plot
db2Colors = db1Color .* (0:.05:1)' + [1 1 1] .* (1:-.05:0)';

%Plots each trial
hold on
imagesc(db1Time(in1Idx) + .5 * dbTSmp, 1:inNTrl, db2Im);
colormap(db2Colors);
ylim([0 inNTrl + 1]); xlim(db1Range);