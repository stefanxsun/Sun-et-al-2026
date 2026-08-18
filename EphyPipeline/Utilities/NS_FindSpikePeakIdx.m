function in1SpikeIndex = NS_FindSpikePeakIdx(db1Trace, dbThreshold, varargin);
%IN1SPIKEINDEX = NS_FindSpikePeakIdx(DB1TRACE, DBTHRESHOLD,
%[BLNEGTFLAG]) returns the index of the peak of each of the segments
%of DB1TRACE whos value are beyond DB1THRESHOLD in a direction set by the
%optional variable BLNEGTFLAG (If BLNEGTFLAG is set 1, the
%function looks for values more negative than DBTHREHSHOLD wheareas it
%looks for values more positive in any other case)

narginchk(2,3)

blNegTFlag = 0;
if nargin == 3
    if varargin{1}
        blNegTFlag = 1;
    else
        fprintf('Unrecognized value for the optional argument blNegTFlag. Set to default\r')
    end
end
        
if blNegTFlag
    bl1BeyondT = db1Trace < dbThreshold;
else
    bl1BeyondT = db1Trace > dbThreshold;
end

in1BegSpk = find(bl1BeyondT(1:end - 1) == 0 & bl1BeyondT(2:end) == 1) + 1;
in1EndSpk = find(bl1BeyondT(1:end - 1) == 1 & bl1BeyondT(2:end) == 0);

if ~isempty(in1BegSpk)
    if in1BegSpk(1) > in1EndSpk(1), in1EndSpk(1) = []; end
    if in1BegSpk(end) > in1EndSpk(end), in1BegSpk(end) = []; end
end

in1LocalSpikeIndex = nan(1, length(in1BegSpk)); %intialize
if blNegTFlag
    for idx = 1:length(in1BegSpk)
        [~, in1LocalSpikeIndex(idx)] = min(db1Trace(in1BegSpk(idx):in1EndSpk(idx)));
    end
else
    for idx = 1:length(in1BegSpk)
        [~, in1LocalSpikeIndex(idx)] = max(db1Trace(in1BegSpk(idx):in1EndSpk(idx)));
    end
end

in1SpikeIndex = in1BegSpk + in1LocalSpikeIndex - 1;