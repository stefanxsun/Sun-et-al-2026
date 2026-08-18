function NS_RasterPlot(cTRIAL, db1Range, db1Color)
%Synopsis:
%       NS_RasterPlot(cTRIAL, DB1RANG, DB1COLOR)
%Utility to plot raster plots of events contained in a cell array CTRIAL
%whose values are in the range DB1RANGE with the color DB1COLOR.

%Deals with optional arguments
narginchk(2, 3)
if nargin < 3, db1Color = [0 0 0]; end

%Checks arguments
    %cTRIAL
if ~iscell(cTRIAL), error('cTRIAL must be a cell array'); end
if any(~cellfun(@isnumeric, cTRIAL)), error('cTRIAL must only containe numberic arrays'); end
    %db1Range
if ~isnumeric(db1Range), error('db1Range must be a 2 element row vector'); end
if ~ismatrix(db1Range), error('db1Range must be a 2 element row vector'); end
if any(size(db1Range) ~= [1 2]), error('db1Range must be a 2 element row vector'); end
    %db1Color
if ~isnumeric(db1Color), error('db1Color must be a 3 element row vector with values comprised between 0 and 1'); end
if ~ismatrix(db1Color), error('db1Color must be a 3 element row vector with values comprised between 0 and 1'); end
if any(size(db1Color) ~= [1 3]), error('db1Color must be a 3 element row vector with values comprised between 0 and 1'); end
if any(db1Color < 0 | db1Color > 1), error('db1Color must be a 3 element row vector with values comprised between 0 and 1'); end

%Gets the number of trials
inNTrl = length(cTRIAL);

%Trims events to fit in the window of interest
cTRIAL = cellfun(@(x) x(x > db1Range(1) & x < db1Range(2)), cTRIAL, 'UniformOutput', false);

%Plots each trial
hold on
for iTrl = 1:inNTrl
    db1Evt = cTRIAL{iTrl}(:);
    plot(db1Evt, iTrl * ones(size(db1Evt)),  '.', 'Color', db1Color);
end
ylim([0 inNTrl + 1]);
xlim(db1Range);