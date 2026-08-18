function [db2Cond, in2TrialIdx]=NS_SortTrials(db2StimMat)
%[DB2COND, IN2TRIALIDX] = NS_SortTrials(DB2STIMMAT)
%Identify the number of stimulus conditions (e.g.  specific combination of
%stimulus parameters) in the trial matrix DB2STIMMAT where each row is a 
%parameters and each column is a trial. The output variable DB2COND is a
%two dimensional matrix where each column is a unique condition. The output
%variable IN2TRIALIDX represent the indices of the trials (columns) in
%DB2STIMMAT, arranged in a two dimensional matrix where each column is a
%condition (sorted in the same order as in DB2COND) and each row is a
%condition set repetition. Formating trial indices this way makes it
%convenient to average trials over stimulus condition in later stages of
%processing. I hope it is clear, it's not very complicated but it is quite
%ackward to explain.
%
%2016-11-08 QP: Adapted from SortPresPerStim

[db2Cond, in1CondIdx, in1TrialIdx]=unique(db2StimMat', 'rows');
inNCond=length(in1CondIdx); inNPres=floor(length(in1TrialIdx)/inNCond);
[ignore, in1SortTrialIdx]=sort(in1TrialIdx(1:inNPres*inNCond));

in2TrialIdx=reshape(in1SortTrialIdx, inNPres, inNCond);
db2Cond=db2Cond';