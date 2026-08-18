function ColorSampler(db2Color)
%Plot a series of color presented on a nColor * 3 input matrix

figure, hold on
for iCol = 1:size(db2Color, 1)
    fill([iCol iCol iCol + 1 iCol + 1], [1 2 2 1], db2Color(iCol, :), 'LineStyle', 'none');
end
xlim([1 iCol + 1]); ylim([1 2]);