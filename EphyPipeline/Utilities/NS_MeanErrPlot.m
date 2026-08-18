function hPLT = NS_MeanErrPlot(db1X, db1Y, db1Err, db1Color)

if iscolumn(db1X), db1X = db1X'; end
if iscolumn(db1Y), db1Y = db1Y'; end
if iscolumn(db1Err), db1Err = db1Err'; end

hold on
% Plots the error in shaded area
db1XFill = [db1X db1X(end:-1:1)];
db1YFill = [db1Y + db1Err db1Y(end:-1:1) - db1Err(end:-1:1)];
fill(db1XFill, db1YFill, db1Color, 'FaceAlpha', .5, 'LineStyle', 'none');

%Plots the average
hPLT = plot(db1X, db1Y, 'Color', db1Color);
