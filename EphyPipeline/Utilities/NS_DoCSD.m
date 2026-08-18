function db2CSD = NS_DoCSD(db2LFP, inNConv)
% Utility to compute the CSD out of the LFP signal
narginchk(1, 2);

if nargin < 2; inNConv = 4; end

%Does a spatial smoothing with 
db2LFP = [repmat(db2LFP(1,:), ceil(inNConv/2), 1) ;...
    db2LFP ;...
    repmat(db2LFP(end,:), ceil(inNConv/2), 1)]; %Pads the signal before convolution to avoid artifact caused by zero padding
db2CSD = - diff(conv2(db2LFP, gausswin(inNConv), 'same')./sum(gausswin(inNConv)), 2);
db2CSD = db2CSD(ceil(inNConv/2) + 1:end - ceil(inNConv/2), :);