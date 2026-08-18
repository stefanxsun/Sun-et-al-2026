function [in1BegIdx, inLen] = NS_MatchSeqs(db1Seq, db1RefSeq, varargin)
%[IN1BEGIDX, [INLEN]] = NS_MatchSeq(DB1SEQ, DB1REFSEQ [INMAXCUT DBTHRESHOLD])
%returns the begining index IN1BEGIDX and the length INLEN of the best
%match of a sequence of number IN1SEQ within a longer sequence of number
%IN1REFSEQ. The threshold for error must be comprised between 0 and 1 and
%is defined by the optional argument DBTHRESHOLD. If IN1SEQ is not fully
%contained in IN1REFSEQ the function tries to match a shorter sequence by
%removing the end of IN1SEQ. The maximum number of point that can be
%removed is controled by the optional argument INMAXCUT If several matches
%of the same length are found, returns them all. If no match is found
%for the minimal lenght IN1BEGIDX is returned empty.

%2017-05-02 QP: Created

%Checks for the number of output argument
nargoutchk(0,2)

%Checks for optional arguments and there format
switch length(varargin)
    case 0
        inMaxCut    = 0;
        dbThreshold = 1;
    case 1
        inMaxCut    = varargin{1};
        dbThreshold = 1;
    case 2
        inMaxCut    = varargin{1};
        dbThreshold = varargin{2};
end
if mod(inMaxCut, 1) ~= 0 | sign(inMaxCut) == -1 | numel(inMaxCut) > 1
    warning('inMaxCut is ill conditionned. set to 0')
end
if dbThreshold <= 0 | dbThreshold > 1
    warning('dbThreshold must be between 0 and 1: set to 1'); 
    dbThreshold = 1; 
end

%Checks the inMaxCut is not superior to the length of in1Seq
if inMaxCut > length(db1Seq) - 2
    warning('inMaxCut must be strictly inferior to the length of db1Seq, set to %d', length(db1Seq) - 2)
    inMaxCut = length(db1Seq) - 2;
end

%Checks that input vector are indeed vectors
if ~isvector(db1Seq); error('db1Seq must be a vector'); end
if ~isvector(db1RefSeq); error('db1RefSeq must be a vector'); end

%Makes sure that the input vectors are row vectors
db1Seq = db1Seq(:); db1RefSeq = db1RefSeq(:);

%Computes the length of the ref seq
inRSeqLen = length(db1RefSeq);

%Checks that the reference sequence is longer than the sequence
if length(db1Seq) > inRSeqLen, error('db1Seq (L: %d) is longer than db1RefSeq (L: %d)\r', length(db1Seq), inRSeqLen); end

%Initialize the main loop
bl1Match = false;
inCut = 0;
while ~bl1Match & inCut <= inMaxCut 
    inLen = length(db1Seq); % length of the sequence
    inNPoss = inRSeqLen - inLen + 1; % number of possible matches
    %Reformats in1RefSeq so that every row is a possible match for in1Seq 
    in2Idx = repmat((1:inLen)',  1, inNPoss) + repmat(0:inNPoss - 1, inLen, 1);
    in2RSeq = db1RefSeq(in2Idx);
    
    %Finds matches
    in1BegIdx = find(sum(in2RSeq == repmat(db1Seq, 1, inNPoss))./inLen >= dbThreshold);
    
    %Keeps the best match if there is several
    if length(in1BegIdx) > 1
        in2BestMatch = sum(in2RSeq(:, in1BegIdx) == repmat(db1Seq, 1, length(in1BegIdx)));
        in1Max = max(in2BestMatch);
        in1BegIdx = in1BegIdx(in2BestMatch == in1Max);
        %(this way of doing things allow to find several maximums in case of
        %equality)
    end
    
    %Exits if a matche or more is found or if the sequence length was one
    %otherwise shorten in1Seq by one from the end
    if ~isempty(in1BegIdx)
        bl1Match = true;
    else
        db1Seq = db1Seq(1:end -1);
        inCut = inCut + 1;
    end
end