function db1FrameTStamp = VEHA_U_FindMissingMovieFrame(db1VAnalogFrameTStamp, inFrameCount)
%This function, takes the frame timestamps read from the visual analog and
%the number of frames that should have been displayed and returns a vector
%containing NaNs for missing frames.

db1WhatShouldBe = linspace(db1VAnalogFrameTStamp(1), db1VAnalogFrameTStamp(end), inFrameCount);

db1TSInterval = (db1WhatShouldBe(2) -db1WhatShouldBe(1))*0.9;
db1FrameTStamp = nan(size(db1WhatShouldBe));
inLagIdx = 0;
for ii = 1:length(db1WhatShouldBe)
    if db1VAnalogFrameTStamp(ii - inLagIdx) - db1WhatShouldBe(ii) < db1TSInterval
        db1FrameTStamp(ii) = db1VAnalogFrameTStamp(ii - inLagIdx);
    else
        inLagIdx = inLagIdx + 1;
    end
end
