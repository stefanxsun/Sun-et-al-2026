function [db1BIC] = ClusterBIC(db2Data, db2Tree, inNCluMax)
% Utility reterning the Bayesian information criterion of different number
% of clusters. The log likelihood will be the mean sum of 

% Gets the number of observation and the number of varialbes
inNObs  = size(db2Data, 1);

% Initializes the output variable
db1BIC  = inf(1, inNCluMax);

for iNCl = 2:inNCluMax
    % Calculates the centroid of ward clusters
    in1CluWard  = cluster(db2Tree, 'maxclust', iNCl);
    db2CtrWard  = zeros(iNCl, size(db2Data, 2));
    for iClu = 1:iNCl
        db2CtrWard(iClu,:) = mean(db2Data(in1CluWard == iClu, :));
    end
    
    % Does the K-Mean correction
    [~,  ~, ~, db2Dist]  = kmeans(db2Data, iNCl, 'start', db2CtrWard);
    
    % Estimate the probability that each point is within its cluster as: 
    % pi = 1 - ((xi - ci)/(xi - cj)) where xi is the coordinate of
    % observation i, ci is the centroid of the cluster to which i is
    % assigned and cj is the centroid of the closest cluster.
    db2SrtDist  = sort(db2Dist, 2);
    db1Prob     = 1 - (db2SrtDist(:, 1)./db2SrtDist(:, 2));
    
    % Calculates the Bayesian information criterion of the clustering
    db1BIC(iNCl) = (iNCl * log(inNObs)) - (2 * sum(log(db1Prob))); 
end