function NS_WriteMUADatFile(chFileName, db2Data)
%NS_WriteDatFile(CHFILENAME, DB2DATA) writes a binary dat file meant to be
%used for spike detection by SpikeDetekt. The input data matrix DB2DATA
%should be formatted as (rows:channels x columns:samples). Data are
%stored as two bytes long unsigned integers ('int16');

%Scales DB2DATA to maximize its range in the int16 format
dbMin = min(db2Data(:));
dbMax = max(db2Data(:));
dbMed = median([dbMin dbMax]);
db2Data = 32767*2*(db2Data - dbMed)./(dbMax - dbMin); 

%Writes the the output file
hFID = fopen(chFileName, 'w'); %open the file and returns a File ID handle
fwrite(hFID, db2Data, 'int16');
fclose(hFID);