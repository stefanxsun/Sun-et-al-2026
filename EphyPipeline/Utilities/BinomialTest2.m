function dbXPVal = BinomialTest2(inXNObs_1, dbXRate_1, inXNObs_2, dbXRate_2)
% Function 2 - Performs a Binomial test for 2 samples
dbXPAll  = (inXNObs_1 .* dbXRate_1 + inXNObs_2 .* dbXRate_2) ./ (inXNObs_1 + inXNObs_2); 
dbZ      = abs(dbXRate_1 - dbXRate_2)./...
    sqrt(dbXPAll .* (1 - dbXPAll) .* (1./ inXNObs_1 + 1./inXNObs_2));
dbXPVal = 2 * (1 - normcdf(dbZ));
