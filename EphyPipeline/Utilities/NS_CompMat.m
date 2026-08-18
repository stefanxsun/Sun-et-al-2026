function blHit = NS_CompMat(dbXMat1, dbXMat2)
%Little utility that returns true if the 2 input matrices have the same 
%size and all their values are equal.

blHit = length(size(dbXMat1)) == length(size(dbXMat2));
if ~blHit, return; end
blHit = all(size(dbXMat1) == size(dbXMat2));
if ~blHit, return; end
blHit = all(dbXMat1(:) == dbXMat2(:));
if ~blHit, return; end
