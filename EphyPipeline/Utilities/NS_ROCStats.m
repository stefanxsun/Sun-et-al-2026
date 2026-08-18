function [dbDPrime, dbAUC, dbP_DPrime, dbP_AUC] = NS_ROCStats(db1Predictor, bl1Hit)

bl1Rem = isnan(db1Predictor) | isnan(bl1Hit);
db1Predictor(bl1Rem) = []; bl1Hit(bl1Rem) = [];

[dbDPrime, dbAUC] = ROCStatSub(db1Predictor, bl1Hit);

%Use a permutation test
inNTrl  = length(bl1Hit);
inNIter = 10000;
[db1Rnd_DPrime, db1Rnd_AUC] = deal(nan(1, inNIter));
for iItr = 1:inNIter
    bl1RandHit = bl1Hit(randperm(inNTrl));
    [db1Rnd_DPrime(iItr), db1Rnd_AUC(iItr)] = ROCStatSub(db1Predictor, bl1RandHit);
end
dbP_DPrime  = mean(db1Rnd_DPrime > dbDPrime);
dbP_AUC     = mean(db1Rnd_AUC > dbAUC);


function [dbDPrime, dbAUC] = ROCStatSub(db1ExpVar, bl1Hit)

dbMu_Hit    = mean(db1ExpVar(bl1Hit == 1));
dbMu_Miss   = mean(db1ExpVar(bl1Hit == 0));
dbVar_Hit   = max(var(db1ExpVar(bl1Hit == 1)), .001); % Avoids zero denominators 
dbVar_Miss  = max(var(db1ExpVar(bl1Hit == 0)), .001); % Avoids zero denominators
dbDPrime    = abs(dbMu_Hit - dbMu_Miss) ./ sqrt(0.5 * (dbVar_Hit + dbVar_Miss));
dbAUC       = normcdf(dbDPrime / sqrt(2));