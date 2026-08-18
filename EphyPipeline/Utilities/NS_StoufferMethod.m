function dbP = NS_StoufferMethod(db1P)
%DBP = NS_StoufferMethod(DB1P)
%Evalutates the overall significance DBP of a group of p-values DB1P using
%Stouffer's method.

dbZ     = sum(norminv(1 - db1P(:)))/sqrt(numel(db1P));
dbP     = 1 - normcdf(dbZ); 