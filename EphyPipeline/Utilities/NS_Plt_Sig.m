function hPLT = NS_Plt_Sig(db1X, db1Y, dbP);
%Synopsis:
%	hPLT = NS_Plt_Sig(DB1X, DB1Y, DBP)
%Utility to plot stars for the significant value DBP, between 2 positions
%on the x-axis (provide by DB1X) at positions on the y-axis provided by the 2
%element vector DB1Y D1BY. The star code is * for p < 0.05, ** for p < 0.01 
%and *** for p < 0.001.  

%Checks input
if numel(db1X) ~= 2; error('db1X must be a 2 element vector'); end
if numel(db1Y) ~= 2; error('db1Y must be a 2 element vector'); end
if numel(dbP) ~= 1; error('dbP must be a single value'); end
if dbP > 1 | dbP <0, error('dbP must be between 0 and 1'); end

%Returns if dbP is not significant
if dbP >= .5; return; end

%Makes sure x and y are sorted
db1X = sort(db1X); db1Y = sort(db1Y); 

%Plots the bar
db1XBar	= db1X(1) + [.1 .9] * range(db1X);
hold on, plot(db1XBar, db1Y(1) .* [1 1], 'k', 'LineWidth', 2);

%Computes the number of stars
if dbP < 0.001, db1XStar = db1X(1) + range(db1X) .* [.3 .5 .7]; db1YOnes = [1 1 1];
elseif dbP < 0.01, db1XStar = db1X(1) + range(db1X) .* [.4 .6]; db1YOnes = [1 1];
else, db1XStar = db1X(1) + range(db1X) .* .5; db1YOnes = 1; end

%Plots the stars
hPLT = plot(db1XStar, db1YOnes .* db1Y(2), 'k*');
