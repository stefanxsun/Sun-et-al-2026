function groupIdx = dendrogramColorGroup(Z, nGroups)
% Utility returning the indices fo the cluster to whom belong each
% branche of Z a dendrogram returns by the function cluster when nGroups
% clusters are considered.

if size(Z, 2) ~= 3; error('The tree matrix should be formatted like the output of the function cluster'); end

numBranch = size(Z, 1);
numLeaves = numBranch + 1;

if nGroups <= 1 || nGroups >= numBranch; groupIdx = ones(numBranch, 1); return; end

groupIdx = zeros(numBranch, 1);

nodeIdx = numLeaves + 1:numLeaves + numBranch;

startNodes = unique(Z(end - nGroups + 2: end, 1:2));
startNodes = startNodes(~ismember(startNodes, nodeIdx(end - nGroups + 2: end)));

for iGp = 1:nGroups
    branchIdx = startNodes(iGp);
    branchIdx = findBranches(branchIdx, branchIdx, Z, nodeIdx);
    groupIdx(ismember(nodeIdx, branchIdx)) = iGp;
end


function branchIdx = findBranches(branchIdx, startNode, Z, nodeIdx)

blIdx = ismember(nodeIdx, startNode);
if Z(blIdx, 1) >= nodeIdx(1), branchIdx = findBranches(branchIdx, Z(blIdx, 1), Z, nodeIdx); end
if Z(blIdx, 2) >= nodeIdx(1), branchIdx = findBranches(branchIdx, Z(blIdx, 2), Z, nodeIdx); end
branchIdx = cat(1, branchIdx, startNode);