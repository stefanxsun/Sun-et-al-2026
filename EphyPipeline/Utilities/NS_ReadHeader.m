function sHEADER = NS_ReadHeader(cHEADER)
%SHEADER = NS_ReadHeader(CHEADER)
%Extracts the information contained in the cell array CHEADER returned by
%Nlx2MatCSC (provide to by Neuralynx to read neuralynx files) into a
%structure SHEADER

sHEADER = struct();
for i=1:length(cHEADER)
    chString = cHEADER{i};
    if ~isempty(chString) && strcmp(chString(1), '#')
        cVARNAME = regexp(chString, '(?<=^##\s)\w+\s\w+', 'match');
        if  length(cVARNAME) == 1
            chVarName = strrep(cVARNAME{1}, ' ', '_');
            cVAR = regexp(chString, '(?<=^##\s\w+\s\w+\s).*', 'match');
            if ~isempty(cVAR); chVar = cVAR{1}; else chVar = ''; end
            [dbVar, isNum] = str2num(chVar);
            if isNum
                eval(strcat('sHEADER.', chVarName, '=', chVar, ';'));
            else
                eval(strcat('sHEADER.', chVarName, '=''', chVar, ''';'));
            end
        end
    else
        cVARNAME = regexp(chString, '(?<=^-)\w+', 'match');
        if  length(cVARNAME) == 1
            chVarName = strrep(cVARNAME{1}, 'µs', 'MicroSec');
            cVAR = regexp(chString, '\S+(?=\s?$)', 'match');
            if ~isempty(cVAR); chVar = cVAR{1}; else chVar = ''; end
            [dbVar, isNum] = str2num(chVar);
            if isNum
                eval(strcat('sHEADER.', chVarName, '=', chVar, ';'));
            else
                eval(strcat('sHEADER.', chVarName, '=''', chVar, ''';'));
            end
        end
    end
end

