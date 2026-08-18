function bl1Output = NS_DilateBoolean(bl1Input)
%BL1OUTPUT = NS_DILATEBOOLEAN(BL1INPUT) perfoms dilation (i.e. false points
%lying next to true points are set to true) on the boolean vector BL1INPUT.

if min(size(bl1Input)) > 1
    error('The input vector must be a one dimensional')
end

if sum(bl1Input ~= 0 & bl1Input ~= 1) > 0
    error('The input vector must be logical or consist of 0 and 1 only')
end

bl1Output = bl1Input(:);
bl1Output([find(diff(bl1Output) == 1); (find(diff(bl1Output) == -1) + 1)]) = true;