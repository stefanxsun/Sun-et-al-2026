function blXOutlier = NS_FindOutlier(dbXData, dbZThreshold)
%BL1OUTLIER = NS_FINDOUTLIER(DB1DATA, [DBZTHRESHOLD]) finds outlier in
%input vector DB1DATA. An outlier is defined as anything that is beyound
%DBZTHRESHOLD (default is 3) std div of the 80% that are closest to the
%mean. Requires the utility 

if nargin < 2, dbZThreshold = 3; end

db1Bound    = quantile(dbXData(:), [.1 .9]);
blXSel      = dbXData >= db1Bound(1) & dbXData <= db1Bound(2);

db1Mu       = nanmean(dbXData(blXSel));
db1SD       = nanstd(dbXData(blXSel));

dbZScore    = bsxfun(@minus, dbXData, db1Mu);
dbZScore    = bsxfun(@rdivide, dbZScore, db1SD);
blXOutlier  = bsxfun(@gt, abs(dbZScore), dbZThreshold);
