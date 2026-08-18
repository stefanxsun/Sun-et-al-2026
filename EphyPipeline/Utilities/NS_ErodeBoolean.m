function bl1Output = NS_ErodeBoolean(bl1Input)
%BL1OUTPUT = NS_ERODEBOOLEAN(BL1INPUT) perfoms erosion (i.e. true points
%lying next to false points are set to false) on the boolean vector
%BL1INPUT.

if min(size(bl1Input)) > 1
    error('The input vector must be a one dimensional')
end

if sum(bl1Input ~= 0 & bl1Input ~= 1) > 0
    error('The input vector must be logical or consist of 0 and 1 only')
end

bl1Output = bl1Input(:);
bl1Output([find(diff(bl1Output) == -1); (find(diff(bl1Output) == 1) + 1)]) = false;
