function [in1UnmatchedIdx_1, in1UnmatchedIdx_2, blWarning] = NS_FindUnmatchedPtsInMatchedSeq(db1Seq1, db1Seq2,  dbRatio12, dbTolerance)
%[IN1UNMATCHEDIDX_1, IN1UNMATCHEDIDX_2] =
%FindUnmatchedPtsInMatchedSeq(DB1SEQ1, DB1SEQ2, DBRATIO12, [DBTOLERANCE])
%
%If DB1SEQ1 and DB1SEQ2 are two sequences of timestamps for the same events
%recorded with two different clocks whose units are linked by the ratio
%DBRATIO12, returns the indices IN1UNMATCHED_1 and IN1UNMATCHED_2 of the
%points of DB1SEQ1 and DB1SEQ1 for wich a match can not be find in the
%other sequence with of tolerance DBTOLERANCE expressed as a fraction of
%dbRatio
%WARNING: The function won't work very well if there is a mismatch on the
%first point and if tolerance and ratio are not set properly.

%Checks for the number of arguments and edits the number
narginchk(3, 4);
if nargin < 4; dbTolerance = 0.10; end

%Checks that db1Seq1 and dbSeq2 are row vectors
if ~isvector(db1Seq1), error('db1Seq1  must be a vector'); end
if ~isvector(db1Seq2), error('db1Seq2  must be a vector'); end
if iscolumn(db1Seq1), db1Seq1 = db1Seq1'; end
if iscolumn(db1Seq2), db1Seq2 = db1Seq2'; end

%Sets the tolerance in absolute term
dbTol = dbTolerance * dbRatio12;

%Computes the difference of length between the two sequences
inLen1 = length(db1Seq1);
inLen2 = length(db1Seq2);
inMinLen = min(inLen1, inLen2);

%Initialize loop variables
[in1UnmatchedIdx_1, in1UnmatchedIdx_2] = deal([]);
[inBeg1, inBeg2] = deal(1);
[inEnd1, inEnd2] = deal(inMinLen);
[blM1, blM2] = deal(true); % Initialized to true at the entrance of the loop

% Loops through the unmatched points from the begining of the vector to the
% end until no match is found
while blM1 || blM2
    %Looks for an unmatched points in both vector
    %plot(diff(db1Seq1(inBeg1:inEnd1)) ./ diff(db1Seq2(inBeg2:inEnd2)))
    inUM_1 = find(diff(db1Seq1(inBeg1:inEnd1)) ./ diff(db1Seq2(inBeg2:inEnd2)) < dbRatio12 - dbTol, 1, 'first');
    inUM_2 = find(diff(db1Seq1(inBeg1:inEnd1)) ./ diff(db1Seq2(inBeg2:inEnd2)) > dbRatio12 + dbTol, 1, 'first');
    
    % Determines if a match was encontered in either vector
    if isempty(inUM_1) && isempty(inUM_2)
        [blM1, blM2] = deal(false);
    elseif isempty(inUM_2)
        blM1 = true;    blM2 = false;
    elseif isempty(inUM_1)
        blM1 = false;   blM2 = true;
    elseif inUM_1 < inUM_2
        blM1 = true;    blM2 = false;
    else 
        blM1 = false;   blM2 = true;
    end
    
    % Record the match and edits the zone of interest accordingly
    if blM1
        in1UnmatchedIdx_1 = cat(2, in1UnmatchedIdx_1, inBeg1 -1 + inUM_1);
        inBeg1 = inBeg1 + inUM_1 + 1;
        inBeg2 = inBeg2 + inUM_1;
        if inEnd1 < inLen1, inEnd1 = inEnd1 + 1;
        else, inEnd2  = inEnd2 - 1; end
    elseif blM2
        in1UnmatchedIdx_2 = cat(2, in1UnmatchedIdx_2, inBeg2 - 1 + inUM_2);
        inBeg2 = inBeg2 + inUM_2 + 1;
        inBeg1 = inBeg1 + inUM_2;
        if inEnd2 < inLen2, inEnd2 = inEnd2 + 1;
        else, inEnd1  = inEnd1 - 1; end
    end
end

% Checks if there are remaining unevaluated chunks at the end of the
% sequence and issues a warning if it is the case
blWarning = false;
if inEnd1 < inLen1
    in1UnmatchedIdx_1 = cat(2, in1UnmatchedIdx_1, inEnd1 : inLen1 - 1);
    warning('Unmatched points at the end of sequence 1');
    blWarning = true;
end
if inEnd2 < inLen2
    in1UnmatchedIdx_2 = cat(2, in1UnmatchedIdx_2, inEnd2 : inLen2 - 1);
    warning('Unmatched points at the end of sequence 2');
    blWarning = true;
end

% We then need to add one to the indices
in1UnmatchedIdx_1 = in1UnmatchedIdx_1 + 1;
in1UnmatchedIdx_2 = in1UnmatchedIdx_2 + 1;