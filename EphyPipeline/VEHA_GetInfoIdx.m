cd('E:\Ephy\VisExpHighAll')

sINFO = VEHA_DefineINFO();

for i = 1:length(sINFO.sREC)
    chSessionName = strcat(sINFO.sREC(i).chNlxSessionDir, '_', num2str(sINFO.sREC(i).inRecNum));
    fprintf('%s :\t%d\r', chSessionName, i)
end
%%