% Test script for FS and RS units
clear
run StartupAnalysis
cd 'E:\Ephy\VisExpHighAll';
chSessionDir    = 'VEHA_L0-1-2_UnitClustering';
chCluFileName   = 'VEHA_L2_ClusterCut_GUI.mat';
sDIR = dir(chSessionDir);
chLayerDir      = 'VEHA_L3_LayerMapping';
chLyrFileName   = 'VEHA_L3_LayerMapping.mat';
chDestFolder    = 'VEHA_L4_SUA_Type';
chDestFile_Mat  = 'VEHA_L4_SUA_Type.mat';
chDestFile_Fig  = 'VEHA_L4_SUA_Type.fig';

%Makes sure that cluster is cleared from the workspace
clear sCLUSTER

% Sets layer parameters
in1Layer = [70; 315; 455; 735]; %if total depth = 1050
cLAYER  = {'1', '2-3', '4', '5a', '5b', '6'};
in1LyrLim = [0; in1Layer(1:3); mean(in1Layer(3:4)); in1Layer(4)];

%Loops through file and aggregates CSD
fprintf('Loading clusters ...')
for iDir = 1:length(sDIR)
    if sDIR(iDir).isdir
        %Loads the file
        sD2 = dir(fullfile(chSessionDir, sDIR(iDir).name));
        if ~any(ismember({sD2.name}, {chCluFileName})); continue; end
        try
            sINP1   = load(fullfile(chSessionDir, sDIR(iDir).name, chCluFileName), 'sCFG'); sINP1 = sINP1.sCFG;
            sINP2   = load(fullfile(chLayerDir, sDIR(iDir).name, chLyrFileName), 'sCFG'); sINP2 = sINP2.sCFG;
            sSES_CLU = sINP1.sL0MUATDF.sCLUSTER;
            db1LayerChan    = sINP2.sL3LM.db1LayerChan;
            db1ChannelDepth = sINP2.sL3LM.db1ChannelDepth;
            for iClu = 1:length(sSES_CLU)
                db1AvChan   = sum((1:16)' .* mean(sSES_CLU(iClu).bl2Mask, 2))/sum(mean(sSES_CLU(iClu).bl2Mask, 2));
                dbDepth     = interp1(db1ChannelDepth, db1AvChan);
                inLyrIdx    = find(dbDepth > in1LyrLim, 1, 'last');
                chLayer = cLAYER{inLyrIdx};
                sSES_CLU(iClu).dbDepth      = dbDepth;
                sSES_CLU(iClu).chLayer      = chLayer;
                sSES_CLU(iClu).chSes        = sDIR(iDir).name;
                sSES_CLU(iClu).inCluNum     = iClu;
            end
                
            % Aggregates the cluster stucture into the meta structure
            if ~exist('sCLUSTER', 'var'), sCLUSTER = sSES_CLU; db1WavTime = sINP1.sL0MUATDF.db1WavTime * 10;
            else, sCLUSTER = cat(2, sCLUSTER, sSES_CLU); end
        catch ME
            getReport(ME)
        end
    end
end
fprintf('Done !\r')
%% CLusters unit based on Vinck et al. 2015 with unbounded interpolation of the waveform
dbTStep     = diff(db1WavTime(1:2));
in1NIntrp   = 5;
dbTStep2    = dbTStep / in1NIntrp;
in1Idx1     = 1:length(db1WavTime);
in1Idx2     = 1:1/in1NIntrp:length(db1WavTime);

db1Norm_T2  = -0.05:dbTStep2:0.8;
in1NormIdx  = round(db1Norm_T2 / dbTStep2);
inZeroIdx   = find(in1NormIdx == 0);
inRepolIdx  = find(db1Norm_T2 >= 0.45, 1, 'first');

inNClu = length(sCLUSTER);
for iClu = 1:inNClu
    db1AvWave   = - mean(sCLUSTER(iClu).db2Waveform, 1);
    db1AvWave   = interp1(in1Idx1, db1AvWave, in1Idx2, 'spline');
    [dbMaxY, inMaxX] = max(db1AvWave);
    db1AvWave   = db1AvWave(in1NormIdx + inMaxX);
    [dbMinY, inMinX] = min(db1AvWave(in1NormIdx > 0));
    inMinX      = inZeroIdx + inMinX;
    db1AvWave   = (db1AvWave - dbMinY)./(dbMaxY - dbMinY);
    sCLUSTER(iClu).db1AvWaveform    = db1AvWave;
    sCLUSTER(iClu).dbWF_PkTrh       = inMinX * dbTStep2;
    sCLUSTER(iClu).dbWF_RepT        = db1AvWave(inRepolIdx);
    sCLUSTER(iClu).dbFR             = (10^6)./mean(diff(sCLUSTER(iClu).db1TStamps)); 
end

% db2PMat     = [[sCLUSTER.dbWF_PkTrh]; [sCLUSTER.dbWF_RepT]; [sCLUSTER.dbFR]]';
db2PMat     = [[sCLUSTER.dbWF_PkTrh]; [sCLUSTER.dbWF_RepT]]';
fprintf('Done !\r')
%% Cluster the data based on the peak to trough time and repolarization and plots figures
close all, iFig = 0; clear hFIG, cFIGNAME = {};
%Creates the parameter matrix
db2ZPMat = zscore(db2PMat);

%Performs Ward's clustering
db2Tree     = linkage(db2ZPMat, 'ward');
[~, inNClu] = min(ClusterBIC(db2ZPMat, db2Tree, 10));
in1CluWard  = cluster(db2Tree, 'maxclust', inNClu);
db2CtrWard = zeros(inNClu, size(db2ZPMat, 2));
for iClu = 1:inNClu
    db2CtrWard(iClu,:) = mean(db2ZPMat(in1CluWard == iClu, :));
end

% Does the K-Mean correction and prints the silhouette metrics
in1CluKM    = kmeans(db2ZPMat, inNClu, 'start', db2CtrWard);

%Makes sure that FS (i.e. cluster having the highest value of 
%repolarization) are the first cluster
	%Finds FS
db1Clu_RepT 	= nan(1, inNClu);
for iClu = 1:inNClu
	db1Clu_RepT(iClu) = nanmean([sCLUSTER(in1CluKM == iClu).dbWF_RepT]); 
end
[~, inCluFS] = max(db1Clu_RepT);
	%If they are not first put them first
if inCluFS ~= 1
	bl1CluOne 	= in1CluKM == 1; 
	bl1CluFS 	= in1CluKM == inCluFS;
	in1CluKM(bl1CluOne) = inCluFS;
	in1CluKM(bl1CluFS) 	= 1;
end

%Sets cluster colors
cCOLOR = {[1 .1 0], [0 .4 1], [.2 0 .8]};

% Plots the dendrogram
iFig = iFig + 1; hFIG(iFig) = figure;
cFIGNAME = cat(1, cFIGNAME, 'Dendrogram');
if inNClu == 1
    hDEND = dendrogram(db2Tree, size(db2ZPMat, 1));
else
%     hDEND = dendrogram(db2Tree, size(db2ZPMat, 1), ...
%         'ColorThreshold', median(db2Tree(end - inNClu + 1:end - inNClu + 2, 3)));
    hDEND = dendrogram(db2Tree, size(db2ZPMat, 1));
    in1BranchGroupIdx = dendrogramColorGroup(db2Tree, inNClu);
    in1CluNum = 1:inNClu;
	if inCluFS ~= 1
		bl1CluOne 	= in1CluNum == 1; 
		bl1CluFS 	= in1CluNum	== inCluFS;
		in1CluNum(bl1CluOne) 	= inCluFS;
		in1CluNum(bl1CluFS) 	= 1;
	end
    
    for iClu = 0:inNClu
        if iClu == 0, db1Col = [0 0 0]; else, db1Col = cCOLOR{in1CluNum(iClu)}; end
        in1GroupBranchIdx = find(in1BranchGroupIdx == iClu);
        for iBr = 1:length(in1GroupBranchIdx)
            hDEND(in1GroupBranchIdx(iBr)).Color  = db1Col;
        end
    end
end
title('Units Dendrogram');

% Plots scatter plots of the cluster as a function of the parameters
[inNObs, inNPar] = size(db2PMat);
cPAR_NAME = {'Peak-Trough Duration', 'Repolarization'};
for iP1 = 1:inNPar
    for iP2 = iP1 + 1:inNPar
        chTitle = sprintf('%s vs %s', cPAR_NAME{iP1}, cPAR_NAME{iP2});
        iFig = iFig + 1; hFIG(iFig) = figure; hold on
        cFIGNAME = cat(1, cFIGNAME, chTitle);
        for iClu = 1:inNClu
            bl1Clu = in1CluKM == iClu;
            plot(db2PMat(bl1Clu, iP1), db2PMat(bl1Clu, iP2), 'o', 'Color', cCOLOR{iClu}); 
        end
        xlabel(sprintf('%s', cPAR_NAME{iP1})); ylabel(sprintf('%s', cPAR_NAME{iP2}));
        title(chTitle);
    end
end

db1Depth = [sCLUSTER.dbDepth];
chTitle = 'Depth';
iFig = iFig + 1; hFIG(iFig) = figure; hold on
cFIGNAME = cat(1, cFIGNAME, chTitle);
title(chTitle);
for iClu = 1:inNClu
    bl1Clu = in1CluKM == iClu;
    plot(iClu, db1Depth(bl1Clu)', 'o', 'Color', cCOLOR{iClu})
end
db1XLim = [0 inNClu + 1];
plot(db1XLim, [in1Layer in1Layer]', 'k', 'LineWidth', 2)
xlim([0 inNClu + 1]);
xlabel('Cluster #'), ylabel('Depth (microns)')
set(gca, 'YDir', 'reverse')

db2AvWav = cat(1, sCLUSTER.db1AvWaveform);
chTitle = 'Waveforms';
iFig = iFig + 1; hFIG(iFig) = figure; hold on
cFIGNAME = cat(1, cFIGNAME, chTitle);
title(chTitle);
for iClu = 1:inNClu
    bl1Clu = in1CluKM == iClu;
    plot(db1Norm_T2, db2AvWav(bl1Clu, :)', 'Color', cCOLOR{iClu})
end
%% Export the figures and the result
chFigDirName = fullfile(chSessionDir);
mkdir(chDestFolder);
savefig(hFIG, fullfile(chDestFolder, chDestFile_Fig));

NS_SaveFig(chDestFolder, hFIG, cFIGNAME);
fprintf('Done !\r')
%% Export the result of the clustering
warning off

cCLUTYPE = {'FS', 'RS1', 'RS2'};

for iClu = 1:length(sCLUSTER)
    sCLUSTER(iClu).chCluType    = cCLUTYPE{in1CluKM(iClu)}; 
end
sSUA_TYPE = rmfield(sCLUSTER, {'db1TStamps', 'bl2Mask', 'db2Waveform'});

save(fullfile(chDestFolder, chDestFile_Mat), 'sSUA_TYPE', '-v7.3');
fprintf('Done !\r')
