function dbXP = NS_WelchTest(dbXMu1, dbXMu2, dbXVar1, dbXVar2, inXN1, inXN2)
%Synopis:
%   DBXP = NS_WelchTest(DBXMU1, DBXMU2, DBXVAR1, DBXVAR2, INXN1, INXN2)
%Utility computing the p-value of the difference between the means DBXMU1
%and DBXMU2 of two normally distributed samples of size INXN1 and INXN2 
%with unknown and unequal variances with unbiased estimators DBXVAR1 and 
%DBXVAR2 

%Caclulates the t-statistic
dbXT    = abs(dbXMu1 - dbXMu2) ./ sqrt((dbXVar1 ./ inXN1) + (dbXVar2 ./ inXN2));

%Calculates the degree of freedom
dbXDF   = (((dbXVar1 ./ inXN1) + (dbXVar2 ./ inXN2)) .^ 2) ./ ...
    ((((dbXVar1 ./ inXN1) .^ 2) ./ (inXN1 - 1)) + ...
    (((dbXVar2 ./ inXN2) .^ 2) ./ (inXN2 - 1)));

%Calculates the p-value (we multiply by 2 because the test is two tailed)
dbXP    = tcdf(dbXT, dbXDF, 'upper') .* 2; 
