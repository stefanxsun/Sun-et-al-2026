function [in1BegPts, in1EndPts, inCells] = NS_DoDefineContinuousRecording(db1TStamps)

% % Original version - fails when the recording presents adjacent
% discontinuities -- COMMENTED OUT 2020-10-15
% in1BreakPoints = find(diff(db1TStamps,2)~=0);
% in1BegPts = [1 in1BreakPoints(2:2:end) + 1];
% in1EndPts = [in1BreakPoints(1:2:end) + 1 length(db1TStamps)];
% inCells = length(in1BegPts);

% New version as of 2020-10-15
inStep      = median(diff(db1TStamps));
bl1Cont     = diff(db1TStamps) == inStep;
if bl1Cont(1) == 0; bl1Cont(1) =1; end %%%%%%%%%%%%%%%%%%%%Stefan added this 08/04/2023 to solve a problem for one weird session...
in1BegPts   = [1 find(bl1Cont(2:end) & ~bl1Cont(1:end - 1)) + 1];
in1EndPts   = [find(~bl1Cont(2:end) & bl1Cont(1:end - 1)) + 1 length(db1TStamps)];
if bl1Cont(end) == 0; in1EndPts(end)  = [];end %%%% Stefan added this 09/26/2023 to solve a problem for some weird sessions...

% Addition to avoid loosing recordings due to small timing errors of the
% neuralynx system 2020-10-19
db1T_InterRec   = (db1TStamps(in1BegPts(2:end)) - db1TStamps(in1EndPts(1:end-1))) ./ 10.^6;
bl1Error        = db1T_InterRec < .1;
in1BegPts([false bl1Error]) = [];
in1EndPts([bl1Error false]) = [];

inCells = length(in1BegPts);