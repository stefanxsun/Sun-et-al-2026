function db2Data = NS_ReadMUADatFile(chFileName)
%DB2DATA = NS_WriteDatFile(CHFILENAME) reads a binary dat file meant to be
%used for spike detection by SpikeDetekt. The output data matrix DB2DATA
%should (if everything goes right) be formatted as (rows:channels x
%columns:samples). Data are stored as two bytes long unsigned integers
%('int16'); db2Data needs rescaling

%Writes the the output file
hFID = fopen(chFileName, 'r'); %open the file and returns a File ID handle
db2Data = fread(hFID, [16, Inf], 'int16');
fclose(hFID);