function [db1Time, db1Raster_Mean, db1Raster_Var, inNTrial] = NS_RasterPlot_Mean(cTRIAL, db1Range, dbConvWin, db1Color)
%Synopsis:
%       NS_RasterPlot_Mean(cTRIAL, DB1RANGE, DBCONVWIN DB1COLOR)
%Utility to the mean and S.D. of raster plots of events contained in a cell
%array CTRIAL with the color DB1COLOR. The averages are smoothed by
%convoluting rasters wiht square window.

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
db2Raster   = zeros(inNTrl, 500);
for iTrl = 1:inNTrl
    db1Hit          = any(cTRIAL{iTrl}(:) > db1Time(1:end - 1) & cTRIAL{iTrl}(:) < db1Time(2:end) , 1);
    db1Hit_Conv     = conv(db1Hit, db1Win, 'same')./dbConvWin;
    db2Raster(iTrl, :)  = db1Hit_Conv(in1Idx);
end

%Computes the psth
db1Raster_Mean  = nanmean(db2Raster, 1);
db1Raster_Var   = nanvar(db2Raster, 1);
inNTrial        = length(cTRIAL);
db1Raster_SEM   = sqrt(db1Raster_Var./inNTrial);

%Adjust the time
db1Time = db1Time(in1Idx) + .5 * dbTSmp;

%Plots each trial
hold on
NS_MeanErrPlot(db1Time, db1Raster_Mean, db1Raster_SEM, db1Color);
xlim(db1Range);