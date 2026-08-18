function blSucces = NS_WriteTableToFlatFile(hFID, cMAT, cHEADROW, cHEADCOL, inNDecimal)
%Utility to write a matrix into a flat file.
%Synopsis:
%   BLSUCCESS = NS_WriteMatToFlatFile(HFID, DB2MAT, [CHEADCOL], [CHEADROW], [DBPRECISION]) 
%Input:
% -HFID:        -A file identifier object returned by the function fopen
% -DB2MAT:      -A Matrix
% -CHEADCOL:    -A cell array of headers for the matrix's columns
% -CHEADROW:    -A cell array of headers for the matrix's row
% -inNDecimal:  -A single integer describing the number of decimal
%Output:
% - BLSUCCESS   -A single boolean value indicated success of failure

%Deals with optional arguments
narginchk(2, 5)
if ~exist('cHEADROW', 'var'),     cHEADROW = {}; end
if ~exist('cHEADCOL', 'var'),     cHEADCOL = {}; end
if ~exist('inNDecimal', 'var'),   inNDecimal = 2; end

%Check input cell array
if isnumeric(cMAT), cMAT = num2cell(cMAT); end
if ~ismatrix(cMAT); error('db2Mat must be a matrix'); end

%Transform the numberica values of the table into characters
    %Extract numeric values
bl1Num      = cellfun(@isnumeric, cMAT(:));
cMATNUM     = cMAT(bl1Num);
db1MatNum   = cell2mat(cMATNUM);
    %Checks the order of the matrix and figures out the max number of decimal
db2Order = floor(log(abs(db1MatNum))./log(10));
inMaxOrd = max(db2Order(:));
inMinOrd = min(db2Order(:));
    %Specifies rounding format
inNDecimal = max(inNDecimal, -inMinOrd + 2 ); %Modify the number of decimal if the order of number is too low
chOrdMax    = num2str(max(inMaxOrd, 0) + 1 + inNDecimal);
chDecim     = num2str(inNDecimal);
chFormat    = ['% ' chOrdMax '.' chDecim 'f'];
    %Does the transformation
[inNRow, inNCol] = size(cMAT);
for iRow = 1:inNRow
    for iCol = 1:inNCol
        if isnumeric(cMAT{iRow, iCol})
            cMAT{iRow, iCol} = sprintf(chFormat, cMAT{iRow, iCol});
        end
    end
end

%Checks the headers
blHRow = CheckHeader(cHEADROW, inNRow);
blHCol = CheckHeader(cHEADCOL, inNCol);
if isrow(cHEADROW), cHEADROW = cHEADROW'; end
if iscolumn(cHEADCOL), cHEADCOL = cHEADCOL'; end

%Happends header
if blHRow, cMAT = [cHEADROW cMAT]; end
if blHCol & blHRow, cMAT = [{' '} cHEADCOL; cMAT];
elseif blHCol & ~blHRow, cMAT = [cHEADCOL; cMAT]; end

%Appends spaces so that all elements in a column have the same number of characters
db1ColChar = max(cellfun(@length, cMAT), 1);
[inNRow, inNCol] = size(cMAT);
for iRow = 1:inNRow
    for iCol = 1:inNCol
        inMissLen   = db1ColChar(iCol) - length(cMAT{iRow, iCol});
        chPad       = repmat(' ', 1, inMissLen); 
        if any([iRow iCol] == 1), cMAT{iRow, iCol} = [cMAT{iRow, iCol} chPad];
        else, cMAT{iRow, iCol} = [chPad cMAT{iRow, iCol}]; end
    end
end

%Opens try catch block and tries to write into files
try
    %Print each cell of the matrix
    for iRow = 1:inNRow
        for iCol = 1:inNCol
            fprintf(hFID, '%s\t', cMAT{iRow, iCol});
        end
        fprintf(hFID, '\n');
    end
    
    %Indicate sucess and returns
    blSucces = true;
catch ME
    %Print error message
    fprintf('Matrix could not be written to file. Error Message:\n')
    getReport(ME);
    blSucces = false;
end

%Utility to check headers
function blGood = CheckHeader(cHEADER, inNEl)
blGood  = iscell(cHEADER);
if blGood
blGood  = isvector(cHEADER) & ...
    all(cellfun(@ischar, cHEADER)) & ...
    numel(cHEADER) == inNEl;
end