function db1Lim = NS_Plt_Range(db1Data, dbMarginMin, dbMarginMax)
% Synopsis:
%       DB1LIM = NS_Plt_Range(DB1DATA, DBMARGINMIN, DBMARGINMAX)
% Utility returning the 2 element vector DB1LIM i.e. a usuful range for a
% ploting the values contained in DB1DATA meant to serve as an input to
% xlim or ylim. The optional argument DBMARGINMIN and DBMARGINMAX set the
% distance of the lower and upper bonds of DB1LIM to the min and maximum of
% DB1DATA. Units are expressed as a fraction fo the range. Default for both
% is 0.1;

% Check optional arguments
narginchk(1, 3);
if nargin < 2, dbMarginMin = .1; end
if nargin < 3, dbMarginMax = .1; end

% Calculate min, max and range
dbMin   = min(db1Data(:));
dbMax   = max(db1Data(:));
dbRange = dbMax - dbMin;

% Calculates the limit
dbLow   = dbMin - dbMarginMin * dbRange;
dbHigh  = dbMax + dbMarginMax * dbRange;
db1Lim  = [dbLow dbHigh];
