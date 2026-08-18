function db1Conv = NS_NanConv(db1Trace, db1Kernel)
%Utility to convolute a trace while ommitting NaNs

%Checks that both inputs are vector
if ~(isvector(db1Trace)), error('db1Trace must be a vector'); end
if ~(isvector(db1Kernel)), error('db1Kernel must be a vector'); end

%Format db1Trace as a row and db1Kernel as a column
if ~isrow(db1Trace), db1Trace = db1Trace'; end
if ~iscolumn(db1Kernel), db1Kernel = db1Kernel'; end

%Gets the length of the trace and the length of the kernel
inTLen      = length(db1Trace);
inKLen      = length(db1Kernel);
inPadLen1   = floor(inKLen / 2);
inPadLen2   = inKLen - inPadLen1 - 1;

%In order not to overload the memory the trace will be computed in chunks
in1MaxMemSize   = round(0.5 * (1024 ^ 3 / 8)); %0.2 GiB of RAM
inChunkLen      = min(floor((in1MaxMemSize - (inKLen * (inPadLen1 +  inPadLen2))) / inKLen), inTLen);
if inChunkLen < inPadLen1, error('db1Kernel is too big for the computation to be done'); end
inNChunk = ceil(inTLen/inChunkLen);

%Initializes db1Conv
db1Conv = nan(size(db1Trace));

%Loops over chunks
for iChk = 1:inNChunk
    %Computes the indices of the chunk
    if iChk ~= 1 & iChk * inChunkLen + inPadLen2 >=  inTLen, in1ChunkIdx = (iChk - 1) * inChunkLen + 1 : inTLen; blExit = true; inNChunk = inNChunk - 1; %Extend the chunk if the padded length exceeds the trace
    else, in1ChunkIdx = (iChk - 1) * inChunkLen + 1 : min(iChk * inChunkLen, inTLen); end
    %Pads the chunks
    if inNChunk == 1; db1Chunk = [db1Trace(in1ChunkIdx(1)) * ones(1, inPadLen1), db1Trace(in1ChunkIdx), db1Trace(in1ChunkIdx(end)) * ones(1, inPadLen2)];
    elseif iChk == 1; db1Chunk = [db1Trace(in1ChunkIdx(1)) * ones(1, inPadLen1), db1Trace(in1ChunkIdx), db1Trace((1:inPadLen2) + in1ChunkIdx(end))];
    elseif iChk == inNChunk, db1Chunk = [db1Trace(in1ChunkIdx(1) - (inPadLen1:-1:1)), db1Trace(in1ChunkIdx), db1Trace(in1ChunkIdx(end)) * ones(1, inPadLen2)]; 
    else, db1Chunk = [db1Trace(in1ChunkIdx(1) - (inPadLen1:-1:1)), db1Trace(in1ChunkIdx), db1Trace((1:inPadLen2) + in1ChunkIdx(end))]; 
    end
    
    %Computes the indices of the matrix used for convulation
    in2Idx      = (1:length(in1ChunkIdx)) + (0:inKLen - 1)';   
    
    %Convolutes the chunk
    db2ConNum   = db1Chunk(in2Idx) .* db1Kernel;
    db2ConDen   = ~isnan(db2ConNum) .* db1Kernel;
    db1ChunkConv     = nansum(db2ConNum)./nansum(db2ConDen);
    db1ChunkConv(all(isnan(db2ConNum))) = nan;
    
    %Aggregates the convolution
    db1Conv(in1ChunkIdx) = db1ChunkConv;
    
    %Exit loop if needed
    if blExit, break; end
end
